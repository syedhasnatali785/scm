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

              if (items.isNotEmpty) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(40, 30),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                  label: const Text('Erase All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                        ),
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Erase All Container Products?',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: const SizedBox(
                          width: 380,
                          child: Text(
                            'Are you sure you want to erase all products in this active shipment? This will wipe the loaded packing items so you can start a clean import. This action cannot be undone.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.delete_forever_rounded, size: 16),
                            label: const Text('Erase All Data', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              ref.read(productItemsProvider.notifier).clearAll();
                              ref.read(shipmentViewModelProvider.notifier).clearAllItems();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],

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
