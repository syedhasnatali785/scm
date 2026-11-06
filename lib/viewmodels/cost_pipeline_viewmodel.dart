import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/cost_node.dart';
import '../../engine/calculation_engine.dart';

@immutable
class CostPipelineState {
  final List<CostNode> nodes;
  final ApportionmentMode apportionmentMode;

  const CostPipelineState({
    this.nodes = const [],
    this.apportionmentMode = ApportionmentMode.targetCapacity,
  });

  CostPipelineState copyWith({
    List<CostNode>? nodes,
    ApportionmentMode? apportionmentMode,
  }) {
    return CostPipelineState(
      nodes: nodes ?? this.nodes,
      apportionmentMode: apportionmentMode ?? this.apportionmentMode,
    );
  }
}

class CostPipelineViewModel extends StateNotifier<CostPipelineState> {
  CostPipelineViewModel()
    : super(
        CostPipelineState(
          nodes: CostNode.defaultPipeline(),
          apportionmentMode: ApportionmentMode.targetCapacity,
        ),
      );

  void addNode(CostNode node) {
    state = state.copyWith(nodes: [...state.nodes, node]);
  }

  void updateNode(CostNode updated) {
    state = state.copyWith(
      nodes: [
        for (final n in state.nodes)
          if (n.id == updated.id) updated else n,
      ],
    );
  }

  void removeNode(String id) {
    state = state.copyWith(
      nodes: state.nodes.where((n) => n.id != id).toList(),
    );
  }

  void toggleNodeActive(String id) {
    state = state.copyWith(
      nodes: [
        for (final n in state.nodes)
          if (n.id == id) n.copyWith(isActive: !n.isActive) else n,
      ],
    );
  }

  void setApportionmentMode(ApportionmentMode mode) {
    state = state.copyWith(apportionmentMode: mode);
  }
}

final costPipelineViewModelProvider =
    StateNotifierProvider<CostPipelineViewModel, CostPipelineState>((ref) {
      return CostPipelineViewModel();
    });
