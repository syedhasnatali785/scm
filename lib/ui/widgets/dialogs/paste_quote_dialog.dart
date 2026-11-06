import 'dart:convert';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/container_spec.dart';
import '../../../core/models/product_item.dart';
import '../../../state/shipment_state.dart';

class PasteQuoteDialog extends ConsumerStatefulWidget {
  const PasteQuoteDialog({super.key});

  @override
  ConsumerState<PasteQuoteDialog> createState() => _PasteQuoteDialogState();
}

class _PasteQuoteDialogState extends ConsumerState<PasteQuoteDialog> {
  int _activeTab = 0; // 0 = Raw Text (WeChat/WhatsApp), 1 = Upload Excel/CSV
  String? _uploadedFileName;

  final TextEditingController _textCtrl = TextEditingController(
    text: '''HF Electric Jeep 601, HF-601-RED, 135*75*52cm, 50 ctns, 450 RMB, 28.5kg
Super Drift Go-Kart, GK-24V-BLK, 110x62x38cm, 60 ctns, 380 RMB, 22.0kg
Toddler Balance Bike, BB-4IN1-BLU, 68*32*30 cm, 80 ctns, 85 RMB, 10.5kg
Solar Inverter 5kW, INV-5K-PRO, 65*42*38cm, 40 ctns, 1200 RMB, 32.0kg''',
  );

  List<ProductItem> _parsedPreview = [];

  // Regex patterns
  static final RegExp _dimRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:[*xX×])\s*(\d+(?:\.\d+)?)\s*(?:[*xX×])\s*(\d+(?:\.\d+)?)\s*(cm|mm|m|in)?',
    caseSensitive: false,
  );
  static final RegExp _weightRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:kg|kgs|gross\s*wt)',
    caseSensitive: false,
  );
  static final RegExp _priceRegex = RegExp(
    r'(?:¥|\$|rmb|usd)?\s*(\d+(?:\.\d+)?)\s*(?:rmb|usd|yuan|\$|¥)',
    caseSensitive: false,
  );
  static final RegExp _cartonsRegex = RegExp(
    r'(\d+)\s*(?:ctns?|cartons?|boxes?)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _parseText();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _parseText() {
    final lines = _textCtrl.text.split('\n');
    final items = <ProductItem>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Extract Dimensions using Regex e.g. 65*42*38cm or 110x62x38
      double l = 60.0, w = 40.0, h = 40.0;
      DimensionUnit unit = DimensionUnit.cm;
      final dimMatch = _dimRegex.firstMatch(line);
      if (dimMatch != null) {
        l = double.tryParse(dimMatch.group(1) ?? '') ?? l;
        w = double.tryParse(dimMatch.group(2) ?? '') ?? w;
        h = double.tryParse(dimMatch.group(3) ?? '') ?? h;
        final unitStr = dimMatch.group(4)?.toLowerCase();
        if (unitStr == 'mm') unit = DimensionUnit.mm;
        if (unitStr == 'm') unit = DimensionUnit.m;
        if (unitStr == 'in') unit = DimensionUnit.inch;
      }

      // Extract Gross Weight e.g. 28.5kg
      double gw = 18.0;
      final gwMatch = _weightRegex.firstMatch(line);
      if (gwMatch != null) {
        gw = double.tryParse(gwMatch.group(1) ?? '') ?? gw;
      }

      // Extract Price & Currency e.g. 450 RMB or $85 USD
      double price = 350.0;
      String currency = 'RMB';
      final priceMatch = _priceRegex.firstMatch(line);
      if (priceMatch != null) {
        price = double.tryParse(priceMatch.group(1) ?? '') ?? price;
        if (line.toLowerCase().contains('usd') || line.contains('\$')) {
          currency = 'USD';
        }
      }

      // Extract Cartons e.g. 50 ctns
      int cartons = 50;
      final ctnMatch = _cartonsRegex.firstMatch(line);
      if (ctnMatch != null) {
        cartons = int.tryParse(ctnMatch.group(1) ?? '') ?? cartons;
      }

      // Split comma or tab for Name & SKU
      final tokens = line.contains('\t') ? line.split('\t') : line.split(',');
      String name = 'Factory Cargo';
      String sku = 'SKU-${items.length + 1}';

      if (tokens.isNotEmpty) {
        name = tokens[0].trim();
      }
      if (tokens.length > 1) {
        final candidateSku = tokens[1].trim();
        // If not a dimension token, assign as SKU
        if (!_dimRegex.hasMatch(candidateSku) && !_priceRegex.hasMatch(candidateSku)) {
          sku = candidateSku;
        }
      }

      // Determine appropriate default Stacking Tier based on weight
      StackingTier tier = StackingTier.mediumMiddle;
      if (gw >= 28.0) {
        tier = StackingTier.heavyFloor;
      } else if (gw <= 12.0) {
        tier = StackingTier.fragileTop;
      }

      items.add(ProductItem(
        id: const Uuid().v4(),
        name: name,
        modelNumber: sku,
        supplierName: 'Direct Import Supplier',
        cartonLength: l,
        cartonWidth: w,
        cartonHeight: h,
        dimensionUnit: unit,
        orderedCartons: cartons,
        piecesPerCarton: 1,
        gwPerCartonKg: gw,
        nwPerCartonKg: gw * 0.88,
        unitPriceOrigin: price,
        originCurrency: currency,
        stackingTier: tier,
        orientationConstraint: OrientationConstraint.uprightOnly,
      ));
    }

    setState(() => _parsedPreview = items);
  }

  Future<void> _pickAndParseFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() => _uploadedFileName = file.name);

      final items = <ProductItem>[];

      if (file.name.endsWith('.csv')) {
        final content = utf8.decode(bytes);
        _textCtrl.text = content;
        _parseText();
      } else {
        // Parse Excel using excel package
        final excel = ex.Excel.decodeBytes(bytes);
        for (final table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet == null) continue;

          bool isHeader = true;
          for (final row in sheet.rows) {
            if (row.isEmpty) continue;
            final rowStrings = row.map((cell) => cell?.value?.toString() ?? '').toList();

            // Skip header row
            if (isHeader) {
              isHeader = false;
              continue;
            }

            final rowLine = rowStrings.where((s) => s.trim().isNotEmpty).join(', ');
            if (rowLine.isNotEmpty) {
              // Parse line using intelligent regex engine
              final dimMatch = _dimRegex.firstMatch(rowLine);
              double l = 60, w = 40, h = 40;
              if (dimMatch != null) {
                l = double.tryParse(dimMatch.group(1) ?? '') ?? l;
                w = double.tryParse(dimMatch.group(2) ?? '') ?? w;
                h = double.tryParse(dimMatch.group(3) ?? '') ?? h;
              }

              final gwMatch = _weightRegex.firstMatch(rowLine);
              double gw = gwMatch != null ? (double.tryParse(gwMatch.group(1) ?? '') ?? 18.0) : 18.0;

              final priceMatch = _priceRegex.firstMatch(rowLine);
              double price = priceMatch != null ? (double.tryParse(priceMatch.group(1) ?? '') ?? 350.0) : 350.0;

              final ctnMatch = _cartonsRegex.firstMatch(rowLine);
              int cartons = ctnMatch != null ? (int.tryParse(ctnMatch.group(1) ?? '') ?? 50) : 50;

              items.add(ProductItem(
                id: const Uuid().v4(),
                name: rowStrings.isNotEmpty ? rowStrings[0] : 'Imported Item',
                modelNumber: rowStrings.length > 1 ? rowStrings[1] : 'SKU-${items.length + 1}',
                supplierName: 'Excel Packing List',
                cartonLength: l,
                cartonWidth: w,
                cartonHeight: h,
                orderedCartons: cartons,
                piecesPerCarton: 1,
                gwPerCartonKg: gw,
                nwPerCartonKg: gw * 0.9,
                unitPriceOrigin: price,
                originCurrency: 'RMB',
              ));
            }
          }
        }

        if (items.isNotEmpty) {
          setState(() => _parsedPreview = items);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File parsing error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _parsedPreview.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 24),
          const SizedBox(width: 10),
          const Text(
            'Smart Data Importer & Packing List Parser',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Mode switch tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _tabPill('WeChat / Text', 0),
                _tabPill('Upload Excel / CSV', 1),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeTab == 0) ...[
              const Text(
                'Paste raw text from WeChat, WhatsApp, or email quotes. The intelligent regex engine automatically parses dimensions (e.g. 65*42*38cm), weights, cartons, and prices:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  hintText: 'Paste lines here (comma or tab separated)...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => _parseText(),
              ),
            ] else ...[
              // Upload Excel / CSV drag and drop zone
              InkWell(
                onTap: _pickAndParseFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131D38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7), style: BorderStyle.solid, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8), size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _uploadedFileName != null
                            ? 'Loaded File: $_uploadedFileName (Click to Replace)'
                            : 'Click to Upload Factory Packing List (.xlsx, .xls, .csv)',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Supports multi-column spreadsheets with auto-mapping for Dimensions, Cartons, Weight, and FOB price',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Header for parsed table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'MAPPED PRODUCT ITEMS (${_parsedPreview.length} SKUs Ready to Import):',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF38BDF8)),
                  label: const Text('Re-parse', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                  onPressed: _parseText,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Parsed Table View
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131D38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF223154)),
                ),
                child: _parsedPreview.isEmpty
                    ? const Center(
                        child: Text('No recognized SKUs yet. Paste text or upload a file.', style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: _parsedPreview.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B)),
                        itemBuilder: (ctx, i) {
                          final p = _parsedPreview[i];
                          return Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: p.boxColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    Text(
                                      '${p.modelNumber} · ${p.cartonLength.toStringAsFixed(0)}×${p.cartonWidth.toStringAsFixed(0)}×${p.cartonHeight.toStringAsFixed(0)} cm (${p.cbmPerCarton.toStringAsFixed(3)} m³/ctn)',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${p.orderedCartons} Ctns (${p.totalPieces} pcs)',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${p.gwPerCartonKg.toStringAsFixed(1)} kg / ctn',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${p.originCurrency} ${p.unitPriceOrigin.toStringAsFixed(0)} FOB',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                tooltip: 'Remove SKU',
                                onPressed: () => _removeItem(i),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
          icon: const Icon(Icons.check, size: 16, color: Colors.white),
          label: Text('Import ${_parsedPreview.length} SKUs into Shipment', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: _parsedPreview.isEmpty
              ? null
              : () {
                  for (final item in _parsedPreview) {
                    ref.read(productItemsProvider.notifier).addItem(item);
                  }
                  Navigator.pop(context);
                },
        ),
      ],
    );
  }

  Widget _tabPill(String title, int index) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
