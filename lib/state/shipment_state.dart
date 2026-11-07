import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/container_spec.dart';
import '../core/models/cost_node.dart';
import '../core/models/currency.dart';
import '../core/models/product_item.dart';
import '../core/models/calculation_results.dart';
import '../core/network/fx_service.dart';
import '../data/repositories/shipment_repository.dart';
import '../engine/calculation_engine.dart';
import '../engine/packing/container_packer.dart';
import '../engine/packing/packed_box.dart';
import '../viewmodels/shipment_viewmodel.dart';

export '../viewmodels/shipment_viewmodel.dart';
export '../viewmodels/container_cms_viewmodel.dart';
export '../viewmodels/cost_pipeline_viewmodel.dart';
export '../core/models/shipment.dart';
export '../core/models/organization.dart';

enum AppUserRole {
  ownerExecutive(
    'Owner Executive Mode',
    'Full financial audit & margin visibility',
  ),
  internalOperator(
    'Internal Operator Mode',
    'Data entry & logistics focus (hides net profit)',
  );

  final String title;
  final String description;
  const AppUserRole(this.title, this.description);
}

/// User Role Provider
final userRoleProvider = StateProvider<AppUserRole>(
  (ref) => AppUserRole.ownerExecutive,
);

/// Apportionment Mode Provider (Target Capacity vs Actual Load)
final apportionmentModeProvider = StateProvider<ApportionmentMode>(
  (ref) => ApportionmentMode.targetCapacity,
);

/// Container Specification Provider
class ContainerSpecNotifier extends StateNotifier<ContainerSpec> {
  ContainerSpecNotifier()
    : super(ContainerSpec.fromPreset(ContainerPreset.fortyHC));

  void selectPreset(ContainerPreset preset) {
    state = ContainerSpec.fromPreset(preset);
  }

  void updateDimensions({
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    double? doorWidthCm,
    double? doorHeightCm,
    double? maxPayloadKg,
    double? roadAxleLimitKg,
    double? usableVolumePct,
  }) {
    state = state.copyWith(
      lengthCm: lengthCm,
      widthCm: widthCm,
      heightCm: heightCm,
      doorWidthCm: doorWidthCm,
      doorHeightCm: doorHeightCm,
      maxGrossPayloadKg: maxPayloadKg,
      roadAxleLimitKg: roadAxleLimitKg,
      usableVolumePct: usableVolumePct,
    );
  }
}

final containerSpecProvider =
    StateNotifierProvider<ContainerSpecNotifier, ContainerSpec>((ref) {
      return ContainerSpecNotifier();
    });

/// Currency Rates Provider
class CurrencyRatesNotifier extends StateNotifier<Map<String, CurrencyRate>> {
  CurrencyRatesNotifier()
    : super({for (final c in CurrencyRate.defaultCurrencies()) c.code: c}) {
    fetchLive();
  }

  Future<void> fetchLive() async {
    try {
      final updated = await FxService.refreshRatesWithBuffer(state);
      state = updated;
    } catch (_) {}
  }

  void updateRate(String code, double rate) {
    if (state.containsKey(code)) {
      state = {
        ...state,
        code: state[code]!.copyWith(
          rateToBase: rate,
          lastUpdated: DateTime.now(),
        ),
      };
    }
  }

  void updateBuffer(String code, double bufferPct) {
    if (state.containsKey(code)) {
      state = {
        ...state,
        code: state[code]!.copyWith(safetyBufferPct: bufferPct),
      };
    }
  }

  void toggleLock(String code) {
    if (state.containsKey(code)) {
      state = {
        ...state,
        code: state[code]!.copyWith(isLocked: !state[code]!.isLocked),
      };
    }
  }
}

final currencyRatesProvider =
    StateNotifierProvider<CurrencyRatesNotifier, Map<String, CurrencyRate>>((
      ref,
    ) {
      return CurrencyRatesNotifier();
    });

/// Dynamic Cost Pipeline Nodes Provider
class CostNodesNotifier extends StateNotifier<List<CostNode>> {
  CostNodesNotifier() : super(CostNode.defaultPipeline());

  void addNode(CostNode node) {
    state = [...state, node];
  }

  void updateNode(CostNode updated) {
    state = [
      for (final n in state)
        if (n.id == updated.id) updated else n,
    ];
  }

  void removeNode(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void toggleNodeActive(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isActive: !n.isActive) else n,
    ];
  }
}

final costNodesProvider =
    StateNotifierProvider<CostNodesNotifier, List<CostNode>>((ref) {
      return CostNodesNotifier();
    });

/// Product Items Provider
class ProductItemsNotifier extends StateNotifier<List<ProductItem>> {
  final IShipmentRepository? _repository;
  final Ref? _ref;
  final String _shipmentId;
  final String _orgId;
  Timer? _debounceTimer;

  ProductItemsNotifier([
    this._repository,
    this._ref,
    this._shipmentId = 'a0000000-0000-0000-0000-000000000001',
    this._orgId = '02337732-6c78-496b-bd95-f10feef8e135',
  ]) : super(const <ProductItem>[]) {
    _initFromRepository();
  }

  void _updateSyncStatus(SyncStatus status, {String? errorMessage}) {
    if (_ref != null) {
      Future.microtask(() {
        try {
          _ref.read(shipmentViewModelProvider.notifier).setSyncStatus(
            status,
            errorMessage: errorMessage,
          );
        } catch (_) {}
      });
    }
  }

  Future<void> _initFromRepository() async {
    if (_repository != null) {
      try {
        _updateSyncStatus(SyncStatus.syncing);
        final fetched = await _repository.getShipmentItems(_shipmentId);
        if (mounted) {
          state = fetched;
          _updateSyncStatus(SyncStatus.synced);
        }
      } catch (e) {
        if (mounted) {
          _updateSyncStatus(SyncStatus.offline, errorMessage: e.toString());
        }
      }
    }
  }

  void addItem(ProductItem item) {
    state = [...state, item];
    _updateSyncStatus(SyncStatus.syncing);
    if (_repository != null) {
      _repository.upsertItem(_shipmentId, _orgId, item).catchError((_) {});
    }
    _scheduleSync();
  }

  void updateItem(ProductItem updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    _updateSyncStatus(SyncStatus.syncing);
    if (_repository != null) {
      _repository.upsertItem(_shipmentId, _orgId, updated).catchError((_) {});
    }
    _scheduleSync();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _updateSyncStatus(SyncStatus.syncing);
    if (_repository != null) {
      _repository.deleteItem(id).catchError((_) {});
    }
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_repository == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      try {
        await _repository.saveShipmentItems(_shipmentId, _orgId, state);
        _updateSyncStatus(SyncStatus.synced);
      } catch (e) {
        _updateSyncStatus(SyncStatus.error, errorMessage: e.toString());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final productItemsProvider =
    StateNotifierProvider<ProductItemsNotifier, List<ProductItem>>((ref) {
      final repo = ref.watch(shipmentRepositoryProvider);
      return ProductItemsNotifier(repo, ref);
    });

/// Reactive Calculation Engine Totals Provider
final calculatedTotalsProvider = Provider<CalculatedShipmentTotals>((ref) {
  final items = ref.watch(productItemsProvider);
  final container = ref.watch(containerSpecProvider);
  final costNodes = ref.watch(costNodesProvider);
  final rates = ref.watch(currencyRatesProvider);
  final mode = ref.watch(apportionmentModeProvider);

  return CalculationEngine.calculate(
    items: items,
    container: container,
    costNodes: costNodes,
    currencyRates: rates,
    apportionmentMode: mode,
  );
});

/// Reactive Line Calculation Family Provider (Derived directly from shipment totals for 100% parity)
final calculatedLineItemProvider = Provider.family<CalculatedLineItem?, String>(
  (ref, itemId) {
    final totals = ref.watch(calculatedTotalsProvider);
    return totals.lineItemFor(itemId);
  },
);

/// Reactive 3D Packing Result Provider
final packingResultProvider = Provider<PackingResult>((ref) {
  final items = ref.watch(productItemsProvider);
  final container = ref.watch(containerSpecProvider);

  return ContainerPacker.pack(items: items, container: container);
});
