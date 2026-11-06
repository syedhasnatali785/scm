import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/currency.dart';
import '../../../engine/calculation_engine.dart';
import '../../../state/shipment_state.dart';

class ControlRail extends ConsumerWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onPasteQuote;
  final VoidCallback onOpenCostPipeline;
  final VoidCallback onEditContainer;
  final VoidCallback onExport;

  const ControlRail({
    super.key,
    required this.onAddProduct,
    required this.onPasteQuote,
    required this.onOpenCostPipeline,
    required this.onEditContainer,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final container = ref.watch(containerSpecProvider);
    final rates = ref.watch(currencyRatesProvider);
    final apportionmentMode = ref.watch(apportionmentModeProvider);
    final activeCostNodes = ref.watch(costNodesProvider).where((n) => n.isActive).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Left Group: FX Currency Bar & Apportionment Switch
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // FX Currencies
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_exchange_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  const Text('Live FX:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  for (final code in ['RMB', 'USD'])
                    if (rates.containsKey(code))
                      _fxChip(context, ref, rates[code]!),
                ],
              ),

              Container(height: 24, width: 1, color: const Color(0xFF334155)),

              // Apportionment Mode Selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeTab(
                      label: 'Target Mode (68 CBM)',
                      isSelected: apportionmentMode == ApportionmentMode.targetCapacity,
                      onTap: () => ref.read(apportionmentModeProvider.notifier).state = ApportionmentMode.targetCapacity,
                    ),
                    _modeTab(
                      label: 'Actual Load Mode',
                      isSelected: apportionmentMode == ApportionmentMode.actualLoad,
                      onTap: () => ref.read(apportionmentModeProvider.notifier).state = ApportionmentMode.actualLoad,
                    ),
                  ],
                ),
              ),

              // Container Preset Pill
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onEditContainer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar, size: 15, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        '${container.name} (${container.usableCbm.toStringAsFixed(1)} CBM)',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),

              // Cost Pipeline Trigger
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onOpenCostPipeline,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_tree_outlined, size: 15, color: Color(0xFF818CF8)),
                      const SizedBox(width: 6),
                      Text(
                        'Cost Pipeline ($activeCostNodes Active)',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Right Group: Action Buttons (+ Add Product, Paste Quote, Export)
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.content_paste_go_rounded, size: 16),
                label: const Text('Paste Factory Quote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: onPasteQuote,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCBD5E1),
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Export Reports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: onExport,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: onAddProduct,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _fxChip(BuildContext context, WidgetRef ref, CurrencyRate rate) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showFxEditDialog(context, ref, rate),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rate.isLocked ? const Color(0xFFF59E0B) : const Color(0xFF334155),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '1 ${rate.code} = ₨ ${rate.rateToBase.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            if (rate.safetyBufferPct > 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '(+${rate.safetyBufferPct}%)',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 10),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              rate.isLocked ? Icons.lock : Icons.edit_outlined,
              size: 12,
              color: rate.isLocked ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showFxEditDialog(BuildContext context, WidgetRef ref, CurrencyRate rate) {
    final rateController = TextEditingController(text: rate.rateToBase.toString());
    final bufferController = TextEditingController(text: rate.safetyBufferPct.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Configure FX Rate: ${rate.code} / PKR',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Base Rate (1 ${rate.code} in PKR)',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixText: '₨ ',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bufferController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Safety Volatility Buffer %',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  suffixText: '%',
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: rate.isLocked,
                    onChanged: (val) {
                      ref.read(currencyRatesProvider.notifier).toggleLock(rate.code);
                      Navigator.pop(ctx);
                    },
                    activeColor: const Color(0xFF0284C7),
                  ),
                  const Text('Lock Rate for Shipment', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () {
                final r = double.tryParse(rateController.text) ?? rate.rateToBase;
                final b = double.tryParse(bufferController.text) ?? rate.safetyBufferPct;
                ref.read(currencyRatesProvider.notifier).updateRate(rate.code, r);
                ref.read(currencyRatesProvider.notifier).updateBuffer(rate.code, b);
                Navigator.pop(ctx);
              },
              child: const Text('Save Rate', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
