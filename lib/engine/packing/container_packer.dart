import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/models/container_spec.dart';
import '../../core/models/product_item.dart';
import 'packed_box.dart';

/// 3D Vector for Extreme Points in bin-packing
class _ExtremePoint {
  final double x;
  final double y;
  final double z;

  const _ExtremePoint(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ExtremePoint &&
          (x - other.x).abs() < 0.01 &&
          (y - other.y).abs() < 0.01 &&
          (z - other.z).abs() < 0.01;

  @override
  int get hashCode => Object.hash(x.round(), y.round(), z.round());
}

/// A tested orientation candidate (dx, dy, dz)
class _BoxOrientation {
  final double dx;
  final double dy;
  final double dz;
  const _BoxOrientation(this.dx, this.dy, this.dz);
}

class ContainerPacker {
  /// Solves 3D bin packing using a Layer-and-Shelf (Extreme-Point) heuristic
  /// with SKU grouping, stacking tier prioritization, and orientation constraints.
  static PackingResult pack({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) {
    final stopwatch = Stopwatch()..start();

    if (items.isEmpty) {
      return PackingResult.empty(
        container.lengthCm,
        container.widthCm,
        container.heightCm,
      );
    }

    final double contL = container.lengthCm;
    final double contW = container.widthCm;
    final double contH = container.heightCm;

    // 1. Group by SKU and sort by Stacking Tier (Floor -> Mid -> Fragile Top),
    // and within same tier by Gross Weight descending.
    final sortedItems = List<ProductItem>.from(items)..sort((a, b) {
      final tierComp = a.stackingTier.rank.compareTo(b.stackingTier.rank);
      if (tierComp != 0) return tierComp;
      return b.gwPerCartonKg.compareTo(a.gwPerCartonKg);
    });

    final packedBoxes = <PackedBox>[];
    int totalRequestedCartons = 0;
    double packedVolumeCbm = 0.0;

    // Extreme points list - start with container floor origin
    final extremePoints = <_ExtremePoint>[const _ExtremePoint(0, 0, 0)];

    double maxEnclosingX = 0.0;
    double maxEnclosingY = 0.0;
    double maxEnclosingZ = 0.0;

    for (final item in sortedItems) {
      totalRequestedCartons += item.orderedCartons;

      final double l = math.max(5.0, item.lengthInCm);
      final double w = math.max(5.0, item.widthInCm);
      final double h = math.max(5.0, item.heightInCm);

      // Determine allowed orientations based on constraint
      final allowedOrientations = _getAllowedOrientations(
        l,
        w,
        h,
        item.orientationConstraint,
      );

      int cartonIndex = 0;
      for (int c = 0; c < item.orderedCartons; c++) {
        _PlacementCandidate? bestCandidate;

        // Sort extreme points: lowest Z first (gravity/stacking), then lowest X (fill deep), then lowest Y
        extremePoints.sort((a, b) {
          final zComp = a.z.compareTo(b.z);
          if ((a.z - b.z).abs() > 0.01) return zComp;
          final xComp = a.x.compareTo(b.x);
          if ((a.x - b.x).abs() > 0.01) return xComp;
          return a.y.compareTo(b.y);
        });

        // Search for a valid extreme point
        for (final ep in extremePoints) {
          for (final orient in allowedOrientations) {
            final dx = orient.dx;
            final dy = orient.dy;
            final dz = orient.dz;

            // 1. Container Boundary Check
            if (ep.x + dx > contL || ep.y + dy > contW || ep.z + dz > contH) {
              continue;
            }

            // 2. Collision Check with already packed boxes
            bool collides = false;
            for (final b in packedBoxes) {
              if (_boxesIntersect(ep.x, ep.y, ep.z, dx, dy, dz, b.x, b.y, b.z, b.dx, b.dy, b.dz)) {
                collides = true;
                break;
              }
            }
            if (collides) continue;

            // 3. Fragility & Support Check:
            // If z > 0, box must have reasonable support underneath,
            // and we NEVER place a heavier/lower-tier box on top of a fragileTop box!
            if (ep.z > 0.01) {
              bool hasSupport = false;
              bool violatesFragility = false;

              for (final b in packedBoxes) {
                // Check if b is directly underneath
                if ((b.z + b.dz - ep.z).abs() < 0.5) {
                  // Check horizontal overlap
                  final xOverlap = math.max(0.0, math.min(ep.x + dx, b.x + b.dx) - math.max(ep.x, b.x));
                  final yOverlap = math.max(0.0, math.min(ep.y + dy, b.y + b.dy) - math.max(ep.y, b.y));

                  if (xOverlap > 0.1 && yOverlap > 0.1) {
                    hasSupport = true;
                    // Fragility violation check
                    if (b.stackingTier == StackingTier.fragileTop && item.stackingTier != StackingTier.fragileTop) {
                      violatesFragility = true;
                      break;
                    }
                  }
                }
              }

              if (violatesFragility || !hasSupport) continue;
            }

            // Valid placement found!
            bestCandidate = _PlacementCandidate(
              ep: ep,
              dx: dx,
              dy: dy,
              dz: dz,
            );
            break;
          }
          if (bestCandidate != null) break;
        }

        if (bestCandidate != null) {
          final ep = bestCandidate.ep;
          final dx = bestCandidate.dx;
          final dy = bestCandidate.dy;
          final dz = bestCandidate.dz;

          // Estimate layer based on z
          final layer = (ep.z / math.max(10.0, dz)).floor() + 1;

          packedBoxes.add(PackedBox(
            itemId: item.id,
            itemName: item.name,
            sku: item.modelNumber,
            cartonIndex: cartonIndex++,
            x: ep.x,
            y: ep.y,
            z: ep.z,
            dx: dx,
            dy: dy,
            dz: dz,
            color: item.boxColor,
            weightKg: item.gwPerCartonKg,
            layer: layer,
            stackingTier: item.stackingTier,
          ));

          packedVolumeCbm += (dx * dy * dz) / 1000000.0;

          // Update enclosing envelope
          maxEnclosingX = math.max(maxEnclosingX, ep.x + dx);
          maxEnclosingY = math.max(maxEnclosingY, ep.y + dy);
          maxEnclosingZ = math.max(maxEnclosingZ, ep.z + dz);

          // Update extreme points: remove used point, add 3 projection points
          extremePoints.remove(ep);

          final p1 = _ExtremePoint(ep.x + dx, ep.y, ep.z);
          final p2 = _ExtremePoint(ep.x, ep.y + dy, ep.z);
          final p3 = _ExtremePoint(ep.x, ep.y, ep.z + dz);

          if (p1.x < contL && !extremePoints.contains(p1)) extremePoints.add(p1);
          if (p2.y < contW && !extremePoints.contains(p2)) extremePoints.add(p2);
          if (p3.z < contH && !extremePoints.contains(p3)) extremePoints.add(p3);

          // Prune extreme points that are inside the newly added box
          extremePoints.removeWhere((p) =>
              p.x >= ep.x &&
              p.x < ep.x + dx &&
              p.y >= ep.y &&
              p.y < ep.y + dy &&
              p.z >= ep.z &&
              p.z < ep.z + dz);
        } else {
          // Cannot place any more cartons for this SKU
          break;
        }
      }
    }

    stopwatch.stop();

    final usableCbm = container.usableCbm;
    final enclosingEnvelopeCbm = (maxEnclosingX * maxEnclosingY * maxEnclosingZ) / 1000000.0;
    final voidWasteCbm = math.max(0.0, enclosingEnvelopeCbm - packedVolumeCbm);
    final freeCbm = math.max(0.0, usableCbm - packedVolumeCbm - voidWasteCbm);

    final density = usableCbm > 0
        ? (packedVolumeCbm / usableCbm) * 100.0
        : 0.0;

    return PackingResult(
      boxes: packedBoxes,
      totalRequestedCartons: totalRequestedCartons,
      totalPackedCartons: packedBoxes.length,
      packedCbm: packedVolumeCbm,
      voidWasteCbm: voidWasteCbm,
      freeCbm: freeCbm,
      usableCbm: usableCbm,
      containerLengthCm: contL,
      containerWidthCm: contW,
      containerHeightCm: contH,
      packingDensityPct: density,
      computeTime: stopwatch.elapsed,
    );
  }

  /// Async background worker isolate wrapper using Flutter compute
  static Future<PackingResult> packAsync({
    required List<ProductItem> items,
    required ContainerSpec container,
  }) {
    return compute(
      _isolatePackTask,
      _IsolatePackParams(items: items, container: container),
    );
  }

  static PackingResult _isolatePackTask(_IsolatePackParams params) {
    return pack(items: params.items, container: params.container);
  }

  static bool _boxesIntersect(
    double x1, double y1, double z1, double dx1, double dy1, double dz1,
    double x2, double y2, double z2, double dx2, double dy2, double dz2,
  ) {
    return (x1 < x2 + dx2 && x1 + dx1 > x2) &&
           (y1 < y2 + dy2 && y1 + dy1 > y2) &&
           (z1 < z2 + dz2 && z1 + dz1 > z2);
  }

  static List<_BoxOrientation> _getAllowedOrientations(
    double l,
    double w,
    double h,
    OrientationConstraint constraint,
  ) {
    switch (constraint) {
      case OrientationConstraint.noRotation:
        return [_BoxOrientation(l, w, h)];

      case OrientationConstraint.uprightOnly:
        // Height (h) must remain vertical (dz = h)
        // Can rotate length and width in horizontal plane
        if ((l - w).abs() < 0.1) {
          return [_BoxOrientation(l, w, h)];
        }
        return [
          _BoxOrientation(l, w, h),
          _BoxOrientation(w, l, h),
        ];

      case OrientationConstraint.allowAny:
        // All 6 3D permutations
        final permutations = <_BoxOrientation>[
          _BoxOrientation(l, w, h),
          _BoxOrientation(w, l, h),
          _BoxOrientation(l, h, w),
          _BoxOrientation(h, l, w),
          _BoxOrientation(w, h, l),
          _BoxOrientation(h, w, l),
        ];
        // Deduplicate identical dimensions
        final unique = <_BoxOrientation>[];
        for (final p in permutations) {
          final exists = unique.any((u) =>
              (u.dx - p.dx).abs() < 0.1 &&
              (u.dy - p.dy).abs() < 0.1 &&
              (u.dz - p.dz).abs() < 0.1);
          if (!exists) unique.add(p);
        }
        return unique;
    }
  }
}

class _PlacementCandidate {
  final _ExtremePoint ep;
  final double dx;
  final double dy;
  final double dz;
  const _PlacementCandidate({
    required this.ep,
    required this.dx,
    required this.dy,
    required this.dz,
  });
}

class _IsolatePackParams {
  final List<ProductItem> items;
  final ContainerSpec container;
  _IsolatePackParams({required this.items, required this.container});
}
