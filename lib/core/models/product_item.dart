import 'package:flutter/material.dart';
import 'container_spec.dart';
import 'duty_and_assembly.dart';

/// Stacking priority tier for 3D container packing
enum StackingTier {
  heavyFloor('HEAVY (Floor)', 1),
  mediumMiddle('MEDIUM (Mid)', 2),
  fragileTop('FRAGILE (Top)', 3);

  final String label;
  final int rank; // 1 = floor, 3 = top
  const StackingTier(this.label, this.rank);
}

/// Orientation freedom during spatial bin-packing
enum OrientationConstraint {
  allowAny('Any Orientation'),
  uprightOnly('Upright Only (H Vertical)'),
  noRotation('Fixed (L x W x H)');

  final String label;
  const OrientationConstraint(this.label);
}

@immutable
class ProductItem {
  final String id;
  final String name;
  final String modelNumber;
  final String supplierName;
  
  // Dimensions & Packaging
  final double cartonLength;
  final double cartonWidth;
  final double cartonHeight;
  final DimensionUnit dimensionUnit;
  final double? manualCbmOverride;

  final int orderedCartons;
  final int piecesPerCarton;
  final double nwPerCartonKg;
  final double gwPerCartonKg;

  // 3D Spatial Attributes
  final StackingTier stackingTier;
  final OrientationConstraint orientationConstraint;

  // Origin Purchase
  final double unitPriceOrigin;
  final String originCurrency;

  // Duty & Value-Add Assembly
  final DutySpec dutySpec;
  final AssemblySpec assemblySpec;

  // Commercial / Profit Margins
  final double targetMarkupPct; // Forward pricing markup %
  final double? marketSellingPrice; // Reverse pricing competitor price
  
  // Visuals
  final Color boxColor;
  final String? photoUrl;

  const ProductItem({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.supplierName,
    this.cartonLength = 100.0,
    this.cartonWidth = 60.0,
    this.cartonHeight = 45.0,
    this.dimensionUnit = DimensionUnit.cm,
    this.manualCbmOverride,
    this.orderedCartons = 100,
    this.piecesPerCarton = 1,
    this.nwPerCartonKg = 24.0,
    this.gwPerCartonKg = 27.0,
    this.stackingTier = StackingTier.mediumMiddle,
    this.orientationConstraint = OrientationConstraint.uprightOnly,
    this.unitPriceOrigin = 420.0,
    this.originCurrency = 'RMB',
    this.dutySpec = const DutySpec(),
    this.assemblySpec = const AssemblySpec(),
    this.targetMarkupPct = 25.0,
    this.marketSellingPrice,
    this.boxColor = const Color(0xFF3B82F6),
    this.photoUrl,
  });

  // Helper getters
  double get lengthInCm => dimensionUnit.toCm(cartonLength);
  double get widthInCm => dimensionUnit.toCm(cartonWidth);
  double get heightInCm => dimensionUnit.toCm(cartonHeight);

  double get cbmPerCarton {
    if (manualCbmOverride != null && manualCbmOverride! > 0) {
      return manualCbmOverride!;
    }
    return (lengthInCm * widthInCm * heightInCm) / 1000000.0;
  }

  int get totalPieces => orderedCartons * piecesPerCarton;
  double get totalLineCbm => orderedCartons * cbmPerCarton;
  double get totalLineNwKg => orderedCartons * nwPerCartonKg;
  double get totalLineGwKg => orderedCartons * gwPerCartonKg;

  ProductItem copyWith({
    String? id,
    String? name,
    String? modelNumber,
    String? supplierName,
    double? cartonLength,
    double? cartonWidth,
    double? cartonHeight,
    DimensionUnit? dimensionUnit,
    double? manualCbmOverride,
    int? orderedCartons,
    int? piecesPerCarton,
    double? nwPerCartonKg,
    double? gwPerCartonKg,
    StackingTier? stackingTier,
    OrientationConstraint? orientationConstraint,
    double? unitPriceOrigin,
    String? originCurrency,
    DutySpec? dutySpec,
    AssemblySpec? assemblySpec,
    double? targetMarkupPct,
    double? marketSellingPrice,
    Color? boxColor,
    String? photoUrl,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      modelNumber: modelNumber ?? this.modelNumber,
      supplierName: supplierName ?? this.supplierName,
      cartonLength: cartonLength ?? this.cartonLength,
      cartonWidth: cartonWidth ?? this.cartonWidth,
      cartonHeight: cartonHeight ?? this.cartonHeight,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      manualCbmOverride: manualCbmOverride ?? this.manualCbmOverride,
      orderedCartons: orderedCartons ?? this.orderedCartons,
      piecesPerCarton: piecesPerCarton ?? this.piecesPerCarton,
      nwPerCartonKg: nwPerCartonKg ?? this.nwPerCartonKg,
      gwPerCartonKg: gwPerCartonKg ?? this.gwPerCartonKg,
      stackingTier: stackingTier ?? this.stackingTier,
      orientationConstraint: orientationConstraint ?? this.orientationConstraint,
      unitPriceOrigin: unitPriceOrigin ?? this.unitPriceOrigin,
      originCurrency: originCurrency ?? this.originCurrency,
      dutySpec: dutySpec ?? this.dutySpec,
      assemblySpec: assemblySpec ?? this.assemblySpec,
      targetMarkupPct: targetMarkupPct ?? this.targetMarkupPct,
      marketSellingPrice: marketSellingPrice ?? this.marketSellingPrice,
      boxColor: boxColor ?? this.boxColor,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap({String? shipmentId, String? orgId}) {
    return {
      'id': id,
      if (shipmentId != null) ...{'shipment_id': shipmentId},
      if (orgId != null) ...{'org_id': orgId},
      'name': name,
      'model_number': modelNumber,
      'supplier_name': supplierName,
      'carton_length': cartonLength,
      'carton_width': cartonWidth,
      'carton_height': cartonHeight,
      'dimension_unit': dimensionUnit.name,
      'manual_cbm_override': manualCbmOverride,
      'ordered_cartons': orderedCartons,
      'pieces_per_carton': piecesPerCarton,
      'nw_per_carton_kg': nwPerCartonKg,
      'gw_per_carton_kg': gwPerCartonKg,
      'unit_price_origin': unitPriceOrigin,
      'origin_currency': originCurrency,
      'duty_spec': dutySpec.toMap(),
      'assembly_spec': assemblySpec.toMap(),
      'target_markup_pct': targetMarkupPct,
      'market_selling_price': marketSellingPrice,
      'box_color': '#${boxColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'photo_url': photoUrl,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    DimensionUnit unit = DimensionUnit.cm;
    for (final u in DimensionUnit.values) {
      if (u.name == map['dimension_unit']) {
        unit = u;
        break;
      }
    }

    Color color = const Color(0xFF3B82F6);
    if (map['box_color'] != null) {
      final colorStr = (map['box_color'] as String).replaceFirst('#', '');
      final intVal = int.tryParse(colorStr, radix: 16);
      if (intVal != null) {
        color = Color(intVal);
      }
    }

    return ProductItem(
      id: map['id']?.toString() ?? 'sku_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Untitled Item',
      modelNumber: map['model_number'] as String? ?? 'MOD-001',
      supplierName: map['supplier_name'] as String? ?? '',
      cartonLength: (map['carton_length'] as num?)?.toDouble() ?? 100.0,
      cartonWidth: (map['carton_width'] as num?)?.toDouble() ?? 60.0,
      cartonHeight: (map['carton_height'] as num?)?.toDouble() ?? 45.0,
      dimensionUnit: unit,
      manualCbmOverride: (map['manual_cbm_override'] as num?)?.toDouble(),
      orderedCartons: (map['ordered_cartons'] as num?)?.toInt() ?? 1,
      piecesPerCarton: (map['pieces_per_carton'] as num?)?.toInt() ?? 1,
      nwPerCartonKg: (map['nw_per_carton_kg'] as num?)?.toDouble() ?? 10.0,
      gwPerCartonKg: (map['gw_per_carton_kg'] as num?)?.toDouble() ?? 12.0,
      stackingTier: StackingTier.mediumMiddle,
      orientationConstraint: OrientationConstraint.uprightOnly,
      unitPriceOrigin: (map['unit_price_origin'] as num?)?.toDouble() ?? 100.0,
      originCurrency: map['origin_currency'] as String? ?? 'RMB',
      dutySpec: DutySpec.fromMap(map['duty_spec'] as Map<String, dynamic>?),
      assemblySpec: AssemblySpec.fromMap(map['assembly_spec'] as Map<String, dynamic>?),
      targetMarkupPct: (map['target_markup_pct'] as num?)?.toDouble() ?? 25.0,
      marketSellingPrice: (map['market_selling_price'] as num?)?.toDouble(),
      boxColor: color,
      photoUrl: map['photo_url'] as String?,
    );
  }
}

