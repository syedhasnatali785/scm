import 'package:flutter/foundation.dart';
import '../../engine/calculation_engine.dart';
import 'container_spec.dart';
import 'cost_node.dart';

@immutable
class Shipment {
  final String id;
  final String orgId;
  final String name;
  final String? referenceNo;
  final String status;
  final String containerPreset;
  final ContainerSpec? containerSpecs;
  final List<CostNode> costPipeline;
  final Map<String, dynamic> fxRates;
  final ApportionmentMode apportionmentMode;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shipment({
    required this.id,
    required this.orgId,
    required this.name,
    this.referenceNo,
    this.status = 'DRAFT',
    this.containerPreset = '40HC',
    this.containerSpecs,
    this.costPipeline = const [],
    this.fxRates = const {},
    this.apportionmentMode = ApportionmentMode.targetCapacity,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Shipment copyWith({
    String? id,
    String? orgId,
    String? name,
    String? referenceNo,
    String? status,
    String? containerPreset,
    ContainerSpec? containerSpecs,
    List<CostNode>? costPipeline,
    Map<String, dynamic>? fxRates,
    ApportionmentMode? apportionmentMode,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shipment(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      referenceNo: referenceNo ?? this.referenceNo,
      status: status ?? this.status,
      containerPreset: containerPreset ?? this.containerPreset,
      containerSpecs: containerSpecs ?? this.containerSpecs,
      costPipeline: costPipeline ?? this.costPipeline,
      fxRates: fxRates ?? this.fxRates,
      apportionmentMode: apportionmentMode ?? this.apportionmentMode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'org_id': orgId,
      'name': name,
      'reference_no': referenceNo,
      'status': status,
      'container_preset': containerPreset,
      'container_specs': containerSpecs?.toMap() ?? {},
      'cost_pipeline': costPipeline.map((n) => n.toMap()).toList(),
      'fx_rates': fxRates,
      'apportionment_mode': apportionmentMode.name,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory Shipment.fromMap(Map<String, dynamic> map) {
    ApportionmentMode mode = ApportionmentMode.targetCapacity;
    for (final m in ApportionmentMode.values) {
      if (m.name == map['apportionment_mode']) {
        mode = m;
        break;
      }
    }

    List<CostNode> nodes = [];
    if (map['cost_pipeline'] is List) {
      nodes = (map['cost_pipeline'] as List)
          .map((e) => CostNode.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    ContainerSpec? spec;
    if (map['container_specs'] is Map) {
      spec = ContainerSpec.fromMap(Map<String, dynamic>.from(map['container_specs'] as Map));
    }

    return Shipment(
      id: map['id']?.toString() ?? '',
      orgId: map['org_id']?.toString() ?? '',
      name: map['name'] as String? ?? 'Untitled Shipment',
      referenceNo: map['reference_no'] as String?,
      status: map['status'] as String? ?? 'DRAFT',
      containerPreset: map['container_preset'] as String? ?? '40HC',
      containerSpecs: spec,
      costPipeline: nodes,
      fxRates: map['fx_rates'] is Map ? Map<String, dynamic>.from(map['fx_rates'] as Map) : {},
      apportionmentMode: mode,
      createdBy: map['created_by']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}
