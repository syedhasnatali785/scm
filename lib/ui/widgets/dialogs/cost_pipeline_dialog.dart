import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/cost_node.dart';
import '../../../state/shipment_state.dart';

class CostPipelineDialog extends ConsumerStatefulWidget {
  const CostPipelineDialog({super.key});

  @override
  ConsumerState<CostPipelineDialog> createState() => _CostPipelineDialogState();
}

class _CostPipelineDialogState extends ConsumerState<CostPipelineDialog> {
  CostStage _selectedStageTab = CostStage.freight;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(costNodesProvider);
    final filteredNodes = nodes.where((n) => n.stage == _selectedStageTab).toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.account_tree_outlined, color: Color(0xFF38BDF8), size: 22),
              SizedBox(width: 10),
              Text(
                'Modular Cost Pipeline Builder',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add Cost Node', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _showAddNodeDialog(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 500,
        child: Column(
          children: [
            // Stage Selection Tabs
            Row(
              children: [
                for (final stage in CostStage.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _selectedStageTab = stage),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedStageTab == stage
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedStageTab == stage
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(stage.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                stage.label,
                                style: TextStyle(
                                  color: _selectedStageTab == stage ? Colors.white : const Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Cost Nodes List for the selected stage
            Expanded(
              child: filteredNodes.isEmpty
                  ? Center(
                      child: Text(
                        'No cost nodes in ${_selectedStageTab.label}. Click "+ Add Cost Node" to add one.',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredNodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final node = filteredNodes[index];
                        return _nodeTile(context, node);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done', style: TextStyle(color: Color(0xFF38BDF8))),
        ),
      ],
    );
  }

  Widget _nodeTile(BuildContext context, CostNode node) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: node.isActive ? const Color(0xFF223154) : const Color(0xFF334155).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: node.isActive,
            activeColor: const Color(0xFF0284C7),
            onChanged: (_) => ref.read(costNodesProvider.notifier).toggleNodeActive(node.id),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: TextStyle(
                    color: node.isActive ? Colors.white : const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: node.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.allocationRule.label,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apportioned per shipment',
                      style: TextStyle(color: const Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${node.currencyCode} ${node.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: node.isActive ? const Color(0xFF34D399) : const Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF38BDF8)),
            tooltip: 'Edit Node',
            onPressed: () => _showEditNodeDialog(context, node),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            tooltip: 'Delete Node',
            onPressed: () => ref.read(costNodesProvider.notifier).removeNode(node.id),
          ),
        ],
      ),
    );
  }

  void _showEditNodeDialog(BuildContext context, CostNode node) {
    final nameCtrl = TextEditingController(text: node.name);
    final amountCtrl = TextEditingController(text: node.amount.toString());
    String currency = node.currencyCode;
    ApportionmentRule rule = node.allocationRule;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Edit Logistics Cost Node', style: TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cost Node Name',
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
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          items: ['PKR', 'RMB', 'USD', 'AED', 'EUR']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => currency = v ?? 'PKR'),
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
                    onChanged: (v) => setDialogState(() => rule = v ?? ApportionmentRule.byCbm),
                    decoration: const InputDecoration(labelText: 'Apportionment Method'),
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
                      ref.read(costNodesProvider.notifier).updateNode(node.copyWith(
                        name: name,
                        amount: amt,
                        currencyCode: currency,
                        allocationRule: rule,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddNodeDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String currency = 'PKR';
    ApportionmentRule rule = ApportionmentRule.byCbm;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('New Logistics Cost Node', style: TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cost Node Name (e.g. Fumigation Certificate)',
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
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          items: ['PKR', 'RMB', 'USD', 'AED', 'EUR']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => currency = v ?? 'PKR'),
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
                    onChanged: (v) => setDialogState(() => rule = v ?? ApportionmentRule.byCbm),
                    decoration: const InputDecoration(labelText: 'Apportionment Method'),
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
                      ref.read(costNodesProvider.notifier).addNode(CostNode(
                        id: const Uuid().v4(),
                        stage: _selectedStageTab,
                        name: name,
                        amount: amt,
                        currencyCode: currency,
                        allocationRule: rule,
                      ));
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

