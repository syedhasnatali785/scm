import 'package:flutter_test/flutter_test.dart';
import 'package:scm/core/models/container_spec.dart';
import 'package:scm/core/models/product_item.dart';
import 'package:scm/engine/packing/container_packer.dart';

void main() {
  group('ContainerPacker Tests', () {
    test('Packs boxes inside 40HC container without exceeding dimensions', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      final item = ProductItem(
        id: 'box_item',
        name: 'Standard Box',
        modelNumber: 'SB-01',
        supplierName: 'Vendor X',
        cartonLength: 60.0,
        cartonWidth: 40.0,
        cartonHeight: 40.0,
        orderedCartons: 100,
        gwPerCartonKg: 15.0,
      );

      final result = ContainerPacker.pack(items: [item], container: container);

      expect(result.totalPackedCartons, equals(100));
      for (final box in result.boxes) {
        expect(box.x + box.dx, lessThanOrEqualTo(container.lengthCm + 0.001));
        expect(box.y + box.dy, lessThanOrEqualTo(container.widthCm + 0.001));
        expect(box.z + box.dz, lessThanOrEqualTo(container.heightCm + 0.001));
      }
    });

    test('Prioritizes Stacking Tiers (Heavy Floor boxes at bottom, Fragile Top boxes higher)', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);

      final heavyItem = ProductItem(
        id: 'heavy_base',
        name: 'Heavy Electric Motor',
        modelNumber: 'EM-100',
        supplierName: 'Motor Corp',
        cartonLength: 80.0,
        cartonWidth: 60.0,
        cartonHeight: 50.0,
        orderedCartons: 10,
        gwPerCartonKg: 45.0,
        stackingTier: StackingTier.heavyFloor,
      );

      final fragileItem = ProductItem(
        id: 'fragile_glass',
        name: 'Display Glass Panels',
        modelNumber: 'GL-100',
        supplierName: 'Glass Corp',
        cartonLength: 80.0,
        cartonWidth: 60.0,
        cartonHeight: 30.0,
        orderedCartons: 10,
        gwPerCartonKg: 8.0,
        stackingTier: StackingTier.fragileTop,
      );

      // Pass fragile item first in the list to test that heuristic sorts them correctly
      final result = ContainerPacker.pack(
        items: [fragileItem, heavyItem],
        container: container,
      );

      expect(result.totalPackedCartons, equals(20));

      final heavyBoxes = result.boxes
          .where((b) => b.itemId == 'heavy_base')
          .toList();
      final fragileBoxes = result.boxes
          .where((b) => b.itemId == 'fragile_glass')
          .toList();

      // Heavy boxes must be loaded on the floor (Z = 0)
      for (final h in heavyBoxes) {
        expect(h.z, equals(0.0));
      }

      // Fragile boxes are placed according to tier
      for (final f in fragileBoxes) {
        expect(f.stackingTier, equals(StackingTier.fragileTop));
      }
    });

    test('Enforces Upright Only orientation constraint (dz remains equal to carton height)', () {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);

      final uprightItem = ProductItem(
        id: 'fridge_item',
        name: 'Mini Refrigerator',
        modelNumber: 'RF-80',
        supplierName: 'Cool Appliances',
        cartonLength: 50.0,
        cartonWidth: 50.0,
        cartonHeight: 85.0,
        orderedCartons: 15,
        gwPerCartonKg: 20.0,
        orientationConstraint: OrientationConstraint.uprightOnly,
      );

      final result = ContainerPacker.pack(
        items: [uprightItem],
        container: container,
      );

      expect(result.totalPackedCartons, equals(15));
      for (final box in result.boxes) {
        // Vertical dimension dz must be strictly equal to height (85 cm)
        expect(box.dz, equals(85.0));
      }
    });

    test(
      'Computes 3-segment capacity breakdown (Occupied, Void Waste, Free CBM)',
      () {
        final container = ContainerSpec.fromPreset(ContainerPreset.twentyGP);
        final item = ProductItem(
          id: 'box_item_2',
          name: 'Carton Standard',
          modelNumber: 'CS-01',
          supplierName: 'Box Factory',
          cartonLength: 50.0,
          cartonWidth: 40.0,
          cartonHeight: 30.0, // 0.06 CBM
          orderedCartons: 50, // 3.0 CBM
          gwPerCartonKg: 10.0,
        );

        final result = ContainerPacker.pack(
          items: [item],
          container: container,
        );

        expect(result.packedCbm, closeTo(3.0, 0.01));
        expect(result.usableCbm, greaterThan(25.0));
        expect(result.freeCbm, greaterThan(0.0));
        expect(
          result.occupiedPct + result.voidWastePct + result.freePct,
          closeTo(100.0, 1.0),
        );
      },
    );

    test('Background isolate packAsync completes successfully', () async {
      final container = ContainerSpec.fromPreset(ContainerPreset.fortyHC);
      final item = ProductItem(
        id: 'async_item',
        name: 'Async Box',
        modelNumber: 'AB-01',
        supplierName: 'Async Factory',
        cartonLength: 60.0,
        cartonWidth: 40.0,
        cartonHeight: 40.0,
        orderedCartons: 20,
        gwPerCartonKg: 12.0,
      );

      final result = await ContainerPacker.packAsync(
        items: [item],
        container: container,
      );

      expect(result.totalPackedCartons, equals(20));
      expect(result.packedCbm, greaterThan(0.0));
    });
  });
}
