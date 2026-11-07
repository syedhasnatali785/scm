import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:scm/core/models/container_spec.dart';
import 'package:scm/core/models/cost_node.dart';
import 'package:scm/core/models/organization.dart';
import 'package:scm/core/models/product_item.dart';
import 'package:scm/core/models/shipment.dart';
import 'package:scm/data/repositories/organization_repository.dart';
import 'package:scm/data/repositories/shipment_repository.dart';
import 'package:scm/data/repositories/storage_repository.dart';
import 'package:scm/engine/calculation_engine.dart';
import 'package:scm/features/onboarding/onboarding_state.dart';
import 'package:scm/viewmodels/container_cms_viewmodel.dart';
import 'package:scm/viewmodels/cost_pipeline_viewmodel.dart';
import 'package:scm/viewmodels/financial_analytics_viewmodel.dart';
import 'package:scm/viewmodels/shipment_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MVVM Domain Model Serialization Tests', () {
    test('ProductItem serializes toMap and deserializes fromMap accurately', () {
      const item = ProductItem(
        id: 'sku_test_100',
        name: 'Electric Ride-on Truck',
        modelNumber: 'ERT-4x4',
        supplierName: 'Ningbo Toy Factory',
        cartonLength: 120.0,
        cartonWidth: 70.0,
        cartonHeight: 50.0,
        dimensionUnit: DimensionUnit.cm,
        manualCbmOverride: 0.45,
        orderedCartons: 80,
        piecesPerCarton: 1,
        nwPerCartonKg: 22.0,
        gwPerCartonKg: 25.0,
        unitPriceOrigin: 520.0,
        originCurrency: 'RMB',
        targetMarkupPct: 30.0,
        marketSellingPrice: 45000.0,
        boxColor: Color(0xFFE11D48),
      );

      final map = item.toMap(shipmentId: 'shipment_1', orgId: 'org_1');
      expect(map['id'], 'sku_test_100');
      expect(map['shipment_id'], 'shipment_1');
      expect(map['org_id'], 'org_1');
      expect(map['name'], 'Electric Ride-on Truck');
      expect(map['carton_length'], 120.0);
      expect(map['manual_cbm_override'], 0.45);
      expect(map['box_color'], isNotNull);

      final restored = ProductItem.fromMap(map);
      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.modelNumber, item.modelNumber);
      expect(restored.cartonLength, item.cartonLength);
      expect(restored.manualCbmOverride, item.manualCbmOverride);
      expect(restored.orderedCartons, item.orderedCartons);
      expect(restored.unitPriceOrigin, item.unitPriceOrigin);
      expect(restored.targetMarkupPct, item.targetMarkupPct);
      expect(restored.marketSellingPrice, item.marketSellingPrice);
    });

    test('Shipment model serializes toMap and deserializes fromMap', () {
      final shipment = Shipment(
        id: 'ship_001',
        orgId: 'org_001',
        name: 'Q3 Toy Import Batch',
        referenceNo: 'PO-2026-08',
        containerPreset: '40HC',
        containerSpecs: ContainerSpec.fromPreset(ContainerPreset.fortyHC),
        costPipeline: CostNode.defaultPipeline(),
        apportionmentMode: ApportionmentMode.targetCapacity,
      );

      final map = shipment.toMap();
      expect(map['id'], 'ship_001');
      expect(map['name'], 'Q3 Toy Import Batch');
      expect(map['container_preset'], '40HC');
      expect(map['apportionment_mode'], 'targetCapacity');

      final restored = Shipment.fromMap(map);
      expect(restored.id, shipment.id);
      expect(restored.name, shipment.name);
      expect(restored.referenceNo, shipment.referenceNo);
      expect(restored.containerSpecs, isNotNull);
      expect(restored.costPipeline.isNotEmpty, true);
    });

    test('Organization model serializes toMap and deserializes fromMap', () {
      const org = Organization(
        id: 'org_001',
        name: '71 International Lahore',
        slug: '71-international-lahore',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
        workflowPreset: 'SKD Assembly',
      );

      final map = org.toMap();
      expect(map['id'], 'org_001');
      expect(map['name'], '71 International Lahore');

      final restored = Organization.fromMap(map);
      expect(restored.id, org.id);
      expect(restored.name, org.name);
      expect(restored.baseCurrency, 'PKR');
    });

    test('ContainerSpec and CostNode round-trip conversion', () {
      final spec = ContainerSpec.fromPreset(ContainerPreset.twentyGP);
      final specMap = spec.toMap();
      final restoredSpec = ContainerSpec.fromMap(specMap);
      expect(restoredSpec.preset, ContainerPreset.twentyGP);
      expect(restoredSpec.doorHeightCm, 229.2);

      const node = CostNode(
        id: 'node_test',
        stage: CostStage.freight,
        name: 'Sea Freight Qingdao to Karachi',
        amount: 3200.0,
        currencyCode: 'USD',
        allocationRule: ApportionmentRule.byCbm,
      );
      final nodeMap = node.toMap();
      final restoredNode = CostNode.fromMap(nodeMap);
      expect(restoredNode.id, node.id);
      expect(restoredNode.amount, 3200.0);
      expect(restoredNode.currencyCode, 'USD');
    });
  });

  group('Repository Layer Tests', () {
    test('SupabaseShipmentRepository handles CRUD and offline stream caching', () async {
      final repo = SupabaseShipmentRepository();

      // 1. Fetch initial items (clean production starts empty or returns cached list)
      final initial = await repo.getShipmentItems('shipment_demo_01');
      expect(initial, isA<List<ProductItem>>());

      // 2. Upsert an item
      const newItem = ProductItem(
        id: 'sku_repo_test',
        name: 'Test Repo Item',
        modelNumber: 'MOD-REPO-1',
        supplierName: 'Test Supplier',
        orderedCartons: 25,
      );
      await repo.upsertItem('shipment_demo_01', 'org_default_71', newItem);

      final afterUpsert = await repo.getShipmentItems('shipment_demo_01');
      expect(afterUpsert.any((i) => i.id == 'sku_repo_test'), true);

      // 3. Delete the item
      await repo.deleteItem('sku_repo_test');
      final afterDelete = await repo.getShipmentItems('shipment_demo_01');
      expect(afterDelete.any((i) => i.id == 'sku_repo_test'), false);
    });

    test('SupabaseOrganizationRepository creates and caches organization profile', () async {
      final orgRepo = SupabaseOrganizationRepository();
      const org = Organization(
        id: 'org_test_new',
        name: 'New Test Enterprise',
        slug: 'new-test-enterprise',
      );
      final created = await orgRepo.createOrganization(org);
      expect(created.id, 'org_test_new');

      final fetched = await orgRepo.getOrganizationById('org_test_new');
      expect(fetched?.name, 'New Test Enterprise');
    });

    test('SupabaseStorageRepository generates offline fallback data URI without network', () async {
      final storageRepo = SupabaseStorageRepository();
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final url = await storageRepo.uploadThumbnail(
        orgId: 'org_1',
        shipmentId: 'ship_1',
        itemId: 'item_1',
        bytes: sampleBytes,
      );
      expect(url.startsWith('data:image/jpeg;base64,') || url.startsWith('http'), true);
    });
  });

  group('ViewModel Layer Tests', () {
    test('ShipmentViewModel performs reactive operations and tracks sync status', () async {
      final repo = SupabaseShipmentRepository();
      final vm = ShipmentViewModel(repo);

      await vm.init();
      expect(vm.state.items, isA<List<ProductItem>>());
      expect(vm.state.syncStatus, SyncStatus.synced);

      const newItem = ProductItem(
        id: 'sku_vm_test',
        name: 'VM Test Product',
        modelNumber: 'MOD-VM-1',
        supplierName: 'VM Supplier',
        orderedCartons: 15,
      );

      vm.addItem(newItem);
      expect(vm.state.items.any((i) => i.id == 'sku_vm_test'), true);
      expect(vm.state.syncStatus, SyncStatus.syncing);

      await vm.saveToSupabase();
      expect(vm.state.syncStatus, SyncStatus.synced);

      vm.removeItem('sku_vm_test');
      expect(vm.state.items.any((i) => i.id == 'sku_vm_test'), false);

      vm.dispose();
    });

    test('ContainerCmsViewModel manages presets, dimensions, and scrubber step', () {
      final vm = ContainerCmsViewModel();
      expect(vm.state.containerSpec.preset, ContainerPreset.fortyHC);

      vm.selectPreset(ContainerPreset.twentyGP);
      expect(vm.state.containerSpec.preset, ContainerPreset.twentyGP);
      expect(vm.state.containerSpec.lengthCm, 589.8);

      vm.updateDimensions(lengthCm: 600.0);
      expect(vm.state.containerSpec.lengthCm, 600.0);

      vm.setScrubberStep(5);
      expect(vm.state.activeScrubberStep, 0); // clamped to 0 when no packed boxes
    });

    test('CostPipelineViewModel handles dynamic nodes and apportionment rule', () {
      final vm = CostPipelineViewModel();
      expect(vm.state.nodes.isNotEmpty, true);

      const customNode = CostNode(
        id: 'node_custom_port',
        stage: CostStage.clearance,
        name: 'Custom Examination Fee',
        amount: 45000.0,
        currencyCode: 'PKR',
      );
      vm.addNode(customNode);
      expect(vm.state.nodes.any((n) => n.id == 'node_custom_port'), true);

      vm.toggleNodeActive('node_custom_port');
      expect(vm.state.nodes.firstWhere((n) => n.id == 'node_custom_port').isActive, false);

      vm.setApportionmentMode(ApportionmentMode.actualLoad);
      expect(vm.state.apportionmentMode, ApportionmentMode.actualLoad);

      vm.removeNode('node_custom_port');
      expect(vm.state.nodes.any((n) => n.id == 'node_custom_port'), false);
    });

    test('FinancialAnalyticsViewModel updates sensitivity overrides', () {
      final vm = FinancialAnalyticsViewModel();
      expect(vm.state.demurrageDays, 0);

      vm.setDemurrageDays(7);
      expect(vm.state.demurrageDays, 7);

      vm.setRmbRate(42.0);
      expect(vm.state.rmbRateOverride, 42.0);

      vm.reset();
      expect(vm.state.demurrageDays, 0);
      expect(vm.state.rmbRateOverride, 39.50);
    });

    test('OnboardingNotifier completes wizard and persists tenant', () async {
      final orgRepo = SupabaseOrganizationRepository();
      final vm = OnboardingNotifier(orgRepo);

      vm.setOrgName('Lahore Import Express');
      vm.setBaseCurrency('PKR');
      vm.setDefaultOriginCurrency('RMB');
      vm.setWorkflowPreset('Finished Goods');

      await vm.completeOnboarding();
      expect(vm.state.isOnboarded, true);
      expect(vm.state.orgId.isNotEmpty, true);
    });
  });
}
