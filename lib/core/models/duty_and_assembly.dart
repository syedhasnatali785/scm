import 'package:flutter/foundation.dart';

enum DutyMode {
  flatRate('Commercial Clearing Flat Rate'),
  statutoryCascade('Statutory Customs Tax Cascade');

  final String label;
  const DutyMode(this.label);
}

enum FlatRateBasis {
  perKgGross('Per Kg Gross Weight'),
  perKgNet('Per Kg Net Weight'),
  perPiece('Per Piece / Unit'),
  perCbm('Per CBM Volume'),
  fixedLumpSum('Fixed Lump Sum');

  final String label;
  const FlatRateBasis(this.label);
}

@immutable
class DutySpec {
  final DutyMode mode;
  final FlatRateBasis flatBasis;
  final double flatRateAmount; // in Base Currency (PKR)
  
  // Statutory Cascade percentages
  final double landingChargesPct;     // 1% WeBOC/PSW Landing Charges
  final double customsDutyPct;        // CD %
  final double additionalCustomsDutyPct; // ACD %
  final double regulatoryDutyPct;     // RD %
  final double salesTaxPct;           // ST %
  final double additionalSalesTaxPct; // AST / VAT %
  final double withholdingTaxPct;     // WHT %
  final bool isFiler;                 // Filer vs Non-Filer status (Non-Filer doubles WHT)

  const DutySpec({
    this.mode = DutyMode.flatRate,
    this.flatBasis = FlatRateBasis.perKgGross,
    this.flatRateAmount = 240.0,
    this.landingChargesPct = 1.0,
    this.customsDutyPct = 20.0,
    this.additionalCustomsDutyPct = 6.0,
    this.regulatoryDutyPct = 10.0,
    this.salesTaxPct = 18.0,
    this.additionalSalesTaxPct = 3.0,
    this.withholdingTaxPct = 6.0,
    this.isFiler = true,
  });

  DutySpec copyWith({
    DutyMode? mode,
    FlatRateBasis? flatBasis,
    double? flatRateAmount,
    double? landingChargesPct,
    double? customsDutyPct,
    double? additionalCustomsDutyPct,
    double? regulatoryDutyPct,
    double? salesTaxPct,
    double? additionalSalesTaxPct,
    double? withholdingTaxPct,
    bool? isFiler,
  }) {
    return DutySpec(
      mode: mode ?? this.mode,
      flatBasis: flatBasis ?? this.flatBasis,
      flatRateAmount: flatRateAmount ?? this.flatRateAmount,
      landingChargesPct: landingChargesPct ?? this.landingChargesPct,
      customsDutyPct: customsDutyPct ?? this.customsDutyPct,
      additionalCustomsDutyPct: additionalCustomsDutyPct ?? this.additionalCustomsDutyPct,
      regulatoryDutyPct: regulatoryDutyPct ?? this.regulatoryDutyPct,
      salesTaxPct: salesTaxPct ?? this.salesTaxPct,
      additionalSalesTaxPct: additionalSalesTaxPct ?? this.additionalSalesTaxPct,
      withholdingTaxPct: withholdingTaxPct ?? this.withholdingTaxPct,
      isFiler: isFiler ?? this.isFiler,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mode': mode.name,
      'flat_basis': flatBasis.name,
      'flat_rate_amount': flatRateAmount,
      'landing_charges_pct': landingChargesPct,
      'customs_duty_pct': customsDutyPct,
      'additional_customs_duty_pct': additionalCustomsDutyPct,
      'regulatory_duty_pct': regulatoryDutyPct,
      'sales_tax_pct': salesTaxPct,
      'additional_sales_tax_pct': additionalSalesTaxPct,
      'withholding_tax_pct': withholdingTaxPct,
      'is_filer': isFiler,
    };
  }

  factory DutySpec.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DutySpec();
    DutyMode m = DutyMode.flatRate;
    for (final v in DutyMode.values) {
      if (v.name == map['mode']) {
        m = v;
        break;
      }
    }
    FlatRateBasis b = FlatRateBasis.perKgGross;
    for (final v in FlatRateBasis.values) {
      if (v.name == map['flat_basis']) {
        b = v;
        break;
      }
    }
    return DutySpec(
      mode: m,
      flatBasis: b,
      flatRateAmount: (map['flat_rate_amount'] as num?)?.toDouble() ?? 240.0,
      landingChargesPct: (map['landing_charges_pct'] as num?)?.toDouble() ?? 1.0,
      customsDutyPct: (map['customs_duty_pct'] as num?)?.toDouble() ?? 20.0,
      additionalCustomsDutyPct: (map['additional_customs_duty_pct'] as num?)?.toDouble() ?? 6.0,
      regulatoryDutyPct: (map['regulatory_duty_pct'] as num?)?.toDouble() ?? 10.0,
      salesTaxPct: (map['sales_tax_pct'] as num?)?.toDouble() ?? 18.0,
      additionalSalesTaxPct: (map['additional_sales_tax_pct'] as num?)?.toDouble() ?? 3.0,
      withholdingTaxPct: (map['withholding_tax_pct'] as num?)?.toDouble() ?? 6.0,
      isFiler: map['is_filer'] as bool? ?? true,
    );
  }
}

@immutable
class AssemblySpec {
  final bool isEnabled;
  final double localBoxCost;       // per piece
  final double technicianLaborCost; // per piece
  final double localPartsCost;     // per piece (battery, charger, accessories)
  final double defectWastagePct;   // e.g. 2.0%

  const AssemblySpec({
    this.isEnabled = false,
    this.localBoxCost = 350.0,
    this.technicianLaborCost = 650.0,
    this.localPartsCost = 1200.0,
    this.defectWastagePct = 2.0,
  });

  double get totalPerPieceAddition =>
      isEnabled ? (localBoxCost + technicianLaborCost + localPartsCost) : 0.0;

  AssemblySpec copyWith({
    bool? isEnabled,
    double? localBoxCost,
    double? technicianLaborCost,
    double? localPartsCost,
    double? defectWastagePct,
  }) {
    return AssemblySpec(
      isEnabled: isEnabled ?? this.isEnabled,
      localBoxCost: localBoxCost ?? this.localBoxCost,
      technicianLaborCost: technicianLaborCost ?? this.technicianLaborCost,
      localPartsCost: localPartsCost ?? this.localPartsCost,
      defectWastagePct: defectWastagePct ?? this.defectWastagePct,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_enabled': isEnabled,
      'local_box_cost': localBoxCost,
      'technician_labor_cost': technicianLaborCost,
      'local_parts_cost': localPartsCost,
      'defect_wastage_pct': defectWastagePct,
    };
  }

  factory AssemblySpec.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AssemblySpec();
    return AssemblySpec(
      isEnabled: map['is_enabled'] as bool? ?? false,
      localBoxCost: (map['local_box_cost'] as num?)?.toDouble() ?? 350.0,
      technicianLaborCost: (map['technician_labor_cost'] as num?)?.toDouble() ?? 650.0,
      localPartsCost: (map['local_parts_cost'] as num?)?.toDouble() ?? 1200.0,
      defectWastagePct: (map['defect_wastage_pct'] as num?)?.toDouble() ?? 2.0,
    );
  }
}

