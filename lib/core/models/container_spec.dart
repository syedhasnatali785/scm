import 'package:flutter/foundation.dart';

/// Supported dimension units
enum DimensionUnit {
  cm('cm', 1.0),
  mm('mm', 0.1),
  m('m', 100.0),
  inch('in', 2.54);

  final String label;
  final double toCmMultiplier;
  const DimensionUnit(this.label, this.toCmMultiplier);

  double toCm(double value) => value * toCmMultiplier;
}

/// Standard Container Presets
enum ContainerPreset {
  twentyGP(
    name: '20GP Standard',
    lengthCm: 589.8,
    widthCm: 235.2,
    heightCm: 239.3,
    doorWidthCm: 234.0,
    doorHeightCm: 229.2, // 2,292 mm ISO standard
    maxPayloadKg: 28200.0,
    roadAxleLimitKg: 28000.0,
    nominalCbm: 33.2,
    defaultUsablePct: 88.0,
  ),
  fortyGP(
    name: '40GP Standard',
    lengthCm: 1203.2,
    widthCm: 235.2,
    heightCm: 239.3,
    doorWidthCm: 234.0,
    doorHeightCm: 229.2, // 2,292 mm ISO standard
    maxPayloadKg: 26600.0,
    roadAxleLimitKg: 26000.0,
    nominalCbm: 67.7,
    defaultUsablePct: 90.0,
  ),
  fortyHC(
    name: '40HC High Cube',
    lengthCm: 1203.2,
    widthCm: 235.2,
    heightCm: 269.8,
    doorWidthCm: 234.0,
    doorHeightCm: 259.7, // 2,597 mm ISO standard
    maxPayloadKg: 26500.0,
    roadAxleLimitKg: 26500.0,
    nominalCbm: 76.4,
    defaultUsablePct: 91.0,
  ),
  fortyFiveHC(
    name: '45HC High Cube',
    lengthCm: 1355.6,
    widthCm: 235.2,
    heightCm: 269.8,
    doorWidthCm: 234.0,
    doorHeightCm: 259.7, // 2,597 mm ISO standard
    maxPayloadKg: 27700.0,
    roadAxleLimitKg: 27500.0,
    nominalCbm: 86.0,
    defaultUsablePct: 91.0,
  ),
  customTruck(
    name: 'Custom Road Trailer',
    lengthCm: 1220.0,
    widthCm: 240.0,
    heightCm: 260.0,
    doorWidthCm: 240.0,
    doorHeightCm: 250.0,
    maxPayloadKg: 30000.0,
    roadAxleLimitKg: 29500.0,
    nominalCbm: 76.1,
    defaultUsablePct: 92.0,
  );

  final String name;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final double doorWidthCm;
  final double doorHeightCm;
  final double maxPayloadKg;
  final double roadAxleLimitKg;
  final double nominalCbm;
  final double defaultUsablePct;

  const ContainerPreset({
    required this.name,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.doorWidthCm,
    required this.doorHeightCm,
    required this.maxPayloadKg,
    required this.roadAxleLimitKg,
    required this.nominalCbm,
    required this.defaultUsablePct,
  });
}

/// Fully editable container specification
@immutable
class ContainerSpec {
  final String id;
  final String name;
  final ContainerPreset preset;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final double doorWidthCm;
  final double doorHeightCm;
  final double maxGrossPayloadKg;
  final double roadAxleLimitKg;
  final double usableVolumePct;

  const ContainerSpec({
    required this.id,
    required this.name,
    required this.preset,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.doorWidthCm,
    required this.doorHeightCm,
    required this.maxGrossPayloadKg,
    this.roadAxleLimitKg = 26500.0,
    required this.usableVolumePct,
  });

  factory ContainerSpec.fromPreset(ContainerPreset preset) {
    return ContainerSpec(
      id: preset.name,
      name: preset.name,
      preset: preset,
      lengthCm: preset.lengthCm,
      widthCm: preset.widthCm,
      heightCm: preset.heightCm,
      doorWidthCm: preset.doorWidthCm,
      doorHeightCm: preset.doorHeightCm,
      maxGrossPayloadKg: preset.maxPayloadKg,
      roadAxleLimitKg: preset.roadAxleLimitKg,
      usableVolumePct: preset.defaultUsablePct,
    );
  }

  double get grossCbm => (lengthCm * widthCm * heightCm) / 1000000.0;
  double get usableCbm => grossCbm * (usableVolumePct / 100.0);

  ContainerSpec copyWith({
    String? id,
    String? name,
    ContainerPreset? preset,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? doorWidthCm,
    double? doorHeightCm,
    double? maxGrossPayloadKg,
    double? roadAxleLimitKg,
    double? usableVolumePct,
  }) {
    return ContainerSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      preset: preset ?? this.preset,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      doorWidthCm: doorWidthCm ?? this.doorWidthCm,
      doorHeightCm: doorHeightCm ?? this.doorHeightCm,
      maxGrossPayloadKg: maxGrossPayloadKg ?? this.maxGrossPayloadKg,
      roadAxleLimitKg: roadAxleLimitKg ?? this.roadAxleLimitKg,
      usableVolumePct: usableVolumePct ?? this.usableVolumePct,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'preset': preset.name,
      'length_cm': lengthCm,
      'width_cm': widthCm,
      'height_cm': heightCm,
      'door_width_cm': doorWidthCm,
      'door_height_cm': doorHeightCm,
      'max_gross_payload_kg': maxGrossPayloadKg,
      'road_axle_limit_kg': roadAxleLimitKg,
      'usable_volume_pct': usableVolumePct,
    };
  }

  factory ContainerSpec.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ContainerSpec.fromPreset(ContainerPreset.fortyHC);
    ContainerPreset p = ContainerPreset.fortyHC;
    for (final v in ContainerPreset.values) {
      if (v.name == map['preset']) {
        p = v;
        break;
      }
    }
    return ContainerSpec(
      id: map['id'] as String? ?? p.name,
      name: map['name'] as String? ?? p.name,
      preset: p,
      lengthCm: (map['length_cm'] as num?)?.toDouble() ?? p.lengthCm,
      widthCm: (map['width_cm'] as num?)?.toDouble() ?? p.widthCm,
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? p.heightCm,
      doorWidthCm: (map['door_width_cm'] as num?)?.toDouble() ?? p.doorWidthCm,
      doorHeightCm: (map['door_height_cm'] as num?)?.toDouble() ?? p.doorHeightCm,
      maxGrossPayloadKg: (map['max_gross_payload_kg'] as num?)?.toDouble() ?? p.maxPayloadKg,
      roadAxleLimitKg: (map['road_axle_limit_kg'] as num?)?.toDouble() ?? p.roadAxleLimitKg,
      usableVolumePct: (map['usable_volume_pct'] as num?)?.toDouble() ?? p.defaultUsablePct,
    );
  }
}
