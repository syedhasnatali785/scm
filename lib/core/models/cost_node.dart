import 'package:flutter/foundation.dart';

enum CostStage {
  origin('Origin Charges', '🇨🇳'),
  freight('International Freight', '🚢'),
  clearance('Port & Customs Clearance', '🛃'),
  localDelivery('Local Inland Haulage', '🚚');

  final String label;
  final String icon;
  const CostStage(this.label, this.icon);
}

enum ApportionmentRule {
  byCbm('By Volume (CBM)', 'm³'),
  byGrossWeight('By Weight (GW)', 'kg'),
  byInvoiceValue('By Purchase Value', 'val'),
  byCartonCount('Equally per Carton', 'ctn');

  final String label;
  final String badge;
  const ApportionmentRule(this.label, this.badge);
}

@immutable
class CostNode {
  final String id;
  final CostStage stage;
  final String name;
  final double amount;
  final String currencyCode;
  final ApportionmentRule allocationRule;
  final bool isActive;

  const CostNode({
    required this.id,
    required this.stage,
    required this.name,
    required this.amount,
    required this.currencyCode,
    this.allocationRule = ApportionmentRule.byCbm,
    this.isActive = true,
  });

  CostNode copyWith({
    String? id,
    CostStage? stage,
    String? name,
    double? amount,
    String? currencyCode,
    ApportionmentRule? allocationRule,
    bool? isActive,
  }) {
    return CostNode(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      allocationRule: allocationRule ?? this.allocationRule,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage': stage.name,
      'name': name,
      'amount': amount,
      'currency_code': currencyCode,
      'allocation_rule': allocationRule.name,
      'is_active': isActive,
    };
  }

  factory CostNode.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const CostNode(
        id: 'node_default',
        stage: CostStage.origin,
        name: 'Default Node',
        amount: 0.0,
        currencyCode: 'PKR',
      );
    }
    CostStage s = CostStage.origin;
    for (final v in CostStage.values) {
      if (v.name == map['stage']) {
        s = v;
        break;
      }
    }
    ApportionmentRule r = ApportionmentRule.byCbm;
    for (final v in ApportionmentRule.values) {
      if (v.name == map['allocation_rule']) {
        r = v;
        break;
      }
    }
    return CostNode(
      id: map['id'] as String? ?? 'node_${DateTime.now().millisecondsSinceEpoch}',
      stage: s,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currencyCode: map['currency_code'] as String? ?? 'PKR',
      allocationRule: r,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  static List<CostNode> defaultPipeline() {
    return const [
      CostNode(
        id: 'node_origin_trucking',
        stage: CostStage.origin,
        name: 'China Factory to Port Trucking',
        amount: 2500.0,
        currencyCode: 'RMB',
        allocationRule: ApportionmentRule.byCbm,
      ),
      CostNode(
        id: 'node_origin_commission',
        stage: CostStage.origin,
        name: 'Sourcing Agent Commission',
        amount: 3000.0,
        currencyCode: 'RMB',
        allocationRule: ApportionmentRule.byInvoiceValue,
      ),
      CostNode(
        id: 'node_ocean_freight',
        stage: CostStage.freight,
        name: '40HC Ocean Container Freight',
        amount: 3200.0,
        currencyCode: 'USD',
        allocationRule: ApportionmentRule.byCbm,
      ),
      CostNode(
        id: 'node_marine_insurance',
        stage: CostStage.freight,
        name: 'Marine Cargo Insurance',
        amount: 250.0,
        currencyCode: 'USD',
        allocationRule: ApportionmentRule.byInvoiceValue,
      ),
      CostNode(
        id: 'node_port_do_charges',
        stage: CostStage.clearance,
        name: 'Port Delivery Order (DO) & Handling',
        amount: 185000.0,
        currencyCode: 'PKR',
        allocationRule: ApportionmentRule.byCbm,
      ),
      CostNode(
        id: 'node_clearing_agent',
        stage: CostStage.clearance,
        name: 'Customs Clearing Agent Service Fee',
        amount: 75000.0,
        currencyCode: 'PKR',
        allocationRule: ApportionmentRule.byCartonCount,
      ),
      CostNode(
        id: 'node_port_to_warehouse',
        stage: CostStage.localDelivery,
        name: 'Port-to-City 22-Wheeler Trailer',
        amount: 240000.0,
        currencyCode: 'PKR',
        allocationRule: ApportionmentRule.byGrossWeight,
      ),
      CostNode(
        id: 'node_offloading_labor',
        stage: CostStage.localDelivery,
        name: 'Warehouse Offloading & Stacking Labor',
        amount: 35000.0,
        currencyCode: 'PKR',
        allocationRule: ApportionmentRule.byCartonCount,
      ),
    ];
  }
}

