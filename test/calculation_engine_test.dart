import 'package:flutter_test/flutter_test.dart';
import 'package:scm/core/models/container_spec.dart';
import 'package:scm/core/models/cost_node.dart';
import 'package:scm/core/models/currency.dart';
import 'package:scm/core/models/duty_and_assembly.dart';
import 'package:scm/core/models/product_item.dart';
import 'package:scm/engine/calculation_engine.dart';

void main() {
  group('CalculationEngine Tests', () {
    test('Calculates simple shipment totals and unit landed cost accurately', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      final currencies = {
        for (var c in CurrencyRate.defaultCurrencies()) c.code: c,
      };
      final costNodes = CostNode.defaultPipeline();

      final item1 = ProductItem(
        id: 'item_1',
        name: 'HF Electric Jeep 601',
        modelNumber: 'HF-601-RED',
        supplierName: 'Pinghu Toys',
        cartonLength: 135.0,
        cartonWidth: 75.0,
        cartonHeight: 52.0,
        dimensionUnit: DimensionUnit.cm,
        orderedCartons: 80,
        piecesPerCarton: 1,
        nwPerCartonKg: 25.0,
        gwPerCartonKg: 28.0,
        unitPriceOrigin: 450.0,
        originCurrency: 'RMB',
        dutySpec: const DutySpec(
          mode: DutyMode.flatRate,
          flatBasis: FlatRateBasis.perKgGross,
          flatRateAmount: 220.0,
        ),
        assemblySpec: const AssemblySpec(
          isEnabled: true,
          localBoxCost: 400.0,
          technicianLaborCost: 600.0,
          localPartsCost: 1500.0,
          defectWastagePct: 2.0,
        ),
        targetMarkupPct: 25.0,
      );

      final totals = CalculationEngine.calculate(
        items: [item1],
        container: container,
        costNodes: costNodes,
        currencyRates: currencies,
        apportionmentMode: ApportionmentMode.targetCapacity,
      );

      expect(totals.totalCartons, equals(80));
      expect(totals.totalPieces, equals(80));
      expect(totals.totalCbm, closeTo(42.12, 0.05));
      expect(totals.volumeUtilizationPct, greaterThan(50.0));
      expect(totals.totalPurchaseCostBase, greaterThan(1000000.0));
      expect(totals.totalLandedCostBase, greaterThan(totals.totalPurchaseCostBase));
      expect(totals.totalProjectedRevenue, greaterThan(totals.totalLandedCostBase));
      expect(totals.totalProjectedNetProfit, greaterThan(0));
    });

    test('Detects doorway collision correctly', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.twentyGP);
      // Container door height is 228cm
      final tallItem = ProductItem(
        id: 'tall_item',
        name: 'Tall Wardrobe',
        modelNumber: 'WD-01',
        supplierName: 'Foshan Furniture',
        cartonLength: 100.0,
        cartonWidth: 50.0,
        cartonHeight: 240.0, // Exceeds 228cm door height!
        orderedCartons: 10,
      );

      final totals = CalculationEngine.calculate(
        items: [tallItem],
        container: container,
        costNodes: [],
        currencyRates: {'RMB': CurrencyRate.defaultCurrencies()[1]},
      );

      expect(totals.doorwayCollisionsCount, equals(1));
    });

    test('Validates Gatekeeper: Doorway 2292mm/2597mm clearance and Road Axle payload limits', () {
      final twentyGP = ContainerSpec.fromPreset(ContainerPreset.twentyGP);
      final fortyHC = ContainerSpec.fromPreset(ContainerPreset.fortyHC);

      // Cargo with height 235 cm (2,350 mm):
      // Fails 20GP door (2,292 mm clearance), but fits 40HC door (2,597 mm clearance)
      final midCargo = ProductItem(
        id: 'mid_cargo',
        name: 'Tall Palletized Server Rack',
        modelNumber: 'SR-235',
        supplierName: 'Hangzhou Server Co.',
        cartonLength: 100.0,
        cartonWidth: 80.0,
        cartonHeight: 235.0, // 2,350 mm
        orderedCartons: 10,
        gwPerCartonKg: 50.0,
      );

      final result20GP = CalculationEngine.calculate(
        items: [midCargo],
        container: twentyGP,
        costNodes: [],
        currencyRates: {'RMB': CurrencyRate.defaultCurrencies()[1]},
      );

      final result40HC = CalculationEngine.calculate(
        items: [midCargo],
        container: fortyHC,
        costNodes: [],
        currencyRates: {'RMB': CurrencyRate.defaultCurrencies()[1]},
      );

      // Collides with 20GP door (2,292 mm)
      expect(result20GP.doorwayCollisionsCount, equals(1));
      expect(result20GP.doorwayCollidingSkus, contains('Tall Palletized Server Rack (SR-235)'));

      // Fits 40HC high cube door (2,597 mm)
      expect(result40HC.doorwayCollisionsCount, equals(0));

      // Overweight Road Axle Gatekeeper Check:
      // Overload 40HC (limit 26,500 kg) with 30,000 kg cargo
      final heavyCargo = ProductItem(
        id: 'heavy_cargo',
        name: 'Industrial Metal Castings',
        modelNumber: 'MC-HEAVY',
        supplierName: 'Anhui Foundry',
        cartonLength: 60.0,
        cartonWidth: 40.0,
        cartonHeight: 40.0,
        orderedCartons: 600,
        gwPerCartonKg: 50.0, // 30,000 kg total
      );

      final axleResult = CalculationEngine.calculate(
        items: [heavyCargo],
        container: fortyHC,
        costNodes: [],
        currencyRates: {'RMB': CurrencyRate.defaultCurrencies()[1]},
      );

      expect(axleResult.isOverweightAxle, isTrue);
      expect(axleResult.excessAxleWeightKg, equals(3500.0)); // 30000 - 26500 = 3500 kg excess
    });

    test('Provides Fill-the-Gap top up recommendations when space remains', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      final item = ProductItem(
        id: 'small_item',
        name: 'Mini Drone',
        modelNumber: 'MD-10',
        supplierName: 'Shenzhen Tech',
        cartonLength: 30.0,
        cartonWidth: 20.0,
        cartonHeight: 20.0, // 0.012 CBM
        orderedCartons: 100, // 1.2 CBM out of 69 CBM
      );

      final totals = CalculationEngine.calculate(
        items: [item],
        container: container,
        costNodes: CostNode.defaultPipeline(),
        currencyRates: {
          for (var c in CurrencyRate.defaultCurrencies()) c.code: c,
        },
      );

      expect(totals.topUpRecommendations.isNotEmpty, isTrue);
      expect(totals.topUpRecommendations.first.additionalCartons, greaterThan(500));
    });

    test('Calculates statutory WeBOC/PSW cascading duty with 1% landing and filer vs non-filer', () {
      final filerItem = ProductItem(
        id: 'statutory_filer',
        name: 'Auto Spare Parts',
        modelNumber: 'SP-101',
        supplierName: 'Guangzhou Parts',
        orderedCartons: 10,
        piecesPerCarton: 10, // 100 pcs
        unitPriceOrigin: 100.0,
        dutySpec: const DutySpec(
          mode: DutyMode.statutoryCascade,
          landingChargesPct: 1.0,
          customsDutyPct: 20.0,
          additionalCustomsDutyPct: 6.0,
          regulatoryDutyPct: 10.0,
          salesTaxPct: 18.0,
          additionalSalesTaxPct: 3.0,
          withholdingTaxPct: 6.0,
          isFiler: true,
        ),
      );

      final nonFilerItem = filerItem.copyWith(
        id: 'statutory_non_filer',
        dutySpec: filerItem.dutySpec.copyWith(isFiler: false),
      );

      // Assessed CIF = 100,000 * 1.01 = 101,000
      final filerDuty = CalculationEngine.calculateDuty(
        item: filerItem,
        purchaseBaseTotal: 100000.0,
        logisticsShareTotal: 0.0,
      );

      final nonFilerDuty = CalculationEngine.calculateDuty(
        item: nonFilerItem,
        purchaseBaseTotal: 100000.0,
        logisticsShareTotal: 0.0,
      );

      expect(filerDuty, greaterThan(0));
      expect(nonFilerDuty, greaterThan(filerDuty));
      // Non-filer has double WHT
      expect(nonFilerDuty - filerDuty, closeTo(101000 * 1.36 * 1.21 * 0.06, 500));
    });
  });
}

