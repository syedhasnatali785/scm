import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/container_spec.dart';
import '../../../core/models/duty_and_assembly.dart';
import '../../../core/models/product_item.dart';
import '../../../core/services/media_service.dart';
import '../../../core/utils/formula_evaluator.dart';
import '../../../state/shipment_state.dart';

class ProductEditDialog extends ConsumerStatefulWidget {
  final ProductItem? initialItem;

  const ProductEditDialog({super.key, this.initialItem});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _supplierCtrl;

  late TextEditingController _lengthCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  DimensionUnit _unit = DimensionUnit.cm;

  late TextEditingController _cartonsCtrl;
  late TextEditingController _pcsPerCtnCtrl;
  late TextEditingController _nwCtrl;
  late TextEditingController _gwCtrl;

  // 3D Spatial Stacking & Orientation
  StackingTier _stackingTier = StackingTier.mediumMiddle;
  OrientationConstraint _orientationConstraint = OrientationConstraint.uprightOnly;

  late TextEditingController _originPriceCtrl;
  String _originCurrency = 'RMB';

  // Duty
  DutyMode _dutyMode = DutyMode.flatRate;
  FlatRateBasis _flatBasis = FlatRateBasis.perKgGross;
  late TextEditingController _flatRateAmountCtrl;

  // Assembly
  bool _assemblyEnabled = false;
  late TextEditingController _boxCostCtrl;
  late TextEditingController _laborCostCtrl;
  late TextEditingController _partsCostCtrl;
  late TextEditingController _defectPctCtrl;

  // Pricing
  late TextEditingController _markupPctCtrl;
  late TextEditingController _competitorPriceCtrl;

  Color _boxColor = const Color(0xFF3B82F6);
  String? _photoUrl;
  bool _isUploadingPhoto = false;
  String? _nameError;

  static const List<Color> _palette = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF64748B), // Slate
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _modelCtrl = TextEditingController(text: item?.modelNumber ?? '');
    _supplierCtrl = TextEditingController(text: item?.supplierName ?? '');

    _lengthCtrl = TextEditingController(text: item != null ? item.cartonLength.toString() : '60');
    _widthCtrl = TextEditingController(text: item != null ? item.cartonWidth.toString() : '40');
    _heightCtrl = TextEditingController(text: item != null ? item.cartonHeight.toString() : '40');
    _unit = item?.dimensionUnit ?? DimensionUnit.cm;

    _cartonsCtrl = TextEditingController(text: item != null ? item.orderedCartons.toString() : '50');
    _pcsPerCtnCtrl = TextEditingController(text: item != null ? item.piecesPerCarton.toString() : '1');
    _nwCtrl = TextEditingController(text: item != null ? item.nwPerCartonKg.toString() : '15');
    _gwCtrl = TextEditingController(text: item != null ? item.gwPerCartonKg.toString() : '18');

    _stackingTier = item?.stackingTier ?? StackingTier.mediumMiddle;
    _orientationConstraint = item?.orientationConstraint ?? OrientationConstraint.uprightOnly;

    _originPriceCtrl = TextEditingController(text: item != null ? item.unitPriceOrigin.toString() : '350');
    _originCurrency = item?.originCurrency ?? 'RMB';

    _dutyMode = item?.dutySpec.mode ?? DutyMode.flatRate;
    _flatBasis = item?.dutySpec.flatBasis ?? FlatRateBasis.perKgGross;
    _flatRateAmountCtrl = TextEditingController(text: item != null ? item.dutySpec.flatRateAmount.toString() : '220');

    _assemblyEnabled = item?.assemblySpec.isEnabled ?? false;
    _boxCostCtrl = TextEditingController(text: item != null ? item.assemblySpec.localBoxCost.toString() : '350');
    _laborCostCtrl = TextEditingController(text: item != null ? item.assemblySpec.technicianLaborCost.toString() : '600');
    _partsCostCtrl = TextEditingController(text: item != null ? item.assemblySpec.localPartsCost.toString() : '1200');
    _defectPctCtrl = TextEditingController(text: item != null ? item.assemblySpec.defectWastagePct.toString() : '2.0');

    _markupPctCtrl = TextEditingController(text: item != null ? item.targetMarkupPct.toString() : '25.0');
    _competitorPriceCtrl = TextEditingController(text: item?.marketSellingPrice != null ? item!.marketSellingPrice.toString() : '');

    _boxColor = item?.boxColor ?? _palette[0];
    _photoUrl = item?.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _supplierCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _cartonsCtrl.dispose();
    _pcsPerCtnCtrl.dispose();
    _nwCtrl.dispose();
    _gwCtrl.dispose();
    _originPriceCtrl.dispose();
    _flatRateAmountCtrl.dispose();
    _boxCostCtrl.dispose();
    _laborCostCtrl.dispose();
    _partsCostCtrl.dispose();
    _defectPctCtrl.dispose();
    _markupPctCtrl.dispose();
    _competitorPriceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Product name is required');
      return;
    }
    setState(() => _nameError = null);

    final length = FormulaEvaluator.tryEvaluate(_lengthCtrl.text) ?? 60.0;
    final width = FormulaEvaluator.tryEvaluate(_widthCtrl.text) ?? 40.0;
    final height = FormulaEvaluator.tryEvaluate(_heightCtrl.text) ?? 40.0;

    final cartons = (FormulaEvaluator.tryEvaluate(_cartonsCtrl.text) ?? 50.0).round();
    final pcs = (FormulaEvaluator.tryEvaluate(_pcsPerCtnCtrl.text) ?? 1.0).round();
    final nw = FormulaEvaluator.tryEvaluate(_nwCtrl.text) ?? 15.0;
    final gw = FormulaEvaluator.tryEvaluate(_gwCtrl.text) ?? 18.0;

    final originPrice = FormulaEvaluator.tryEvaluate(_originPriceCtrl.text) ?? 350.0;
    final flatRate = FormulaEvaluator.tryEvaluate(_flatRateAmountCtrl.text) ?? 220.0;

    final boxCost = FormulaEvaluator.tryEvaluate(_boxCostCtrl.text) ?? 0.0;
    final laborCost = FormulaEvaluator.tryEvaluate(_laborCostCtrl.text) ?? 0.0;
    final partsCost = FormulaEvaluator.tryEvaluate(_partsCostCtrl.text) ?? 0.0;
    final defectPct = FormulaEvaluator.tryEvaluate(_defectPctCtrl.text) ?? 0.0;

    final markupPct = FormulaEvaluator.tryEvaluate(_markupPctCtrl.text) ?? 25.0;
    final competitorPrice = FormulaEvaluator.tryEvaluate(_competitorPriceCtrl.text);

    final item = ProductItem(
      id: widget.initialItem?.id ?? const Uuid().v4(),
      name: name,
      modelNumber: _modelCtrl.text.trim().isNotEmpty ? _modelCtrl.text.trim() : 'SKU-${const Uuid().v4().substring(0, 4)}',
      supplierName: _supplierCtrl.text.trim().isNotEmpty ? _supplierCtrl.text.trim() : 'Direct Factory',
      cartonLength: length,
      cartonWidth: width,
      cartonHeight: height,
      dimensionUnit: _unit,
      orderedCartons: cartons,
      piecesPerCarton: pcs,
      nwPerCartonKg: nw,
      gwPerCartonKg: gw,
      stackingTier: _stackingTier,
      orientationConstraint: _orientationConstraint,
      unitPriceOrigin: originPrice,
      originCurrency: _originCurrency,
      dutySpec: DutySpec(
        mode: _dutyMode,
        flatBasis: _flatBasis,
        flatRateAmount: flatRate,
      ),
      assemblySpec: AssemblySpec(
        isEnabled: _assemblyEnabled,
        localBoxCost: boxCost,
        technicianLaborCost: laborCost,
        localPartsCost: partsCost,
        defectWastagePct: defectPct,
      ),
      targetMarkupPct: markupPct,
      marketSellingPrice: competitorPrice,
      boxColor: _boxColor,
      photoUrl: _photoUrl,
    );

    if (widget.initialItem != null) {
      ref.read(productItemsProvider.notifier).updateItem(item);
    } else {
      ref.read(productItemsProvider.notifier).addItem(item);
    }

    Navigator.pop(context);
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return;
      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() => _isUploadingPhoto = true);
      final shipmentState = ref.read(shipmentViewModelProvider);
      final url = await MediaService.uploadProductThumbnail(
        orgId: shipmentState.activeOrgId,
        shipmentId: shipmentState.activeShipmentId,
        itemId: widget.initialItem?.id ?? const Uuid().v4(),
        rawBytes: bytes,
      );
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.initialItem != null ? 'Edit Product Item' : 'Add New Product to Container',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Info
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _inputField(
                      'Product Name',
                      _nameCtrl,
                      hint: 'e.g. HF Electric Jeep 601',
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField('Model # / SKU', _modelCtrl, hint: 'e.g. HF-601-RED'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField('Supplier Name', _supplierCtrl, hint: 'Factory Co.'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Dimensions & Unit
              const Text('CARTON DIMENSIONS & PACKAGING:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _inputField('Length', _lengthCtrl, hint: 'cm/mm/in')),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField('Width', _widthCtrl, hint: 'cm/mm/in')),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField('Height', _heightCtrl, hint: 'cm/mm/in')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<DimensionUnit>(
                      value: _unit,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: DimensionUnit.values
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? DimensionUnit.cm),
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Quantities & Weights (With inline math evaluation hint)
              Row(
                children: [
                  Expanded(child: _inputField('Ordered Cartons (supports e.g. 10*12)', _cartonsCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField('Pcs / Carton', _pcsPerCtnCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField('Net Wt / Ctn (kg)', _nwCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField('Gross Wt / Ctn (kg)', _gwCtrl)),
                ],
              ),
              const SizedBox(height: 12),

              // 3B. 3D Spatial Stacking Tier & Orientation Constraints
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<StackingTier>(
                      value: _stackingTier,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: StackingTier.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _stackingTier = v ?? StackingTier.mediumMiddle),
                      decoration: InputDecoration(
                        labelText: '3D Stacking Tier',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<OrientationConstraint>(
                      value: _orientationConstraint,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: OrientationConstraint.values
                          .map((o) => DropdownMenuItem(value: o, child: Text(o.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _orientationConstraint = v ?? OrientationConstraint.uprightOnly),
                      decoration: InputDecoration(
                        labelText: 'Orientation Freedom',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Origin Purchase Cost
              const Text('ORIGIN FACTORY PURCHASE PRICE:', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _inputField('FOB Unit Price', _originPriceCtrl, hint: 'e.g. 450'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _originCurrency,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: ['RMB', 'USD', 'EUR', 'AED', 'PKR']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _originCurrency = v ?? 'RMB'),
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Duty Mode & Flat Rate
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DutyMode>(
                      value: _dutyMode,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: DutyMode.values
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _dutyMode = v ?? DutyMode.flatRate),
                      decoration: InputDecoration(
                        labelText: 'Customs Duty Mode',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_dutyMode == DutyMode.flatRate) ...[
                    Expanded(
                      child: DropdownButtonFormField<FlatRateBasis>(
                        value: _flatBasis,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        items: FlatRateBasis.values
                            .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _flatBasis = v ?? FlatRateBasis.perKgGross),
                        decoration: InputDecoration(
                          labelText: 'Flat Rate Basis',
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inputField('Rate in PKR', _flatRateAmountCtrl, hint: 'e.g. 220'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // 6. Assembly Toggle & Costs
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF223154)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SKD / CKD Local Value-Add Assembly',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _assemblyEnabled,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _assemblyEnabled = val),
                        ),
                      ],
                    ),
                    if (_assemblyEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _inputField('Local Box (PKR)', _boxCostCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _inputField('Labor (PKR)', _laborCostCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _inputField('Local Parts (PKR)', _partsCostCtrl)),
                          const SizedBox(width: 8),
                          Expanded(child: _inputField('Defect %', _defectPctCtrl)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. Pricing & Reverse Pricing
              Row(
                children: [
                  Expanded(
                    child: _inputField('Target Markup %', _markupPctCtrl, hint: 'e.g. 25%'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField('Competitor Market Price (PKR)', _competitorPriceCtrl, hint: 'Reverse calculates profit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 8. 3D Box Color Palette
              Row(
                children: [
                  const Text('3D Box Color:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: _palette.map((c) {
                      final isSelected = _boxColor == c;
                      return InkWell(
                        onTap: () => setState(() => _boxColor = c),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 9. Product Thumbnail Media (< 15 KB WebP/JPEG Compression)
              Row(
                children: [
                  const Text('Thumbnail Photo:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(width: 14),
                  if (_photoUrl != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF38BDF8)),
                        image: DecorationImage(
                          image: NetworkImage(_photoUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 28),
                    ),
                    icon: _isUploadingPhoto
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                        : const Icon(Icons.add_a_photo_outlined, size: 14),
                    label: Text(
                      _photoUrl != null ? 'Replace Photo (<15KB)' : 'Upload Photo (<15KB WebP)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
          onPressed: _save,
          child: const Text('Save Product Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    String? hint,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        errorStyle: const TextStyle(color: Color(0xFFF87171), fontSize: 11),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

