import 'package:flutter/foundation.dart';

@immutable
class Organization {
  final String id;
  final String name;
  final String slug;
  final String baseCurrency;
  final String defaultOriginCurrency;
  final String workflowPreset;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.baseCurrency = 'PKR',
    this.defaultOriginCurrency = 'RMB',
    this.workflowPreset = 'SKD Assembly',
    this.createdAt,
    this.updatedAt,
  });

  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    String? baseCurrency,
    String? defaultOriginCurrency,
    String? workflowPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      defaultOriginCurrency: defaultOriginCurrency ?? this.defaultOriginCurrency,
      workflowPreset: workflowPreset ?? this.workflowPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'base_currency': baseCurrency,
      'default_origin_currency': defaultOriginCurrency,
      'workflow_preset': workflowPreset,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id']?.toString() ?? '',
      name: map['name'] as String? ?? '71 International Trading',
      slug: map['slug'] as String? ?? '71-international',
      baseCurrency: map['base_currency'] as String? ?? 'PKR',
      defaultOriginCurrency: map['default_origin_currency'] as String? ?? 'RMB',
      workflowPreset: map['workflow_preset'] as String? ?? 'SKD Assembly',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}

