import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/container_spec.dart';
import '../../../state/shipment_state.dart';

class ContainerSpecDialog extends ConsumerStatefulWidget {
  const ContainerSpecDialog({super.key});

  @override
  ConsumerState<ContainerSpecDialog> createState() =>
      _ContainerSpecDialogState();
}

class _ContainerSpecDialogState extends ConsumerState<ContainerSpecDialog> {
  late ContainerSpec _current;
  late TextEditingController _lengthCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _doorWidthCtrl;
  late TextEditingController _doorHeightCtrl;
  late TextEditingController _payloadCtrl;
  late TextEditingController _roadAxleCtrl;
  late TextEditingController _usablePctCtrl;

  @override
  void initState() {
    super.initState();
    _current = ref.read(containerSpecProvider);
    _initControllers();
  }

  void _initControllers() {
    _lengthCtrl = TextEditingController(
      text: _current.lengthCm.toStringAsFixed(1),
    );
    _widthCtrl = TextEditingController(
      text: _current.widthCm.toStringAsFixed(1),
    );
    _heightCtrl = TextEditingController(
      text: _current.heightCm.toStringAsFixed(1),
    );
    _doorWidthCtrl = TextEditingController(
      text: _current.doorWidthCm.toStringAsFixed(1),
    );
    _doorHeightCtrl = TextEditingController(
      text: _current.doorHeightCm.toStringAsFixed(1),
    );
    _payloadCtrl = TextEditingController(
      text: _current.maxGrossPayloadKg.toStringAsFixed(0),
    );
    _roadAxleCtrl = TextEditingController(
      text: _current.roadAxleLimitKg.toStringAsFixed(0),
    );
    _usablePctCtrl = TextEditingController(
      text: _current.usableVolumePct.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _doorWidthCtrl.dispose();
    _doorHeightCtrl.dispose();
    _payloadCtrl.dispose();
    _roadAxleCtrl.dispose();
    _usablePctCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(ContainerPreset preset) {
    setState(() {
      _current = ContainerSpec.fromPreset(preset);
      _lengthCtrl.text = _current.lengthCm.toStringAsFixed(1);
      _widthCtrl.text = _current.widthCm.toStringAsFixed(1);
      _heightCtrl.text = _current.heightCm.toStringAsFixed(1);
      _doorWidthCtrl.text = _current.doorWidthCm.toStringAsFixed(1);
      _doorHeightCtrl.text = _current.doorHeightCm.toStringAsFixed(1);
      _payloadCtrl.text = _current.maxGrossPayloadKg.toStringAsFixed(0);
      _roadAxleCtrl.text = _current.roadAxleLimitKg.toStringAsFixed(0);
      _usablePctCtrl.text = _current.usableVolumePct.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 22),
          SizedBox(width: 10),
          Text(
            'Container Geometry & Equipment Setup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUICK PRESETS:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ContainerPreset.values.map((preset) {
                  final isSelected = _current.preset == preset;
                  return ChoiceChip(
                    label: Text(preset.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) _applyPreset(preset);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 14),

              const Text(
                'PARAMETRIC DIMENSIONS (CM) & PAYLOAD:',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _field('Length (cm)', _lengthCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Width (cm)', _widthCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Height (cm)', _heightCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Door Width (cm)', _doorWidthCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Door Height (cm)', _doorHeightCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('Max Gross Payload (kg)', _payloadCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Road Axle Limit (kg)', _roadAxleCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Usable Volume %', _usablePctCtrl)),
                ],
              ),

              const SizedBox(height: 18),
              // Live Computed Volume Callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Nominal Gross: ${_current.grossCbm.toStringAsFixed(1)} CBM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Usable Target: ${_current.usableCbm.toStringAsFixed(1)} CBM',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
          ),
          onPressed: () {
            ref
                .read(containerSpecProvider.notifier)
                .updateDimensions(
                  lengthCm:
                      double.tryParse(_lengthCtrl.text) ?? _current.lengthCm,
                  widthCm: double.tryParse(_widthCtrl.text) ?? _current.widthCm,
                  heightCm:
                      double.tryParse(_heightCtrl.text) ?? _current.heightCm,
                  doorWidthCm:
                      double.tryParse(_doorWidthCtrl.text) ??
                      _current.doorWidthCm,
                  doorHeightCm:
                      double.tryParse(_doorHeightCtrl.text) ??
                      _current.doorHeightCm,
                  maxPayloadKg:
                      double.tryParse(_payloadCtrl.text) ??
                      _current.maxGrossPayloadKg,
                  roadAxleLimitKg:
                      double.tryParse(_roadAxleCtrl.text) ??
                      _current.roadAxleLimitKg,
                  usableVolumePct:
                      double.tryParse(_usablePctCtrl.text) ??
                      _current.usableVolumePct,
                );
            Navigator.pop(context);
          },
          child: const Text(
            'Save Container Spec',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) {
        setState(() {
          _current = _current.copyWith(
            lengthCm: double.tryParse(_lengthCtrl.text) ?? _current.lengthCm,
            widthCm: double.tryParse(_widthCtrl.text) ?? _current.widthCm,
            heightCm: double.tryParse(_heightCtrl.text) ?? _current.heightCm,
            doorWidthCm:
                double.tryParse(_doorWidthCtrl.text) ?? _current.doorWidthCm,
            doorHeightCm:
                double.tryParse(_doorHeightCtrl.text) ?? _current.doorHeightCm,
            maxGrossPayloadKg:
                double.tryParse(_payloadCtrl.text) ??
                _current.maxGrossPayloadKg,
            roadAxleLimitKg:
                double.tryParse(_roadAxleCtrl.text) ??
                _current.roadAxleLimitKg,
            usableVolumePct:
                double.tryParse(_usablePctCtrl.text) ??
                _current.usableVolumePct,
          );
        });
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
