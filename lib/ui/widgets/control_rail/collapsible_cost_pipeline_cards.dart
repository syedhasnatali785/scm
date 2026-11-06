import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/cost_node.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/shipment_state.dart';

class CollapsibleCostPipelineCards extends ConsumerStatefulWidget {
  const CollapsibleCostPipelineCards({super.key});

  @override
  ConsumerState<CollapsibleCostPipelineCards> createState() => _CollapsibleCostPipelineCardsState();
}

class _CollapsibleCostPipelineCardsState extends ConsumerState<CollapsibleCostPipelineCards> {
  CostStage? _expandedStage;

  void _toggleStage(CostStage stage) {
    setState(() {
      _expandedStage = _expandedStage == stage ? null : stage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(costNodesProvider);
    final rates = ref.watch(currencyRatesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF38BDF8)),
                  SizedBox(width: 8),
                  Text(
                    'DYNAMIC LOGISTICS COST PIPELINE (4 STAGES)',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (_expandedStage != null)
                InkWell(
                  onTap: () => setState(() => _expandedStage = null),
                  child: const Text('Collapse Rail', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 4 Horizontal Pipeline Cards
          Row(
            children: CostStage.values.map((stage) {
              final stageNodes = nodes.where((n) => n.stage == stage).toList();
              final isExpanded = _expandedStage == stage;

              // Compute total in Base currency for this card
              double stageTotalBase = 0.0;
              for (final n in stageNodes.where((n) => n.isActive)) {
                final r = rates[n.currencyCode]?.effectiveRate ?? 1.0;
                stageTotalBase += n.amount * r;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _toggleStage(stage),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExpanded ? const Color(0xFF0284C7).withValues(alpha: 0.2) : const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isExpanded ? const Color(0xFF38BDF8) : const Color(0xFF223154),
                          width: isExpanded ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(stage.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    stage.label,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                size: 16,
                                color: const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${stageNodes.where((n) => n.isActive).length} Nodes',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                              Text(
                                Formatters.pkr(stageTotalBase),
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Expanded Drawer Area when a stage card is clicked
          if (_expandedStage != null) ...[
            const SizedBox(height: 12),
            _buildStageDetails(context, _expandedStage!, nodes.where((n) => n.stage == _expandedStage).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildStageDetails(BuildContext context, CostStage stage, List<CostNode> stageNodes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stage.icon} ${stage.label} — Active Cost Nodes:',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text('Add Cost', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showAddNodeModal(context, stage),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stageNodes.map((node) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: node.isActive ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: node.isActive,
                      activeColor: const Color(0xFF0284C7),
                      onChanged: (_) => ref.read(costNodesProvider.notifier).toggleNodeActive(node.id),
                    ),
                    Text(
                      '${node.name}: ',
                      style: TextStyle(
                        color: node.isActive ? Colors.white : const Color(0xFF64748B),
                        fontSize: 12,
                        decoration: node.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${node.currencyCode} ${node.amount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.allocationRule.badge,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => ref.read(costNodesProvider.notifier).removeNode(node.id),
                      child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showAddNodeModal(BuildContext context, CostStage stage) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String currency = stage == CostStage.origin ? 'RMB' : (stage == CostStage.freight ? 'USD' : 'PKR');
    ApportionmentRule rule = ApportionmentRule.byCbm;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Add Cost to ${stage.label}', style: const TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Cost Name (e.g. Detention Deposit)',
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currency,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          items: ['RMB', 'USD', 'PKR', 'AED', 'EUR']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setDState(() => currency = v ?? 'PKR'),
                          decoration: const InputDecoration(labelText: 'Currency'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ApportionmentRule>(
                    value: rule,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: ApportionmentRule.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setDState(() => rule = v ?? ApportionmentRule.byCbm),
                    decoration: const InputDecoration(labelText: 'Apportionment Rule'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (name.isNotEmpty && amt > 0) {
                      ref.read(costNodesProvider.notifier).addNode(
                        CostNode(
                          id: const Uuid().v4(),
                          stage: stage,
                          name: name,
                          amount: amt,
                          currencyCode: currency,
                          allocationRule: rule,
                        ),
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add Node', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

