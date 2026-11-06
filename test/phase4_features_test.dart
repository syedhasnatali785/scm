import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scm/core/models/calculation_results.dart';
import 'package:scm/core/models/container_spec.dart';
import 'package:scm/core/models/cost_node.dart';
import 'package:scm/core/models/currency.dart';
import 'package:scm/core/models/duty_and_assembly.dart';
import 'package:scm/core/models/product_item.dart';
import 'package:scm/core/services/media_service.dart';
import 'package:scm/core/services/report_generator.dart';
import 'package:scm/engine/calculation_engine.dart';

void main() {
  group('Phase 4: Smart Regex Parser Tests', () {
    test('Extracts dimensions from composite strings like 65*42*38cm', () {
      final dimRegex = RegExp(
        r'(\d+(?:\.\d+)?)\s*[*xX×]\s*(\d+(?:\.\d+)?)\s*[*xX×]\s*(\d+(?:\.\d+)?)\s*(cm|mm|m|in)?',
        caseSensitive: false,
      );

      final match1 = dimRegex.firstMatch('HF-601 Electric Jeep 65*42*38cm 50ctns');
      expect(match1, isNotNull);
      expect(double.parse(match1!.group(1)!), equals(65.0));
      expect(double.parse(match1.group(2)!), equals(42.0));
      expect(double.parse(match1.group(3)!), equals(38.0));
      expect(match1.group(4)?.toLowerCase(), equals('cm'));

      final match2 = dimRegex.firstMatch('Size: 120 x 80 x 50 mm, G.W. 25kg');
      expect(match2, isNotNull);
      expect(double.parse(match2!.group(1)!), equals(120.0));
      expect(double.parse(match2.group(2)!), equals(80.0));
      expect(double.parse(match2.group(3)!), equals(50.0));
      expect(match2.group(4)?.toLowerCase(), equals('mm'));
    });

    test('Extracts weight, quantity and pricing from unstructured quote text', () {
      final text = 'Model: TRK-99, 120 ctns, 24 pcs/ctn, 28.5kg gross, 450 RMB each, 85*50*40cm';

      final qtyRegex = RegExp(r'(\d+)\s*(?:ctns?|cartons?|boxes?)', caseSensitive: false);
      final qtyMatch = qtyRegex.firstMatch(text);
      expect(qtyMatch, isNotNull);
      expect(int.parse(qtyMatch!.group(1)!), equals(120));

      final pcsRegex = RegExp(r'(\d+)\s*(?:pcs|pieces|units?)(?:\s*/\s*ctn)?', caseSensitive: false);
      final pcsMatch = pcsRegex.firstMatch(text);
      expect(pcsMatch, isNotNull);
      expect(int.parse(pcsMatch!.group(1)!), equals(24));

      final weightRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kgs)', caseSensitive: false);
      final weightMatch = weightRegex.firstMatch(text);
      expect(weightMatch, isNotNull);
      expect(double.parse(weightMatch!.group(1)!), equals(28.5));

      final priceRegex = RegExp(r'(?:[¥\$]|RMB|USD)\s*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(?:RMB|USD|yuan)', caseSensitive: false);
      final priceMatch = priceRegex.firstMatch(text);
      expect(priceMatch, isNotNull);
      final priceVal = double.parse(priceMatch!.group(1) ?? priceMatch.group(2)!);
      expect(priceVal, equals(450.0));
    });
  });

  group('Phase 4: Client-Side Media Compression (< 15 KB)', () {
    test('Compresses high-resolution image to under 15 KB thumbnail', () {
      final testImage = img.Image(width: 800, height: 800);
      for (var y = 0; y < 800; y++) {
        for (var x = 0; x < 800; x++) {
          testImage.setPixelRgb(x, y, (x % 256), (y % 256), ((x + y) % 256));
        }
      }
      final rawBytes = Uint8List.fromList(img.encodePng(testImage));
      expect(rawBytes.lengthInBytes, greaterThan(1000));

      final compressedBytes = MediaService.compressToThumbnailWebP(rawBytes, targetMaxKb: 15);
      expect(compressedBytes.lengthInBytes, lessThanOrEqualTo(15 * 1024));

      final decoded = img.decodeImage(compressedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(256));
      expect(decoded.height, lessThanOrEqualTo(256));
    });
  });

  group('Phase 4: Sanitized Pro-Forma Exports (.xlsx and .pdf)', () {
    late ContainerSpec container;
    late Map<String, CurrencyRate> currencies;
    late List<CostNode> costNodes;
    late List<ProductItem> items;
    late CalculatedShipmentTotals totals;

    setUp(() {
      container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      currencies = {
        for (var c in CurrencyRate.defaultCurrencies()) c.code: c,
      };
      costNodes = CostNode.defaultPipeline();

      items = [
        ProductItem(
          id: 'item_1',
          name: 'Kids Ride-On 4x4 Jeep',
          modelNumber: 'JEP-4X4-BLK',
          supplierName: 'Zhejiang Kids Toy Factory',
          cartonLength: 120.0,
          cartonWidth: 70.0,
          cartonHeight: 50.0,
          dimensionUnit: DimensionUnit.cm,
          orderedCartons: 50,
          piecesPerCarton: 1,
          nwPerCartonKg: 22.0,
          gwPerCartonKg: 25.0,
          unitPriceOrigin: 380.0,
          originCurrency: 'RMB',
          dutySpec: const DutySpec(
            mode: DutyMode.statutoryCascade,
            customsDutyPct: 20.0,
            salesTaxPct: 18.0,
            withholdingTaxPct: 6.0,
          ),
          assemblySpec: const AssemblySpec(
            isEnabled: true,
            localBoxCost: 350.0,
            technicianLaborCost: 500.0,
            localPartsCost: 800.0,
            defectWastagePct: 1.5,
          ),
          targetMarkupPct: 30.0,
        ),
        ProductItem(
          id: 'item_2',
          name: 'Balance Bike Alloy 12in',
          modelNumber: 'BIKE-12-AL',
          supplierName: 'Guangdong Cycling Co.',
          cartonLength: 75.0,
          cartonWidth: 20.0,
          cartonHeight: 45.0,
          dimensionUnit: DimensionUnit.cm,
          orderedCartons: 100,
          piecesPerCarton: 2,
          nwPerCartonKg: 7.0,
          gwPerCartonKg: 8.5,
          unitPriceOrigin: 95.0,
          originCurrency: 'RMB',
          dutySpec: const DutySpec(
            mode: DutyMode.flatRate,
            flatBasis: FlatRateBasis.perPiece,
            flatRateAmount: 850.0,
          ),
          assemblySpec: const AssemblySpec(isEnabled: false),
          targetMarkupPct: 25.0,
        ),
      ];

      totals = CalculationEngine.calculate(
        items: items,
        container: container,
        currencyRates: currencies,
        costNodes: costNodes,
      );
    });

    test('Executes Owner Audit Excel & PDF export workflows without exceptions', () async {
      final sampleLine = CalculatedLineItem(
        itemId: items[0].id,
        purchaseBaseTotal: 100000.0,
        purchaseBasePerPiece: 2000.0,
        logisticsShareTotal: 25000.0,
        logisticsSharePerPiece: 500.0,
        dutyBaseTotal: 40000.0,
        dutyBasePerPiece: 800.0,
        assemblyBaseTotal: 15000.0,
        assemblyBasePerPiece: 300.0,
        totalLineCost: 180000.0,
        sellablePieces: 50.0,
        unitLandedCost: 3600.0,
        projectedSellingPrice: 4680.0,
        effectiveMarkupPct: 30.0,
        effectiveMarginPct: 23.08,
        projectedLineRevenue: 234000.0,
        projectedLineNetProfit: 54000.0,
      );

      final calculatedLines = <String, CalculatedLineItem?>{
        items[0].id: sampleLine,
        items[1].id: null,
      };

      await expectLater(
        ReportGenerator.exportOwnerFinancialAuditExcel(
          items: items,
          container: container,
          totals: totals,
          calculatedLines: calculatedLines,
        ),
        completes,
      );

      await expectLater(
        ReportGenerator.exportOwnerFinancialAuditPdf(
          items: items,
          container: container,
          totals: totals,
          calculatedLines: calculatedLines,
        ),
        completes,
      );
    });

    test('Executes China Supplier PO (RMB Only) export workflows without exceptions', () async {
      await expectLater(
        ReportGenerator.exportSupplierPurchaseOrderExcel(
          items: items,
          container: container,
        ),
        completes,
      );

      await expectLater(
        ReportGenerator.exportSupplierPurchaseOrderPdf(
          items: items,
          container: container,
        ),
        completes,
      );
    });

    test('Executes Warehouse Receiving Checklist (Zero monetary amounts) export workflows without exceptions', () async {
      await expectLater(
        ReportGenerator.exportWarehouseReceivingChecklistExcel(
          items: items,
          container: container,
        ),
        completes,
      );

      await expectLater(
        ReportGenerator.exportWarehouseReceivingChecklistPdf(
          items: items,
          container: container,
        ),
        completes,
      );
    });
  });

  group('Phase 4: Financial Analytics Sensitivity & Break-Even', () {
    test('Calculates exchange rate stress accurately', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      final currencies = {
        for (var c in CurrencyRate.defaultCurrencies()) c.code: c,
      };
      final costNodes = CostNode.defaultPipeline();

      final item = ProductItem(
        id: 'item_1',
        name: 'Electric Scooter E-10',
        modelNumber: 'SCOOT-E10',
        supplierName: 'Ningbo Scooter Factory',
        cartonLength: 100.0,
        cartonWidth: 50.0,
        cartonHeight: 40.0,
        dimensionUnit: DimensionUnit.cm,
        orderedCartons: 100,
        piecesPerCarton: 1,
        nwPerCartonKg: 15.0,
        gwPerCartonKg: 18.0,
        unitPriceOrigin: 500.0,
        originCurrency: 'RMB',
        dutySpec: const DutySpec(
          mode: DutyMode.statutoryCascade,
          customsDutyPct: 20.0,
          salesTaxPct: 18.0,
        ),
        targetMarkupPct: 25.0,
      );

      final baselineTotals = CalculationEngine.calculate(
        items: [item],
        container: container,
        currencyRates: currencies,
        costNodes: costNodes,
      );

      // Stressed currencies (+10% RMB/PKR)
      final stressedCurrencies = {
        ...currencies,
        'RMB': currencies['RMB']!.copyWith(
          rateToBase: currencies['RMB']!.rateToBase * 1.10,
        ),
      };

      final stressedTotals = CalculationEngine.calculate(
        items: [item],
        container: container,
        currencyRates: stressedCurrencies,
        costNodes: costNodes,
      );

      // Purchase cost in PKR must be exactly 10% higher
      expect(
        stressedTotals.totalPurchaseCostBase,
        closeTo(baselineTotals.totalPurchaseCostBase * 1.10, 0.01),
      );

      // Total landed cost must also increase
      expect(
        stressedTotals.totalLandedCostBase,
        greaterThan(baselineTotals.totalLandedCostBase),
      );
    });
  });
}
