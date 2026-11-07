import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/product_item.dart';
import '../../core/models/shipment.dart';
import '../../core/network/supabase_config.dart';

abstract class IShipmentRepository {
  Future<List<Shipment>> getShipments({required String orgId});
  Future<Shipment?> getShipmentById(String id);
  Future<Shipment> saveShipment(Shipment shipment);
  Future<List<ProductItem>> getShipmentItems(String shipmentId);
  Future<void> saveShipmentItems(
    String shipmentId,
    String orgId,
    List<ProductItem> items,
  );
  Future<void> upsertItem(String shipmentId, String orgId, ProductItem item);
  Future<void> deleteItem(String itemId);
  Stream<List<ProductItem>> streamShipmentItems(String shipmentId);
}

class SupabaseShipmentRepository implements IShipmentRepository {
  // In-memory fallback cache when running offline or in demo mode
  final Map<String, Shipment> _cachedShipments = {};
  final Map<String, List<ProductItem>> _cachedItems = {};
  final _itemsStreamController =
      StreamController<List<ProductItem>>.broadcast();

  bool get _canUseSupabase =>
      SupabaseConfig.isInitialized && !SupabaseConfig.isMockMode;

  @override
  Future<List<Shipment>> getShipments({required String orgId}) async {
    if (_canUseSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from('shipments')
            .select()
            .eq('org_id', orgId)
            .order('created_at', ascending: false);
        final list = (res as List)
            .map((e) => Shipment.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (final s in list) {
          _cachedShipments[s.id] = s;
        }
        return list;
      } catch (e) {
        debugPrint('Supabase getShipments error, falling back to cache: $e');
      }
    }
    return _cachedShipments.values.where((s) => s.orgId == orgId).toList();
  }

  @override
  Future<Shipment?> getShipmentById(String id) async {
    if (_canUseSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from('shipments')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (res != null) {
          final s = Shipment.fromMap(Map<String, dynamic>.from(res));
          _cachedShipments[s.id] = s;
          return s;
        }
      } catch (e) {
        debugPrint('Supabase getShipmentById error: $e');
      }
    }
    return _cachedShipments[id];
  }

  @override
  Future<Shipment> saveShipment(Shipment shipment) async {
    _cachedShipments[shipment.id] = shipment;

    if (_canUseSupabase) {
      try {
        final map = shipment.toMap();
        await SupabaseConfig.client.from('shipments').upsert(map);
      } catch (e) {
        debugPrint('Supabase saveShipment error (cached locally): $e');
      }
    }
    return shipment;
  }

  @override
  Future<List<ProductItem>> getShipmentItems(String shipmentId) async {
    if (_canUseSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from('shipment_items')
            .select()
            .eq('shipment_id', shipmentId)
            .order('created_at', ascending: true);
        final items = (res as List)
            .map(
              (e) => ProductItem.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _cachedItems[shipmentId] = items;
        return items;
      } catch (e) {
        debugPrint('Supabase getShipmentItems error, using fallback: $e');
      }
    }
    return _cachedItems[shipmentId] ?? const <ProductItem>[];
  }

  @override
  Future<void> saveShipmentItems(
    String shipmentId,
    String orgId,
    List<ProductItem> items,
  ) async {
    _cachedItems[shipmentId] = List.from(items);
    _itemsStreamController.add(items);

    if (_canUseSupabase) {
      try {
        if (items.isEmpty) {
          await SupabaseConfig.client
              .from('shipment_items')
              .delete()
              .eq('shipment_id', shipmentId);
        } else {
          final records = items
              .map((i) => i.toMap(shipmentId: shipmentId, orgId: orgId))
              .toList();
          await SupabaseConfig.client.from('shipment_items').upsert(records);
        }
      } catch (e) {
        debugPrint('Supabase saveShipmentItems error: $e');
      }
    }
  }

  @override
  Future<void> upsertItem(
    String shipmentId,
    String orgId,
    ProductItem item,
  ) async {
    final list = _cachedItems[shipmentId] ?? [];
    final idx = list.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    _cachedItems[shipmentId] = list;
    _itemsStreamController.add(list);

    if (_canUseSupabase) {
      try {
        final map = item.toMap(shipmentId: shipmentId, orgId: orgId);
        await SupabaseConfig.client.from('shipment_items').upsert(map);
      } catch (e) {
        debugPrint('Supabase upsertItem error: $e');
      }
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    for (final key in _cachedItems.keys) {
      _cachedItems[key] = _cachedItems[key]!
          .where((i) => i.id != itemId)
          .toList();
      _itemsStreamController.add(_cachedItems[key]!);
    }

    if (_canUseSupabase) {
      try {
        await SupabaseConfig.client
            .from('shipment_items')
            .delete()
            .eq('id', itemId);
      } catch (e) {
        debugPrint('Supabase deleteItem error: $e');
      }
    }
  }

  @override
  Stream<List<ProductItem>> streamShipmentItems(String shipmentId) {
    if (_canUseSupabase) {
      try {
        return SupabaseConfig.client
            .from('shipment_items')
            .stream(primaryKey: ['id'])
            .eq('shipment_id', shipmentId)
            .map((data) => data.map((e) => ProductItem.fromMap(e)).toList());
      } catch (e) {
        debugPrint(
          'Supabase realtime stream error, using broadcast stream: $e',
        );
      }
    }
    return _itemsStreamController.stream;
  }
}
