import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/models/calculation_results.dart';
import '../../core/models/container_spec.dart';
import '../../core/models/product_item.dart';
import '../../core/utils/file_downloader.dart';

class ReportGenerator {
  // ==========================================
  // 1. OWNER'S COMPLETE FINANCIAL AUDIT SHEET
  // ==========================================

  static Future<void> exportOwnerFinancialAuditExcel({
    required List<ProductItem> items,
    required ContainerSpec container,
    required CalculatedShipmentTotals totals,
    required Map<String, CalculatedLineItem?> calculatedLines,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Financial Audit';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    // Title Block
    sheet.appendRow([
      TextCellValue("71 INTERNATIONAL — OWNER'S COMPLETE FINANCIAL AUDIT"),
    ]);
    sheet.appendRow([
      TextCellValue('Container: ${container.name} (${container.usableCbm.toStringAsFixed(1)} CBM Usable)'),
    ]);
    sheet.appendRow([
      TextCellValue('Total Landed Cost: PKR ${totals.totalLandedCostBase.toStringAsFixed(0)} | Projected Net Profit: PKR ${totals.totalProjectedNetProfit.toStringAsFixed(0)} (${totals.overallMarginPct.toStringAsFixed(1)}% Margin)'),
    ]);
    sheet.appendRow([TextCellValue('')]);

    // Headers
    sheet.appendRow([
      TextCellValue('SKU / Model'),
      TextCellValue('Item Name'),
      TextCellValue('Cartons'),
      TextCellValue('Pcs/Ctn'),
      TextCellValue('Total Pcs'),
      TextCellValue('Total CBM'),
      TextCellValue('Gross Wt (kg)'),
      TextCellValue('FOB Price'),
      TextCellValue('Origin Curr'),
      TextCellValue('FOB Total (PKR)'),
      TextCellValue('Logistics Share (PKR)'),
      TextCellValue('Customs Duty Base (PKR)'),
      TextCellValue('SKD Value Add (PKR)'),
      TextCellValue('Total Line Cost (PKR)'),
      TextCellValue('Unit Landed Cost (ULC)'),
      TextCellValue('Target Markup %'),
      TextCellValue('Selling Price (PKR)'),
      TextCellValue('Projected Net Profit (PKR)'),
    ]);

    for (final item in items) {
      final line = calculatedLines[item.id];
      sheet.appendRow([
        TextCellValue(item.modelNumber),
        TextCellValue(item.name),
        IntCellValue(item.orderedCartons),
        IntCellValue(item.piecesPerCarton),
        IntCellValue(item.totalPieces),
        DoubleCellValue(double.parse(item.totalLineCbm.toStringAsFixed(2))),
        DoubleCellValue(double.parse(item.totalLineGwKg.toStringAsFixed(1))),
        DoubleCellValue(item.unitPriceOrigin),
        TextCellValue(item.originCurrency),
        DoubleCellValue(line != null ? double.parse(line.purchaseBaseTotal.toStringAsFixed(0)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.logisticsShareTotal.toStringAsFixed(0)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.dutyBaseTotal.toStringAsFixed(0)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.assemblyBaseTotal.toStringAsFixed(0)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.totalLineCost.toStringAsFixed(0)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.unitLandedCost.toStringAsFixed(2)) : 0.0),
        DoubleCellValue(item.targetMarkupPct),
        DoubleCellValue(line != null ? double.parse(line.projectedSellingPrice.toStringAsFixed(2)) : 0.0),
        DoubleCellValue(line != null ? double.parse(line.projectedLineNetProfit.toStringAsFixed(0)) : 0.0),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      FileDownloader.save(
        bytes: Uint8List.fromList(bytes),
        fileName: '71_International_Financial_Audit_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportOwnerFinancialAuditPdf({
    required List<ProductItem> items,
    required ContainerSpec container,
    required CalculatedShipmentTotals totals,
    required Map<String, CalculatedLineItem?> calculatedLines,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("71 INTERNATIONAL -- FINANCIAL AUDIT REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text("CONFIDENTIAL // OWNER EXECUTIVE", style: const pw.TextStyle(color: PdfColors.red800, fontSize: 10)),
                ],
              ),
            ),
            pw.Text("Container: ${container.name} | Total Investment: PKR ${totals.totalLandedCostBase.toStringAsFixed(0)} | Projected Profit: PKR ${totals.totalProjectedNetProfit.toStringAsFixed(0)} (${totals.overallMarginPct.toStringAsFixed(1)}% Margin)", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['SKU', 'Name', 'Ctns', 'Pcs', 'CBM', 'GW (kg)', 'FOB', 'Logistics', 'Duty', 'SKD', 'ULC (PKR)', 'Sell Price', 'Net Profit'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: items.map((item) {
                final line = calculatedLines[item.id];
                return [
                  item.modelNumber,
                  item.name,
                  '${item.orderedCartons}',
                  '${item.totalPieces}',
                  item.totalLineCbm.toStringAsFixed(2),
                  item.totalLineGwKg.toStringAsFixed(1),
                  '${item.unitPriceOrigin.toStringAsFixed(0)} ${item.originCurrency}',
                  line != null ? line.logisticsShareTotal.toStringAsFixed(0) : '-',
                  line != null ? line.dutyBaseTotal.toStringAsFixed(0) : '-',
                  line != null ? line.assemblyBaseTotal.toStringAsFixed(0) : '-',
                  line != null ? line.unitLandedCost.toStringAsFixed(1) : '-',
                  line != null ? line.projectedSellingPrice.toStringAsFixed(1) : '-',
                  line != null ? '+${line.projectedLineNetProfit.toStringAsFixed(0)}' : '-',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    FileDownloader.save(
      bytes: bytes,
      fileName: '71_International_Financial_Audit_${DateTime.now().millisecondsSinceEpoch}.pdf',
      mimeType: 'application/pdf',
    );
  }

  // ==========================================
  // 2. CHINA SUPPLIER PURCHASE ORDER (PO)
  // (RMB only, hiding all Pakistan duties and profit margins)
  // ==========================================

  static Future<void> exportSupplierPurchaseOrderExcel({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Purchase Order';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    sheet.appendRow([TextCellValue('PURCHASE ORDER (PO) — 71 INTERNATIONAL TRADING')]);
    sheet.appendRow([TextCellValue('Destination Equipment: ${container.name} Container')]);
    sheet.appendRow([TextCellValue('Note: Strictly Supplier Facing. Terms: FOB China Port.')]);
    sheet.appendRow([TextCellValue('')]);

    // Supplier Facing Headers (No Pakistan Duties, No Margins)
    sheet.appendRow([
      TextCellValue('Item #'),
      TextCellValue('Model / SKU'),
      TextCellValue('Product Description'),
      TextCellValue('Supplier / Factory'),
      TextCellValue('Carton L (cm)'),
      TextCellValue('Carton W (cm)'),
      TextCellValue('Carton H (cm)'),
      TextCellValue('CBM / Ctn'),
      TextCellValue('Gross Wt (kg/ctn)'),
      TextCellValue('Ordered Cartons'),
      TextCellValue('Pieces / Ctn'),
      TextCellValue('Total Quantity (Pcs)'),
      TextCellValue('Total Volume (CBM)'),
      TextCellValue('Total GW (kg)'),
      TextCellValue('FOB Unit Price'),
      TextCellValue('Currency'),
      TextCellValue('Line Total Amount'),
    ]);

    double grandTotalRmb = 0.0;
    int grandTotalCartons = 0;
    int grandTotalPieces = 0;
    double grandTotalCbm = 0.0;
    double grandTotalGw = 0.0;

    int idx = 1;
    for (final item in items) {
      final lineFob = item.totalPieces * item.unitPriceOrigin;
      grandTotalRmb += lineFob;
      grandTotalCartons += item.orderedCartons;
      grandTotalPieces += item.totalPieces;
      grandTotalCbm += item.totalLineCbm;
      grandTotalGw += item.totalLineGwKg;

      sheet.appendRow([
        IntCellValue(idx++),
        TextCellValue(item.modelNumber),
        TextCellValue(item.name),
        TextCellValue(item.supplierName),
        DoubleCellValue(item.cartonLength),
        DoubleCellValue(item.cartonWidth),
        DoubleCellValue(item.cartonHeight),
        DoubleCellValue(double.parse(item.cbmPerCarton.toStringAsFixed(3))),
        DoubleCellValue(item.gwPerCartonKg),
        IntCellValue(item.orderedCartons),
        IntCellValue(item.piecesPerCarton),
        IntCellValue(item.totalPieces),
        DoubleCellValue(double.parse(item.totalLineCbm.toStringAsFixed(2))),
        DoubleCellValue(double.parse(item.totalLineGwKg.toStringAsFixed(1))),
        DoubleCellValue(item.unitPriceOrigin),
        TextCellValue(item.originCurrency),
        DoubleCellValue(lineFob),
      ]);
    }

    // Totals Row
    sheet.appendRow([
      TextCellValue('TOTALS:'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      IntCellValue(grandTotalCartons),
      TextCellValue(''),
      IntCellValue(grandTotalPieces),
      DoubleCellValue(double.parse(grandTotalCbm.toStringAsFixed(2))),
      DoubleCellValue(double.parse(grandTotalGw.toStringAsFixed(1))),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(grandTotalRmb),
    ]);

    final bytes = excel.save();
    if (bytes != null) {
      FileDownloader.save(
        bytes: Uint8List.fromList(bytes),
        fileName: '71_International_Supplier_PO_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportSupplierPurchaseOrderPdf({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          double totalFob = 0.0;
          for (final i in items) {
            totalFob += i.totalPieces * i.unitPriceOrigin;
          }

          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("COMMERCIAL PURCHASE ORDER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text("71 INTERNATIONAL TRADING", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue800)),
                ],
              ),
            ),
            pw.Text("Loading Equipment: ${container.name} | Port of Origin: China Main Ports (FOB)", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: ['Model / SKU', 'Product Description', 'Ctns', 'Pcs/Ctn', 'Total Pcs', 'L*W*H (cm)', 'GW (kg)', 'FOB Price', 'Total (FOB)'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              data: items.map((item) {
                final lineFob = item.totalPieces * item.unitPriceOrigin;
                return [
                  item.modelNumber,
                  item.name,
                  '${item.orderedCartons}',
                  '${item.piecesPerCarton}',
                  '${item.totalPieces}',
                  '${item.cartonLength.toStringAsFixed(0)}*${item.cartonWidth.toStringAsFixed(0)}*${item.cartonHeight.toStringAsFixed(0)}',
                  '${item.totalLineGwKg.toStringAsFixed(1)} kg',
                  '${item.unitPriceOrigin.toStringAsFixed(2)} ${item.originCurrency}',
                  '${lineFob.toStringAsFixed(2)} ${item.originCurrency}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total Order Amount: ¥ ${totalFob.toStringAsFixed(2)} RMB", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    FileDownloader.save(
      bytes: bytes,
      fileName: '71_International_Supplier_PO_${DateTime.now().millisecondsSinceEpoch}.pdf',
      mimeType: 'application/pdf',
    );
  }

  // ====================================================
  // 3. WAREHOUSE RECEIVING & ASSEMBLY CHECKLIST
  // (Zero monetary data, focusing on physical tally & QA)
  // ====================================================

  static Future<void> exportWarehouseReceivingChecklistExcel({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Warehouse Checklist';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);

    sheet.appendRow([TextCellValue('WAREHOUSE RECEIVING & SKD ASSEMBLY TALLY SHEET')]);
    sheet.appendRow([TextCellValue('Container: ${container.name} | Strictly for Warehouse Staff (No Prices Included)')]);
    sheet.appendRow([TextCellValue('')]);

    sheet.appendRow([
      TextCellValue('SKU / Code'),
      TextCellValue('Model Name'),
      TextCellValue('Stacking Tier'),
      TextCellValue('Carton Dimensions (cm)'),
      TextCellValue('Expected Cartons'),
      TextCellValue('Received Cartons [ ]'),
      TextCellValue('Pieces / Ctn'),
      TextCellValue('Total Expected Pieces'),
      TextCellValue('Received Pieces [ ]'),
      TextCellValue('Total GW (kg)'),
      TextCellValue('SKD Assembly Required?'),
      TextCellValue('QC Damage / Defect Count [ ]'),
      TextCellValue('Inspector Sign-off [ ]'),
    ]);

    for (final item in items) {
      sheet.appendRow([
        TextCellValue(item.modelNumber),
        TextCellValue(item.name),
        TextCellValue(item.stackingTier.label),
        TextCellValue('${item.cartonLength.toStringAsFixed(0)} x ${item.cartonWidth.toStringAsFixed(0)} x ${item.cartonHeight.toStringAsFixed(0)}'),
        IntCellValue(item.orderedCartons),
        TextCellValue('[  ]'),
        IntCellValue(item.piecesPerCarton),
        IntCellValue(item.totalPieces),
        TextCellValue('[  ]'),
        DoubleCellValue(double.parse(item.totalLineGwKg.toStringAsFixed(1))),
        TextCellValue(item.assemblySpec.isEnabled ? 'YES (Local Box & Labor)' : 'NO (Finished Goods)'),
        TextCellValue('[  ]'),
        TextCellValue('[  ]'),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      FileDownloader.save(
        bytes: Uint8List.fromList(bytes),
        fileName: '71_International_Warehouse_Receiving_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  static Future<void> exportWarehouseReceivingChecklistPdf({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("WAREHOUSE RECEIVING & ASSEMBLY TALLY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text("OPERATIONAL FLOOR COPY", style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                ],
              ),
            ),
            pw.Text("Container: ${container.name} | Door Clearance: ${(container.doorHeightCm * 10).toStringAsFixed(0)} mm | Total Cargo Weight: ${items.fold<double>(0.0, (acc, i) => acc + i.totalLineGwKg).toStringAsFixed(0)} kg", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['SKU / Code', 'Product Name', 'Tier', 'Expected Ctns', 'Actual [v]', 'Total Pcs', 'Assembly', 'Defect Count', 'Verified'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              data: items.map((item) {
                return [
                  item.modelNumber,
                  item.name,
                  item.stackingTier.label,
                  '${item.orderedCartons}',
                  '[    ]',
                  '${item.totalPieces}',
                  item.assemblySpec.isEnabled ? 'YES' : 'NO',
                  '[    ]',
                  '[    ]',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    FileDownloader.save(
      bytes: bytes,
      fileName: '71_International_Warehouse_Receiving_${DateTime.now().millisecondsSinceEpoch}.pdf',
      mimeType: 'application/pdf',
    );
  }
}
