import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cost_node.dart';
import '../../core/utils/formatters.dart';
import '../../state/shipment_state.dart';
import '../widgets/control_rail/collapsible_cost_pipeline_cards.dart';
import '../widgets/dialogs/cost_pipeline_dialog.dart';

class CostPipelineView extends ConsumerWidget {
  const CostPipelineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(calculatedTotalsProvider);
    final costNodes = ref.watch(costNodesProvider);

    final originNodes = costNodes.where((n) => n.stage == CostStage.origin && n.isActive).length;
    final freightNodes = costNodes.where((n) => n.stage == CostStage.freight && n.isActive).length;
    final clearanceNodes = costNodes.where((n) => n.stage == CostStage.clearance && n.isActive).length;
    final haulageNodes = costNodes.where((n) => n.stage == CostStage.localDelivery && n.isActive).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MULTI-STAGE LOGISTICS & TARIFF PIPELINE',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Pipeline Logistics: ${Formatters.pkr(totals.totalLogisticsCostBase)} across 4 operational transport phases.',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Custom Cost Node', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CostPipelineDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview Stage Summary Row
          Row(
            children: [
              Expanded(
                child: _stageSummaryTile(
                  icon: '🇨🇳',
                  title: '1. Origin Logistics',
                  activeNodes: originNodes,
                  color: const Color(0xFF38BDF8),
                  rule: 'Ex-Works / FOB Port Handing',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _stageSummaryTile(
                  icon: '🚢',
                  title: '2. International Freight',
                  activeNodes: freightNodes,
                  color: const Color(0xFF6366F1),
                  rule: 'Ocean / Air Line Container Freight',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _stageSummaryTile(
                  icon: '🛃',
                  title: '3. Port & Customs',
                  activeNodes: clearanceNodes,
                  color: const Color(0xFFF59E0B),
                  rule: 'Terminal Handling, WeBOC, Wharfage',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _stageSummaryTile(
                  icon: '🚚',
                  title: '4. Inland Haulage',
                  activeNodes: haulageNodes,
                  color: const Color(0xFFEC4899),
                  rule: 'Port to Warehouse Ground Transport',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Collapsible Cost Pipeline Cards (The full horizontal interactive cards)
          const CollapsibleCostPipelineCards(),
        ],
      ),
    );
  }

  Widget _stageSummaryTile({
    required String icon,
    required String title,
    required int activeNodes,
    required Color color,
    required String rule,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeNodes Active Node${activeNodes == 1 ? '' : 's'}',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(rule, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        ],
      ),
    );
  }
}

