import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/report_generator.dart';
import '../../core/utils/formatters.dart';
import '../../state/shipment_state.dart';
import '../widgets/audit_grid/parametric_audit_grid.dart';
import '../widgets/dialogs/product_edit_dialog.dart';

class AuditGridView extends ConsumerWidget {
  const AuditGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productItemsProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final container = ref.watch(containerSpecProvider);

    return Column(
      children: [
        // Sub-toolbar for Audit Grid
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0B132B),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              // Statistics Chips
              _statBadge(
                label: 'Total Items',
                value: '${items.length} SKUs',
                color: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 8),
              _statBadge(
                label: 'Total Cartons',
                value: '${totals.totalCartons} ctns',
                color: const Color(0xFF818CF8),
              ),
              const SizedBox(width: 8),
              _statBadge(
                label: 'Volume Used',
                value: '${totals.totalCbm.toStringAsFixed(1)} m³',
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 8),
              _statBadge(
                label: 'Gross Weight',
                value: '${Formatters.number(totals.totalGrossWeightKg.round())} kg',
                color: const Color(0xFFFBBF24),
              ),

              const Spacer(),

              // Quick Actions
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF059669)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(40, 30),
                ),
                icon: const Icon(Icons.table_view_rounded, size: 14),
                label: const Text('Export Grid to Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ReportGenerator.exportOwnerFinancialAuditExcel(
                    items: items,
                    container: container,
                    totals: totals,
                    calculatedLines: {
                      for (final item in items)
                        item.id: ref.read(calculatedLineItemProvider(item.id)),
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(40, 30),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Add Row', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const ProductEditDialog(),
                  );
                },
              ),
            ],
          ),
        ),

        // Full Screen Parametric Grid
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: ParametricAuditGrid(),
          ),
        ),
      ],
    );
  }

  Widget _statBadge({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
