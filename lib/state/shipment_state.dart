import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/container_spec.dart';
import '../core/models/cost_node.dart';
import '../core/models/currency.dart';
import '../core/models/duty_and_assembly.dart';
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
  final String _shipmentId;
  final String _orgId;
  Timer? _debounceTimer;

  ProductItemsNotifier([
    this._repository,
    this._shipmentId = 'shipment_demo_01',
    this._orgId = 'org_default_71',
  ]) : super(_initialDemoItems()) {
    _initFromRepository();
  }

  Future<void> _initFromRepository() async {
    if (_repository != null) {
      try {
        final fetched = await _repository.getShipmentItems(_shipmentId);
        if (fetched.isNotEmpty && mounted) {
          state = fetched;
        }
      } catch (_) {}
    }
  }

  static List<ProductItem> _initialDemoItems() {
    return [
      const ProductItem(
        id: 'sku_1',
        name: 'HF Electric Ride-on Jeep 601',
        modelNumber: 'HF-601-RED',
        supplierName: 'Zhejiang Pinghu Toys Co.',
        cartonLength: 135.0,
        cartonWidth: 75.0,
        cartonHeight: 52.0,
        dimensionUnit: DimensionUnit.cm,
        orderedCartons: 50,
        piecesPerCarton: 1,
        nwPerCartonKg: 25.0,
        gwPerCartonKg: 28.5,
        stackingTier: StackingTier.heavyFloor,
        orientationConstraint: OrientationConstraint.uprightOnly,
        unitPriceOrigin: 450.0,
        originCurrency: 'RMB',
        dutySpec: DutySpec(
          mode: DutyMode.flatRate,
          flatBasis: FlatRateBasis.perKgGross,
          flatRateAmount: 220.0,
        ),
        assemblySpec: AssemblySpec(
          isEnabled: true,
          localBoxCost: 400.0,
          technicianLaborCost: 650.0,
          localPartsCost: 1500.0,
          defectWastagePct: 2.0,
        ),
        targetMarkupPct: 25.0,
        boxColor: Color(0xFF3B82F6), // Blue
      ),
      const ProductItem(
        id: 'sku_2',
        name: 'Super Drift 24V Go-Kart',
        modelNumber: 'GK-24V-BLK',
        supplierName: 'Guangdong Motion Tech',
        cartonLength: 110.0,
        cartonWidth: 62.0,
        cartonHeight: 38.0,
        dimensionUnit: DimensionUnit.cm,
        orderedCartons: 60,
        piecesPerCarton: 1,
        nwPerCartonKg: 19.0,
        gwPerCartonKg: 22.0,
        stackingTier: StackingTier.mediumMiddle,
        orientationConstraint: OrientationConstraint.uprightOnly,
        unitPriceOrigin: 380.0,
        originCurrency: 'RMB',
        dutySpec: DutySpec(
          mode: DutyMode.flatRate,
          flatBasis: FlatRateBasis.perKgGross,
          flatRateAmount: 220.0,
        ),
        assemblySpec: AssemblySpec(
          isEnabled: true,
          localBoxCost: 350.0,
          technicianLaborCost: 550.0,
          localPartsCost: 1200.0,
          defectWastagePct: 1.5,
        ),
        targetMarkupPct: 28.0,
        boxColor: Color(0xFF10B981), // Emerald
      ),
      const ProductItem(
        id: 'sku_3',
        name: 'Toddler Balance Bike (4-in-1)',
        modelNumber: 'BB-4IN1-BLU',
        supplierName: 'Hebei Kids Cycle Co.',
        cartonLength: 68.0,
        cartonWidth: 32.0,
        cartonHeight: 30.0,
        dimensionUnit: DimensionUnit.cm,
        orderedCartons: 80,
        piecesPerCarton: 2,
        nwPerCartonKg: 9.0,
        gwPerCartonKg: 10.5,
        stackingTier: StackingTier.fragileTop,
        orientationConstraint: OrientationConstraint.allowAny,
        unitPriceOrigin: 85.0,
        originCurrency: 'RMB',
        dutySpec: DutySpec(
          mode: DutyMode.flatRate,
          flatBasis: FlatRateBasis.perKgGross,
          flatRateAmount: 200.0,
        ),
        assemblySpec: AssemblySpec(isEnabled: false),
        targetMarkupPct: 30.0,
        boxColor: Color(0xFFF59E0B), // Amber
      ),
    ];
  }

  void addItem(ProductItem item) {
    state = [...state, item];
    _scheduleSync();
  }

  void updateItem(ProductItem updated) {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    _scheduleSync();
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _scheduleSync();
  }

  void _scheduleSync() {
    if (_repository == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _repository.saveShipmentItems(_shipmentId, _orgId, state);
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
      return ProductItemsNotifier(repo);
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

/// Reactive Line Calculation Family Provider
final calculatedLineItemProvider = Provider.family<CalculatedLineItem?, String>(
  (ref, itemId) {
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final costNodes = ref.watch(costNodesProvider);
    final rates = ref.watch(currencyRatesProvider);
    final mode = ref.watch(apportionmentModeProvider);

    final item = items.cast<ProductItem?>().firstWhere(
      (i) => i?.id == itemId,
      orElse: () => null,
    );
    if (item == null) return null;

    // We run calculation for all items to get true cross-item apportionment
    CalculationEngine.calculate(
      items: items,
      container: container,
      costNodes: costNodes,
      currencyRates: rates,
      apportionmentMode: mode,
    );

    // Return the specific line item calculated
    // Re-run calculation helper for single item precision
    return _calculateSingleLine(item, items, container, costNodes, rates, mode);
  },
);

CalculatedLineItem _calculateSingleLine(
  ProductItem target,
  List<ProductItem> allItems,
  ContainerSpec container,
  List<CostNode> costNodes,
  Map<String, CurrencyRate> rates,
  ApportionmentMode mode,
) {
  // Leverage calculation engine logic directly
  final totals = CalculationEngine.calculate(
    items: allItems,
    container: container,
    costNodes: costNodes,
    currencyRates: rates,
    apportionmentMode: mode,
  );

  // Pre-calculate line specifics
  final originRate = rates[target.originCurrency]?.effectiveRate ?? 1.0;
  final purBase = target.totalPieces * target.unitPriceOrigin * originRate;
  final purPerPc = target.totalPieces > 0
      ? (purBase / target.totalPieces)
      : 0.0;

  double totalLogisticsBase = 0.0;
  for (final n in costNodes.where((c) => c.isActive)) {
    final r = rates[n.currencyCode]?.effectiveRate ?? 1.0;
    totalLogisticsBase += n.amount * r;
  }

  final cbmDenom = (mode == ApportionmentMode.targetCapacity)
      ? container.usableCbm
      : totals.totalCbm;
  final factor = (cbmDenom > 0) ? (target.totalLineCbm / cbmDenom) : 0.0;
  final logisticsShare = totalLogisticsBase * factor;
  final logisticsPerPc = target.totalPieces > 0
      ? (logisticsShare / target.totalPieces)
      : 0.0;

  // Duty
  final dutyTotal = CalculationEngine.calculateDuty(
    item: target,
    purchaseBaseTotal: purBase,
    logisticsShareTotal: logisticsShare,
  );
  final dutyPerPc = target.totalPieces > 0
      ? (dutyTotal / target.totalPieces)
      : 0.0;

  final assemblyPerPc = target.assemblySpec.totalPerPieceAddition;
  final assemblyTotal = target.totalPieces * assemblyPerPc;

  final totalCost = purBase + logisticsShare + dutyTotal + assemblyTotal;
  final sellable =
      target.totalPieces *
      (1.0 - (target.assemblySpec.defectWastagePct / 100.0));
  final ulc = sellable > 0 ? (totalCost / sellable) : 0.0;

  double sellingPrice;
  double markupPct;
  double marginPct;

  if (target.marketSellingPrice != null && target.marketSellingPrice! > 0) {
    sellingPrice = target.marketSellingPrice!;
    markupPct = ulc > 0 ? ((sellingPrice - ulc) / ulc) * 100.0 : 0.0;
    marginPct = sellingPrice > 0
        ? ((sellingPrice - ulc) / sellingPrice) * 100.0
        : 0.0;
  } else {
    markupPct = target.targetMarkupPct;
    sellingPrice = ulc * (1.0 + (markupPct / 100.0));
    marginPct = sellingPrice > 0
        ? ((sellingPrice - ulc) / sellingPrice) * 100.0
        : 0.0;
  }

  final revenue = sellingPrice * sellable;
  final netProfit = revenue - totalCost;
  final collision =
      target.heightInCm > container.doorHeightCm ||
      target.widthInCm > container.doorWidthCm;

  return CalculatedLineItem(
    itemId: target.id,
    purchaseBaseTotal: purBase,
    purchaseBasePerPiece: purPerPc,
    logisticsShareTotal: logisticsShare,
    logisticsSharePerPiece: logisticsPerPc,
    dutyBaseTotal: dutyTotal,
    dutyBasePerPiece: dutyPerPc,
    assemblyBaseTotal: assemblyTotal,
    assemblyBasePerPiece: assemblyPerPc,
    totalLineCost: totalCost,
    sellablePieces: sellable,
    unitLandedCost: ulc,
    projectedSellingPrice: sellingPrice,
    effectiveMarkupPct: markupPct,
    effectiveMarginPct: marginPct,
    projectedLineRevenue: revenue,
    projectedLineNetProfit: netProfit,
    doorwayCollision: collision,
  );
}

/// Reactive 3D Packing Result Provider
final packingResultProvider = Provider<PackingResult>((ref) {
  final items = ref.watch(productItemsProvider);
  final container = ref.watch(containerSpecProvider);

  return ContainerPacker.pack(items: items, container: container);
});
