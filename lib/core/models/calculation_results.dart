import 'package:flutter/foundation.dart';

@immutable
class CalculatedLineItem {
  final String itemId;
  final double purchaseBaseTotal;
  final double purchaseBasePerPiece;
  final double logisticsShareTotal;
  final double logisticsSharePerPiece;
  final double dutyBaseTotal;
  final double dutyBasePerPiece;
  final double assemblyBaseTotal;
  final double assemblyBasePerPiece;
  final double totalLineCost;
  final double sellablePieces;
  final double unitLandedCost;
  final double projectedSellingPrice;
  final double effectiveMarkupPct;
  final double effectiveMarginPct;
  final double projectedLineRevenue;
  final double projectedLineNetProfit;
  final bool doorwayCollision;
  final double deadFreightShare;

  const CalculatedLineItem({
    required this.itemId,
    required this.purchaseBaseTotal,
    required this.purchaseBasePerPiece,
    required this.logisticsShareTotal,
    required this.logisticsSharePerPiece,
    required this.dutyBaseTotal,
    required this.dutyBasePerPiece,
    required this.assemblyBaseTotal,
    required this.assemblyBasePerPiece,
    required this.totalLineCost,
    required this.sellablePieces,
    required this.unitLandedCost,
    required this.projectedSellingPrice,
    required this.effectiveMarkupPct,
    required this.effectiveMarginPct,
    required this.projectedLineRevenue,
    required this.projectedLineNetProfit,
    this.doorwayCollision = false,
    this.deadFreightShare = 0.0,
  });
}

@immutable
class TopUpOption {
  final String itemId;
  final String itemName;
  final int additionalCartons;
  final int additionalPieces;
  final double additionalCbm;
  final double additionalWeightKg;
  final double newUnitLandedCost;
  final double perUnitSavings;

  const TopUpOption({
    required this.itemId,
    required this.itemName,
    required this.additionalCartons,
    required this.additionalPieces,
    required this.additionalCbm,
    required this.additionalWeightKg,
    required this.newUnitLandedCost,
    required this.perUnitSavings,
  });
}

@immutable
class CalculatedShipmentTotals {
  final int totalCartons;
  final int totalPieces;
  final double totalSellablePieces;
  final double totalCbm;
  final double totalGrossWeightKg;
  final double containerUsableCbm;
  final double containerMaxPayloadKg;
  final double roadAxleLimitKg;
  final bool isOverweightAxle;
  final double excessAxleWeightKg;
  final double volumeUtilizationPct;
  final double payloadUtilizationPct;
  final double remainingCbm;
  final double remainingPayloadKg;
  final double totalPurchaseCostBase;
  final double totalLogisticsCostBase;
  final double totalDutyCostBase;
  final double totalAssemblyCostBase;
  final double totalLandedCostBase;
  final double totalProjectedRevenue;
  final double totalProjectedNetProfit;
  final double overallMarginPct;
  final double overallRoiPct;
  final double deadFreightCost;
  final int doorwayCollisionsCount;
  final List<String> doorwayCollidingSkus;
  final List<TopUpOption> topUpRecommendations;
  final List<CalculatedLineItem> lineItems;

  const CalculatedShipmentTotals({
    required this.totalCartons,
    required this.totalPieces,
    required this.totalSellablePieces,
    required this.totalCbm,
    required this.totalGrossWeightKg,
    required this.containerUsableCbm,
    required this.containerMaxPayloadKg,
    this.roadAxleLimitKg = 26500.0,
    this.isOverweightAxle = false,
    this.excessAxleWeightKg = 0.0,
    required this.volumeUtilizationPct,
    required this.payloadUtilizationPct,
    required this.remainingCbm,
    required this.remainingPayloadKg,
    required this.totalPurchaseCostBase,
    required this.totalLogisticsCostBase,
    required this.totalDutyCostBase,
    required this.totalAssemblyCostBase,
    required this.totalLandedCostBase,
    required this.totalProjectedRevenue,
    required this.totalProjectedNetProfit,
    required this.overallMarginPct,
    required this.overallRoiPct,
    required this.deadFreightCost,
    required this.doorwayCollisionsCount,
    this.doorwayCollidingSkus = const [],
    this.topUpRecommendations = const [],
    this.lineItems = const [],
  });

  CalculatedLineItem? lineItemFor(String itemId) {
    for (final item in lineItems) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }
}

