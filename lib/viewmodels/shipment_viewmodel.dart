import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/product_item.dart';
import '../../data/repositories/shipment_repository.dart';

enum SyncStatus { synced, syncing, error, offline }

@immutable
class ShipmentState {
  final String activeShipmentId;
  final String activeOrgId;
  final List<ProductItem> items;
  final SyncStatus syncStatus;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const ShipmentState({
    this.activeShipmentId = 'a0000000-0000-0000-0000-000000000001',
    this.activeOrgId = '02337732-6c78-496b-bd95-f10feef8e135',
    this.items = const [],
    this.syncStatus = SyncStatus.synced,
    this.errorMessage,
    this.lastSyncedAt,
  });

  ShipmentState copyWith({
    String? activeShipmentId,
    String? activeOrgId,
    List<ProductItem>? items,
    SyncStatus? syncStatus,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return ShipmentState(
      activeShipmentId: activeShipmentId ?? this.activeShipmentId,
      activeOrgId: activeOrgId ?? this.activeOrgId,
      items: items ?? this.items,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class ShipmentViewModel extends StateNotifier<ShipmentState> {
  final IShipmentRepository _repository;
  Timer? _debounceTimer;
  StreamSubscription? _itemsSub;

  ShipmentViewModel(this._repository) : super(const ShipmentState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(syncStatus: SyncStatus.syncing);
    try {
      final items = await _repository.getShipmentItems(state.activeShipmentId);
      state = state.copyWith(
        items: items,
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      );

      // Listen to real-time changes
      _itemsSub?.cancel();
      _itemsSub = _repository
          .streamShipmentItems(state.activeShipmentId)
          .listen(
            (updatedItems) {
              if (mounted) {
                state = state.copyWith(
                  items: updatedItems,
                  syncStatus: SyncStatus.synced,
                );
              }
            },
            onError: (err) {
              debugPrint('Shipment items stream error: $err');
            },
          );
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.offline,
        errorMessage: e.toString(),
      );
    }
  }

  void addItem(ProductItem item) {
    final updated = [...state.items, item];
    state = state.copyWith(items: updated, syncStatus: SyncStatus.syncing);
    _scheduleAutoSync();
  }

  void updateItem(ProductItem updated) {
    final newItems = [
      for (final item in state.items)
        if (item.id == updated.id) updated else item,
    ];
    state = state.copyWith(items: newItems, syncStatus: SyncStatus.syncing);
    _scheduleAutoSync();
  }

  void removeItem(String id) {
    final filtered = state.items.where((i) => i.id != id).toList();
    state = state.copyWith(items: filtered, syncStatus: SyncStatus.syncing);
    _scheduleAutoSync();
  }

  void importItems(List<ProductItem> newItems) {
    final updated = [...state.items, ...newItems];
    state = state.copyWith(items: updated, syncStatus: SyncStatus.syncing);
    _scheduleAutoSync();
  }

  Future<void> saveToSupabase() async {
    state = state.copyWith(syncStatus: SyncStatus.syncing);
    try {
      await _repository.saveShipmentItems(
        state.activeShipmentId,
        state.activeOrgId,
        state.items,
      );
      state = state.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void setSyncStatus(SyncStatus status, {String? errorMessage}) {
    state = state.copyWith(
      syncStatus: status,
      errorMessage: errorMessage,
      lastSyncedAt: status == SyncStatus.synced ? DateTime.now() : state.lastSyncedAt,
    );
  }

  void _scheduleAutoSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      saveToSupabase();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }
}

// Global Repository Provider
final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  return SupabaseShipmentRepository();
});

// Primary Shipment ViewModel Provider
final shipmentViewModelProvider =
    StateNotifierProvider<ShipmentViewModel, ShipmentState>((ref) {
      final repo = ref.watch(shipmentRepositoryProvider);
      return ShipmentViewModel(repo);
    });
