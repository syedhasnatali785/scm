import 'package:flutter/material.dart';
import '../../core/models/product_item.dart';

@immutable
class PackedBox {
  final String itemId;
  final String itemName;
  final String sku;
  final int cartonIndex;
  
  // Coordinates in cm within the container coordinate frame:
  // X: along length (0 to containerLengthCm)
  // Y: along width (0 to containerWidthCm)
  // Z: along height (0 to containerHeightCm)
  final double x;
  final double y;
  final double z;
  final double dx; // length
  final double dy; // width
  final double dz; // height

  final Color color;
  final double weightKg;
  final int layer;
  final StackingTier stackingTier;

  const PackedBox({
    required this.itemId,
    required this.itemName,
    required this.sku,
    required this.cartonIndex,
    required this.x,
    required this.y,
    required this.z,
    required this.dx,
    required this.dy,
    required this.dz,
    required this.color,
    required this.weightKg,
    required this.layer,
    this.stackingTier = StackingTier.mediumMiddle,
  });

  double get volumeCbm => (dx * dy * dz) / 1000000.0;
}

@immutable
class PackingResult {
  final List<PackedBox> boxes;
  final int totalRequestedCartons;
  final int totalPackedCartons;
  final double packedCbm;
  final double voidWasteCbm; // Stacking void waste (unused gaps inside bounding envelope)
  final double freeCbm;      // Completely unallocated container space
  final double usableCbm;
  final double containerLengthCm;
  final double containerWidthCm;
  final double containerHeightCm;
  final double packingDensityPct;
  final Duration computeTime;

  const PackingResult({
    required this.boxes,
    required this.totalRequestedCartons,
    required this.totalPackedCartons,
    required this.packedCbm,
    this.voidWasteCbm = 0.0,
    this.freeCbm = 0.0,
    this.usableCbm = 0.0,
    required this.containerLengthCm,
    required this.containerWidthCm,
    required this.containerHeightCm,
    required this.packingDensityPct,
    required this.computeTime,
  });

  // 3-Segment Capacity Breakdown Percentages
  double get occupiedPct => usableCbm > 0 ? (packedCbm / usableCbm) * 100.0 : 0.0;
  double get voidWastePct => usableCbm > 0 ? (voidWasteCbm / usableCbm) * 100.0 : 0.0;
  double get freePct => usableCbm > 0 ? (freeCbm / usableCbm) * 100.0 : 0.0;

  static PackingResult empty(double l, double w, double h) {
    final gross = (l * w * h) / 1000000.0;
    return PackingResult(
      boxes: const [],
      totalRequestedCartons: 0,
      totalPackedCartons: 0,
      packedCbm: 0.0,
      voidWasteCbm: 0.0,
      freeCbm: gross,
      usableCbm: gross,
      containerLengthCm: l,
      containerWidthCm: w,
      containerHeightCm: h,
      packingDensityPct: 0.0,
      computeTime: Duration.zero,
    );
  }
}

