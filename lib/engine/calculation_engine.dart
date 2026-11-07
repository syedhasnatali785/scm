import 'dart:math' as math;

import '../core/models/container_spec.dart';
import '../core/models/cost_node.dart';
import '../core/models/currency.dart';
import '../core/models/duty_and_assembly.dart';
import '../core/models/product_item.dart';
import '../core/models/calculation_results.dart';

enum ApportionmentMode {
  targetCapacity, // Allocates freight across the container target usable volume
  actualLoad, // 100% of freight allocated to active cargo, dead freight reported
}

class CalculationEngine {
  /// Computes all line items and overall shipment metrics
  static CalculatedShipmentTotals calculate({
    required List<ProductItem> items,
    required ContainerSpec container,
    required List<CostNode> costNodes,
    required Map<String, CurrencyRate> currencyRates,
    ApportionmentMode apportionmentMode = ApportionmentMode.targetCapacity,
    double volumetricDivisor = 5000.0,
  }) {
    if (items.isEmpty) {
      return CalculatedShipmentTotals(
        totalCartons: 0,
        totalPieces: 0,
        totalSellablePieces: 0,
        totalCbm: 0,
        totalGrossWeightKg: 0,
        containerUsableCbm: container.usableCbm,
        containerMaxPayloadKg: container.maxGrossPayloadKg,
        volumeUtilizationPct: 0,
        payloadUtilizationPct: 0,
        remainingCbm: container.usableCbm,
        remainingPayloadKg: container.maxGrossPayloadKg,
        totalPurchaseCostBase: 0,
        totalLogisticsCostBase: 0,
        totalDutyCostBase: 0,
        totalAssemblyCostBase: 0,
        totalLandedCostBase: 0,
        totalProjectedRevenue: 0,
        totalProjectedNetProfit: 0,
        overallMarginPct: 0,
        overallRoiPct: 0,
        deadFreightCost: 0,
        doorwayCollisionsCount: 0,
        lineItems: const [],
      );
    }

    // Step 1: Pre-calculate basic item aggregations
    int totalCartons = 0;
    int totalPieces = 0;
    double totalCbm = 0.0;
    double totalGwKg = 0.0;

    final purchaseTotals = <String, double>{};
    double grandTotalPurchaseBase = 0.0;

    for (final item in items) {
      totalCartons += item.orderedCartons;
      totalPieces += item.totalPieces;
      totalCbm += item.totalLineCbm;
      totalGwKg += item.totalLineGwKg;

      final originRate =
          currencyRates[item.originCurrency]?.effectiveRate ?? 1.0;
      final purchaseBase = item.totalPieces * item.unitPriceOrigin * originRate;
      purchaseTotals[item.id] = purchaseBase;
      grandTotalPurchaseBase += purchaseBase;
    }

    // Step 2: Convert all active cost pipeline nodes to base currency (PKR)
    double totalActiveLogisticsBase = 0.0;
    final convertedNodes = <Map<String, dynamic>>[];

    for (final node in costNodes.where((n) => n.isActive)) {
      final rate = currencyRates[node.currencyCode]?.effectiveRate ?? 1.0;
      final amountInBase = node.amount * rate;
      totalActiveLogisticsBase += amountInBase;
      convertedNodes.add({'node': node, 'amountBase': amountInBase});
    }

    // Denominators for apportionment
    final double cbmDenom =
        (apportionmentMode == ApportionmentMode.targetCapacity)
        ? math.max(container.usableCbm, 0.01)
        : math.max(totalCbm, 0.01);

    final double gwDenom =
        (apportionmentMode == ApportionmentMode.targetCapacity)
        ? math.max(container.maxGrossPayloadKg, 0.01)
        : math.max(totalGwKg, 0.01);

    final double valueDenom = math.max(grandTotalPurchaseBase, 0.01);
    final double cartonsDenom = math.max(totalCartons.toDouble(), 1.0);

    // Step 3: Compute Line Items
    final calculatedItems = <CalculatedLineItem>[];
    double sumItemPurchaseBase = 0.0;
    double sumItemLogisticsShare = 0.0;
    double sumItemDutyBase = 0.0;
    double sumItemAssemblyBase = 0.0;
    double sumItemTotalLineCost = 0.0;
    double sumItemProjectedRevenue = 0.0;
    double sumSellablePieces = 0.0;
    int doorwayCollisionsCount = 0;
    final doorwayCollidingSkus = <String>[];

    for (final item in items) {
      final purchaseBaseTotal = purchaseTotals[item.id] ?? 0.0;
      final purchaseBasePerPiece = item.totalPieces > 0
          ? (purchaseBaseTotal / item.totalPieces)
          : 0.0;

      // Apportion logistics cost nodes
      double lineLogisticsShareTotal = 0.0;
      for (final entry in convertedNodes) {
        final CostNode node = entry['node'];
        final double amountBase = entry['amountBase'];

        double factor = 0.0;
        switch (node.allocationRule) {
          case ApportionmentRule.byCbm:
            factor = item.totalLineCbm / cbmDenom;
            break;
          case ApportionmentRule.byGrossWeight:
            factor = item.totalLineGwKg / gwDenom;
            break;
          case ApportionmentRule.byInvoiceValue:
            factor = purchaseBaseTotal / valueDenom;
            break;
          case ApportionmentRule.byCartonCount:
            factor = item.orderedCartons / cartonsDenom;
            break;
        }
        lineLogisticsShareTotal += (amountBase * factor);
      }
      final logisticsSharePerPiece = item.totalPieces > 0
          ? (lineLogisticsShareTotal / item.totalPieces)
          : 0.0;

      // Duty calculation
      final dutyBaseTotal = calculateDuty(
        item: item,
        purchaseBaseTotal: purchaseBaseTotal,
        logisticsShareTotal: lineLogisticsShareTotal,
      );
      final dutyBasePerPiece = item.totalPieces > 0
          ? (dutyBaseTotal / item.totalPieces)
          : 0.0;

      // Local Assembly calculation
      final assemblyPerPiece = item.assemblySpec.totalPerPieceAddition;
      final assemblyBaseTotal = item.totalPieces * assemblyPerPiece;

      // Total Line Cost
      final totalLineCost =
          purchaseBaseTotal +
          lineLogisticsShareTotal +
          dutyBaseTotal +
          assemblyBaseTotal;

      // Defect & Sellable Units
      final defectShrinkage = math.max(
        0.0,
        math.min(100.0, item.assemblySpec.defectWastagePct),
      );
      final sellablePieces =
          item.totalPieces * (1.0 - (defectShrinkage / 100.0));
      final unitLandedCost = sellablePieces > 0
          ? (totalLineCost / sellablePieces)
          : 0.0;

      // Pricing & Profits (Forward vs Reverse Pricing)
      double projectedSellingPrice;
      double effectiveMarkupPct;
      double effectiveMarginPct;

      if (item.marketSellingPrice != null && item.marketSellingPrice! > 0) {
        // Reverse Pricing from market price
        projectedSellingPrice = item.marketSellingPrice!;
        effectiveMarkupPct = unitLandedCost > 0
            ? ((projectedSellingPrice - unitLandedCost) / unitLandedCost) *
                  100.0
            : 0.0;
        effectiveMarginPct = projectedSellingPrice > 0
            ? ((projectedSellingPrice - unitLandedCost) /
                      projectedSellingPrice) *
                  100.0
            : 0.0;
      } else {
        // Forward Pricing from markup %
        effectiveMarkupPct = item.targetMarkupPct;
        projectedSellingPrice =
            unitLandedCost * (1.0 + (effectiveMarkupPct / 100.0));
        effectiveMarginPct = projectedSellingPrice > 0
            ? ((projectedSellingPrice - unitLandedCost) /
                      projectedSellingPrice) *
                  100.0
            : 0.0;
      }

      final projectedLineRevenue = projectedSellingPrice * sellablePieces;
      final projectedLineNetProfit = projectedLineRevenue - totalLineCost;

      // Doorway height & width collision check respecting orientation constraints
      bool collision = false;
      switch (item.orientationConstraint) {
        case OrientationConstraint.uprightOnly:
          // Must stay upright (dz = height), can rotate length/width
          collision = item.heightInCm > container.doorHeightCm ||
              math.min(item.lengthInCm, item.widthInCm) > container.doorWidthCm;
          break;
        case OrientationConstraint.noRotation:
          collision = item.heightInCm > container.doorHeightCm ||
              item.widthInCm > container.doorWidthCm;
          break;
        case OrientationConstraint.allowAny:
          final dims = [item.lengthInCm, item.widthInCm, item.heightInCm]..sort();
          final doorMin = math.min(container.doorWidthCm, container.doorHeightCm);
          final doorMax = math.max(container.doorWidthCm, container.doorHeightCm);
          collision = dims[0] > doorMin || dims[1] > doorMax;
          break;
      }
      if (collision) {
        doorwayCollisionsCount++;
        doorwayCollidingSkus.add('${item.name} (${item.modelNumber})');
      }

      // Dead freight attribution for this line in Target mode
      double deadFreightShare = 0.0;
      if (apportionmentMode == ApportionmentMode.targetCapacity &&
          totalCbm < container.usableCbm) {
        final unusedCbmRatio =
            (container.usableCbm - totalCbm) / container.usableCbm;
        deadFreightShare =
            (totalActiveLogisticsBase * unusedCbmRatio) *
            (item.totalLineCbm / math.max(totalCbm, 0.01));
      }

      calculatedItems.add(
        CalculatedLineItem(
          itemId: item.id,
          purchaseBaseTotal: purchaseBaseTotal,
          purchaseBasePerPiece: purchaseBasePerPiece,
          logisticsShareTotal: lineLogisticsShareTotal,
          logisticsSharePerPiece: logisticsSharePerPiece,
          dutyBaseTotal: dutyBaseTotal,
          dutyBasePerPiece: dutyBasePerPiece,
          assemblyBaseTotal: assemblyBaseTotal,
          assemblyBasePerPiece: assemblyPerPiece,
          totalLineCost: totalLineCost,
          sellablePieces: sellablePieces,
          unitLandedCost: unitLandedCost,
          projectedSellingPrice: projectedSellingPrice,
          effectiveMarkupPct: effectiveMarkupPct,
          effectiveMarginPct: effectiveMarginPct,
          projectedLineRevenue: projectedLineRevenue,
          projectedLineNetProfit: projectedLineNetProfit,
          doorwayCollision: collision,
          deadFreightShare: deadFreightShare,
        ),
      );

      sumItemPurchaseBase += purchaseBaseTotal;
      sumItemLogisticsShare += lineLogisticsShareTotal;
      sumItemDutyBase += dutyBaseTotal;
      sumItemAssemblyBase += assemblyBaseTotal;
      sumItemTotalLineCost += totalLineCost;
      sumItemProjectedRevenue += projectedLineRevenue;
      sumSellablePieces += sellablePieces;
    }

    // Step 4: Overall Container & Financial Totals
    final volumeUtilizationPct = container.usableCbm > 0
        ? (totalCbm / container.usableCbm) * 100.0
        : 0.0;
    final payloadUtilizationPct = container.maxGrossPayloadKg > 0
        ? (totalGwKg / container.maxGrossPayloadKg) * 100.0
        : 0.0;

    final remainingCbm = math.max(0.0, container.usableCbm - totalCbm);
    final remainingPayloadKg = math.max(
      0.0,
      container.maxGrossPayloadKg - totalGwKg,
    );

    final deadFreightCost =
        (apportionmentMode == ApportionmentMode.targetCapacity &&
            volumeUtilizationPct < 100.0)
        ? totalActiveLogisticsBase *
              ((container.usableCbm - totalCbm) / container.usableCbm)
        : 0.0;

    final totalProjectedNetProfit =
        sumItemProjectedRevenue - sumItemTotalLineCost;
    final overallMarginPct = sumItemProjectedRevenue > 0
        ? (totalProjectedNetProfit / sumItemProjectedRevenue) * 100.0
        : 0.0;
    final overallRoiPct = sumItemTotalLineCost > 0
        ? (totalProjectedNetProfit / sumItemTotalLineCost) * 100.0
        : 0.0;

    // Step 5: "Fill-the-Gap" Top-Up Recommendations
    final topUpOptions = <TopUpOption>[];
    if (remainingCbm > 0.05 && remainingPayloadKg > 10.0) {
      for (final item in items) {
        if (item.cbmPerCarton <= 0 || item.gwPerCartonKg <= 0) continue;

        final maxCartonsByVol = (remainingCbm / item.cbmPerCarton).floor();
        final maxCartonsByWeight = (remainingPayloadKg / item.gwPerCartonKg)
            .floor();
        final fitCartons = math.min(maxCartonsByVol, maxCartonsByWeight);

        if (fitCartons > 0) {
          final addCbm = fitCartons * item.cbmPerCarton;
          final addWeight = fitCartons * item.gwPerCartonKg;
          final addPieces = fitCartons * item.piecesPerCarton;

          // Estimate savings by diluting fixed freight
          final currentLine = calculatedItems.firstWhere(
            (c) => c.itemId == item.id,
          );
          final dilutedFreightSharePerPiece =
              (currentLine.logisticsShareTotal) /
              math.max(1, (item.totalPieces + addPieces));
          final estimatedNewUlc =
              currentLine.unitLandedCost -
              (currentLine.logisticsSharePerPiece -
                  dilutedFreightSharePerPiece);
          final savings = math.max(
            0.0,
            currentLine.unitLandedCost - estimatedNewUlc,
          );

          topUpOptions.add(
            TopUpOption(
              itemId: item.id,
              itemName: item.name,
              additionalCartons: fitCartons,
              additionalPieces: addPieces,
              additionalCbm: addCbm,
              additionalWeightKg: addWeight,
              newUnitLandedCost: estimatedNewUlc,
              perUnitSavings: savings,
            ),
          );
        }
      }
    }

    final isOverweightAxle = totalGwKg > container.roadAxleLimitKg;
    final excessAxleWeightKg = math.max(0.0, totalGwKg - container.roadAxleLimitKg);

    return CalculatedShipmentTotals(
      totalCartons: totalCartons,
      totalPieces: totalPieces,
      totalSellablePieces: sumSellablePieces,
      totalCbm: totalCbm,
      totalGrossWeightKg: totalGwKg,
      containerUsableCbm: container.usableCbm,
      containerMaxPayloadKg: container.maxGrossPayloadKg,
      roadAxleLimitKg: container.roadAxleLimitKg,
      isOverweightAxle: isOverweightAxle,
      excessAxleWeightKg: excessAxleWeightKg,
      volumeUtilizationPct: volumeUtilizationPct,
      payloadUtilizationPct: payloadUtilizationPct,
      remainingCbm: remainingCbm,
      remainingPayloadKg: remainingPayloadKg,
      totalPurchaseCostBase: sumItemPurchaseBase,
      totalLogisticsCostBase: sumItemLogisticsShare,
      totalDutyCostBase: sumItemDutyBase,
      totalAssemblyCostBase: sumItemAssemblyBase,
      totalLandedCostBase: sumItemTotalLineCost,
      totalProjectedRevenue: sumItemProjectedRevenue,
      totalProjectedNetProfit: totalProjectedNetProfit,
      overallMarginPct: overallMarginPct,
      overallRoiPct: overallRoiPct,
      deadFreightCost: deadFreightCost,
      doorwayCollisionsCount: doorwayCollisionsCount,
      doorwayCollidingSkus: doorwayCollidingSkus,
      topUpRecommendations: topUpOptions,
      lineItems: calculatedItems,
    );
  }

  /// Calculates duty based on flat rate or cascading statutory tax stack
  static double calculateDuty({
    required ProductItem item,
    required double purchaseBaseTotal,
    required double logisticsShareTotal,
  }) {
    final spec = item.dutySpec;
    if (spec.mode == DutyMode.flatRate) {
      switch (spec.flatBasis) {
        case FlatRateBasis.perKgGross:
          return item.totalLineGwKg * spec.flatRateAmount;
        case FlatRateBasis.perKgNet:
          return item.totalLineNwKg * spec.flatRateAmount;
        case FlatRateBasis.perPiece:
          return item.totalPieces * spec.flatRateAmount;
        case FlatRateBasis.perCbm:
          return item.totalLineCbm * spec.flatRateAmount;
        case FlatRateBasis.fixedLumpSum:
          return spec.flatRateAmount;
      }
    } else {
      // Statutory WeBOC/PSW Cascading Tax Mode
      // CIF Base = Purchase Value in PKR + Logistics Share
      final cif = purchaseBaseTotal + logisticsShareTotal;

      // Statutory 1% Landing Charges: Assessed CIF = CIF * (1 + landingChargesPct / 100)
      final assessedCif = cif * (1.0 + (spec.landingChargesPct / 100.0));

      final cd = assessedCif * (spec.customsDutyPct / 100.0);
      final acd = assessedCif * (spec.additionalCustomsDutyPct / 100.0);
      final rd = assessedCif * (spec.regulatoryDutyPct / 100.0);

      // Value for Sales Tax = Assessed CIF + CD + ACD + RD
      final valueForSalesTax = assessedCif + cd + acd + rd;
      final st = valueForSalesTax * (spec.salesTaxPct / 100.0);
      final ast = valueForSalesTax * (spec.additionalSalesTaxPct / 100.0);

      // Value for Withholding Tax = Value for ST + ST + AST
      final valueForWht = valueForSalesTax + st + ast;
      
      // Filer vs Non-Filer: Non-Filers pay double statutory WHT
      final effectiveWhtPct = spec.isFiler
          ? spec.withholdingTaxPct
          : (spec.withholdingTaxPct * 2.0);
      final wht = valueForWht * (effectiveWhtPct / 100.0);

      return cd + acd + rd + st + ast + wht;
    }
  }
}
