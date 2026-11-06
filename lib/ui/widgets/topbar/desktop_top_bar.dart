import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../engine/calculation_engine.dart';
import '../../../state/navigation_state.dart';
import '../../../state/shipment_state.dart';

class DesktopTopBar extends ConsumerWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onPasteQuote;
  final VoidCallback onExport;

  const DesktopTopBar({
    super.key,
    required this.onAddProduct,
    required this.onPasteQuote,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeNavigationTabProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final apportionmentMode = ref.watch(apportionmentModeProvider);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 1. Current Workspace Title & Subtitle
          Icon(activeTab.icon, size: 20, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeTab.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activeTab.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // 2. Real-time Status Badges (Doorway collision, Axle weight, Dead freight)
          if (totals.doorwayCollisionsCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFF87171)),
                  const SizedBox(width: 5),
                  Text(
                    '${totals.doorwayCollisionsCount} Doorway Alerts',
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          if (totals.isOverweightAxle)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Text(
                'Axle Limit Exceeded (+${Formatters.number(totals.excessAxleWeightKg.round())} kg)',
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),

          if (totals.deadFreightCost > 0)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                'Dead Freight: ${Formatters.pkr(totals.deadFreightCost)}',
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),

          // 3. Apportionment Mode Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ApportionmentMode>(
                value: apportionmentMode,
                dropdownColor: const Color(0xFF1E293B),
                isDense: true,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8), size: 16),
                items: const [
                  DropdownMenuItem(
                    value: ApportionmentMode.targetCapacity,
                    child: Text('Cost Rule: Target Usable Capacity'),
                  ),
                  DropdownMenuItem(
                    value: ApportionmentMode.actualLoad,
                    child: Text('Cost Rule: Actual Packed Load'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(apportionmentModeProvider.notifier).state = mode;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3b. Supabase Real-Time Cloud Status Badge
          Consumer(
            builder: (context, ref, _) {
              final shipmentState = ref.watch(shipmentViewModelProvider);
              final status = shipmentState.syncStatus;
              Color color;
              IconData icon;
              String label;

              switch (status) {
                case SyncStatus.synced:
                  color = const Color(0xFF10B981);
                  icon = Icons.cloud_done_rounded;
                  label = 'Supabase Synced';
                  break;
                case SyncStatus.syncing:
                  color = const Color(0xFF38BDF8);
                  icon = Icons.cloud_sync_rounded;
                  label = 'Syncing...';
                  break;
                case SyncStatus.offline:
                  color = const Color(0xFFF59E0B);
                  icon = Icons.cloud_off_rounded;
                  label = 'Local Cache';
                  break;
                case SyncStatus.error:
                  color = const Color(0xFFEF4444);
                  icon = Icons.error_outline_rounded;
                  label = 'Sync Error';
                  break;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // 4. Quick Action CTA Buttons
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF0284C7)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(40, 32),
            ),
            icon: const Icon(Icons.content_paste_rounded, size: 13),
            label: const Text('Import Quote', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: onPasteQuote,
          ),
          const SizedBox(width: 8),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF059669)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(40, 32),
            ),
            icon: const Icon(Icons.download_rounded, size: 13),
            label: const Text('Export Reports', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: onExport,
          ),
          const SizedBox(width: 8),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(40, 32),
              elevation: 0,
            ),
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text('+ Add Item', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: onAddProduct,
          ),
        ],
      ),
    );
  }
}
