import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/calculation_results.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/shipment_state.dart';

class FillTheGapDialog extends ConsumerWidget {
  const FillTheGapDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(calculatedTotalsProvider);
    final recommendations = totals.topUpRecommendations;

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Container Optimization Advisor',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'Fill unused container volume to reduce unit landed cost',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container Remaining Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Remaining Free Volume', '${totals.remainingCbm.toStringAsFixed(2)} CBM', const Color(0xFF38BDF8)),
                  _statItem('Remaining Payload', '${Formatters.number(totals.remainingPayloadKg.round())} kg', const Color(0xFF34D399)),
                  _statItem('Dead Freight Cost', Formatters.pkr(totals.deadFreightCost), const Color(0xFFF87171)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RECOMMENDED TOP-UP CANDIDATES:',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            if (recommendations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Container is already optimally loaded (over 98% utilization)!',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: recommendations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final opt = recommendations[index];
                    return _recommendationTile(context, ref, opt);
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _recommendationTile(BuildContext context, WidgetRef ref, TopUpOption opt) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opt.itemName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '+${opt.additionalCartons} Cartons (+${opt.additionalPieces} Pcs) · Occupies ${opt.additionalCbm.toStringAsFixed(1)} CBM',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Saves ${Formatters.pkr(opt.perUnitSavings)} / pc',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  final items = ref.read(productItemsProvider);
                  final existing = items.firstWhere((i) => i.id == opt.itemId);
                  final updated = existing.copyWith(
                    orderedCartons: existing.orderedCartons + opt.additionalCartons,
                  );
                  ref.read(productItemsProvider.notifier).updateItem(updated);
                  Navigator.pop(context);
                },
                child: const Text('Apply Top-Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

