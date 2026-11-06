import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../core/models/duty_and_assembly.dart';
import '../../../core/models/product_item.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/formula_evaluator.dart';
import '../../../state/shipment_state.dart';

class ParametricAuditGrid extends ConsumerStatefulWidget {
  const ParametricAuditGrid({super.key});

  @override
  ConsumerState<ParametricAuditGrid> createState() =>
      _ParametricAuditGridState();
}

class _ParametricAuditGridState extends ConsumerState<ParametricAuditGrid> {
  PlutoGridStateManager? _stateManager;
  final List<PlutoColumn> _columns = [];
  final List<PlutoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _buildColumns();
  }

  void _buildColumns() {
    _columns.addAll([
      // --- FROZEN LEFT COLUMNS ---
      PlutoColumn(
        title: 'Product / Model SKU',
        field: 'name_sku',
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.start,
        width: 220,
        enableEditingMode: true,
        renderer: (rendererContext) {
          final val = rendererContext.cell.value.toString();
          final isMissing = val.trim().isEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMissing
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : Colors.transparent,
              border: isMissing
                  ? Border.all(color: const Color(0xFFEF4444))
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMissing ? 'Required SKU' : val,
                    style: TextStyle(
                      color: isMissing ? const Color(0xFFF87171) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // --- PACKAGING & DIMENSIONS (3-TIER SYNC) ---
      PlutoColumn(
        title: 'Cartons (Ctn)',
        field: 'ordered_cartons',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Pcs / Ctn',
        field: 'pcs_per_carton',
        type: PlutoColumnType.text(),
        width: 100,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Total Pieces',
        field: 'total_pieces',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode:
            true, // Allows typing total pieces to back-calculate cartons
      ),
      PlutoColumn(
        title: 'L (cm)',
        field: 'carton_length',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'W (cm)',
        field: 'carton_width',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'H (cm)',
        field: 'carton_height',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'CBM / Ctn',
        field: 'cbm_per_carton',
        type: PlutoColumnType.text(),
        width: 110,
        enableEditingMode: true, // Manual CBM override
      ),
      PlutoColumn(
        title: 'Line CBM',
        field: 'total_line_cbm',
        type: PlutoColumnType.number(format: '#,##0.00'),
        readOnly: true,
        width: 105,
      ),
      PlutoColumn(
        title: 'GW / Ctn (kg)',
        field: 'gw_per_carton',
        type: PlutoColumnType.text(),
        width: 115,
        enableEditingMode: true,
      ),

      // --- FACTORY FOB & CURRENCY ---
      PlutoColumn(
        title: 'FOB Price (Origin)',
        field: 'unit_price_origin',
        type: PlutoColumnType.text(),
        width: 140,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Origin Curr',
        field: 'origin_currency',
        type: PlutoColumnType.select(['RMB', 'USD', 'EUR', 'AED', 'PKR']),
        width: 110,
        enableEditingMode: true,
      ),

      // --- DUTY MODE (FLAT VS STATUTORY) ---
      PlutoColumn(
        title: 'Duty Mode',
        field: 'duty_mode',
        type: PlutoColumnType.select(['Flat Rate', 'WeBOC Cascade']),
        width: 130,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Duty Rate / Tax',
        field: 'duty_rate',
        type: PlutoColumnType.text(),
        width: 125,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Filer Status',
        field: 'is_filer',
        type: PlutoColumnType.select([
          'Filer (Normal WHT)',
          'Non-Filer (2x WHT)',
        ]),
        width: 155,
        enableEditingMode: true,
      ),

      // --- SKD LOCAL ASSEMBLY COLUMNS ---
      PlutoColumn(
        title: 'SKD Assembly',
        field: 'assembly_enabled',
        type: PlutoColumnType.select(['ON', 'OFF']),
        width: 120,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Local Box (PKR)',
        field: 'local_box',
        type: PlutoColumnType.text(),
        width: 125,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Labor (PKR)',
        field: 'labor_cost',
        type: PlutoColumnType.text(),
        width: 115,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Defect %',
        field: 'defect_pct',
        type: PlutoColumnType.text(),
        width: 95,
        enableEditingMode: true,
      ),

      // --- FROZEN RIGHT COLUMNS (FINANCIAL BOTTOM LINE) ---
      PlutoColumn(
        title: 'Unit Landed Cost (ULC)',
        field: 'unit_landed_cost',
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.end,
        readOnly: true,
        width: 160,
        renderer: (ctx) {
          return Center(
            child: Text(
              ctx.cell.value.toString(),
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Target Markup %',
        field: 'target_markup_pct',
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.end,
        width: 130,
        enableEditingMode: true,
      ),
      PlutoColumn(
        title: 'Selling Price (PKR)',
        field: 'selling_price',
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.end,
        width: 150,
        enableEditingMode: true, // Bidirectional: typing selling price reverse calculates margin!
        renderer: (ctx) {
          return Center(
            child: Text(
              ctx.cell.value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'Net Profit (PKR)',
        field: 'net_profit',
        type: PlutoColumnType.text(),
        frozen: PlutoColumnFrozen.end,
        readOnly: true,
        width: 150,
        renderer: (ctx) {
          final isOwner =
              ref.watch(userRoleProvider) == AppUserRole.ownerExecutive;
          if (!isOwner) {
            return const Center(
              child: Text(
                'LOCKED',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            );
          }
          final val = ctx.cell.value.toString();
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                val,
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }

  void _syncRowsFromState(List<ProductItem> items) {
    _rows.clear();
    for (final item in items) {
      final lineCalc = ref.read(calculatedLineItemProvider(item.id));
      _rows.add(
        PlutoRow(
          cells: {
            'item_id': PlutoCell(value: item.id),
            'name_sku': PlutoCell(value: '${item.name} (${item.modelNumber})'),
            'ordered_cartons': PlutoCell(value: item.orderedCartons.toString()),
            'pcs_per_carton': PlutoCell(value: item.piecesPerCarton.toString()),
            'total_pieces': PlutoCell(value: item.totalPieces.toString()),
            'carton_length': PlutoCell(value: item.cartonLength.toString()),
            'carton_width': PlutoCell(value: item.cartonWidth.toString()),
            'carton_height': PlutoCell(value: item.cartonHeight.toString()),
            'cbm_per_carton': PlutoCell(
              value: item.cbmPerCarton.toStringAsFixed(3),
            ),
            'total_line_cbm': PlutoCell(value: item.totalLineCbm),
            'gw_per_carton': PlutoCell(value: item.gwPerCartonKg.toString()),
            'unit_price_origin': PlutoCell(
              value: item.unitPriceOrigin.toString(),
            ),
            'origin_currency': PlutoCell(value: item.originCurrency),
            'duty_mode': PlutoCell(
              value: item.dutySpec.mode == DutyMode.flatRate
                  ? 'Flat Rate'
                  : 'WeBOC Cascade',
            ),
            'duty_rate': PlutoCell(
              value: item.dutySpec.mode == DutyMode.flatRate
                  ? item.dutySpec.flatRateAmount.toString()
                  : '${item.dutySpec.customsDutyPct}% CD',
            ),
            'is_filer': PlutoCell(
              value: item.dutySpec.isFiler
                  ? 'Filer (Normal WHT)'
                  : 'Non-Filer (2x WHT)',
            ),
            'assembly_enabled': PlutoCell(
              value: item.assemblySpec.isEnabled ? 'ON' : 'OFF',
            ),
            'local_box': PlutoCell(
              value: item.assemblySpec.localBoxCost.toString(),
            ),
            'labor_cost': PlutoCell(
              value: item.assemblySpec.technicianLaborCost.toString(),
            ),
            'defect_pct': PlutoCell(
              value: item.assemblySpec.defectWastagePct.toString(),
            ),
            'unit_landed_cost': PlutoCell(
              value: lineCalc != null
                  ? Formatters.pkr(lineCalc.unitLandedCost)
                  : '-',
            ),
            'target_markup_pct': PlutoCell(
              value: item.targetMarkupPct.toString(),
            ),
            'selling_price': PlutoCell(
              value: lineCalc != null
                  ? Formatters.pkr(lineCalc.projectedSellingPrice)
                  : '-',
            ),
            'net_profit': PlutoCell(
              value: lineCalc != null
                  ? '+${Formatters.pkr(lineCalc.projectedLineNetProfit)}'
                  : '-',
            ),
          },
        ),
      );
    }
  }

  void _onCellChanged(PlutoGridOnChangedEvent event) {
    final rowIdx = event.rowIdx;
    final items = ref.read(productItemsProvider);
    if (rowIdx >= items.length) return;

    final existing = items[rowIdx];
    final field = event.column.field;
    final dynamic rawValue = event.value;
    final String strValue = rawValue?.toString() ?? '';

    ProductItem updated = existing;

    // Inline formula evaluation helper
    final evaluatedNumber = FormulaEvaluator.tryEvaluate(strValue);

    switch (field) {
      case 'name_sku':
        updated = updated.copyWith(name: strValue);
        break;

      // --- 3-TIER PACKAGING RECIPROCAL SYNC ---
      case 'ordered_cartons':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(orderedCartons: evaluatedNumber.round());
        }
        break;

      case 'pcs_per_carton':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(piecesPerCarton: evaluatedNumber.round());
        }
        break;

      case 'total_pieces':
        // User typed total pieces -> back-calculate ordered cartons!
        if (evaluatedNumber != null &&
            evaluatedNumber > 0 &&
            existing.piecesPerCarton > 0) {
          final targetCartons = (evaluatedNumber / existing.piecesPerCarton)
              .ceil();
          updated = updated.copyWith(orderedCartons: targetCartons);
        }
        break;

      case 'carton_length':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(cartonLength: evaluatedNumber);
        }
        break;

      case 'carton_width':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(cartonWidth: evaluatedNumber);
        }
        break;

      case 'carton_height':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(cartonHeight: evaluatedNumber);
        }
        break;

      case 'cbm_per_carton':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(manualCbmOverride: evaluatedNumber);
        }
        break;

      case 'gw_per_carton':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(gwPerCartonKg: evaluatedNumber);
        }
        break;

      case 'unit_price_origin':
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(unitPriceOrigin: evaluatedNumber);
        }
        break;

      case 'origin_currency':
        updated = updated.copyWith(originCurrency: strValue);
        break;

      case 'duty_mode':
        final isFlat = strValue == 'Flat Rate';
        updated = updated.copyWith(
          dutySpec: updated.dutySpec.copyWith(
            mode: isFlat ? DutyMode.flatRate : DutyMode.statutoryCascade,
          ),
        );
        break;

      case 'duty_rate':
        if (evaluatedNumber != null) {
          if (updated.dutySpec.mode == DutyMode.flatRate) {
            updated = updated.copyWith(
              dutySpec: updated.dutySpec.copyWith(
                flatRateAmount: evaluatedNumber,
              ),
            );
          } else {
            updated = updated.copyWith(
              dutySpec: updated.dutySpec.copyWith(
                customsDutyPct: evaluatedNumber,
              ),
            );
          }
        }
        break;

      case 'is_filer':
        final isFiler =
            strValue.contains('Filer') && !strValue.contains('Non-Filer');
        updated = updated.copyWith(
          dutySpec: updated.dutySpec.copyWith(isFiler: isFiler),
        );
        break;

      case 'assembly_enabled':
        final isEnabled = strValue == 'ON';
        updated = updated.copyWith(
          assemblySpec: updated.assemblySpec.copyWith(isEnabled: isEnabled),
        );
        break;

      case 'local_box':
        if (evaluatedNumber != null) {
          updated = updated.copyWith(
            assemblySpec: updated.assemblySpec.copyWith(
              localBoxCost: evaluatedNumber,
            ),
          );
        }
        break;

      case 'labor_cost':
        if (evaluatedNumber != null) {
          updated = updated.copyWith(
            assemblySpec: updated.assemblySpec.copyWith(
              technicianLaborCost: evaluatedNumber,
            ),
          );
        }
        break;

      case 'defect_pct':
        if (evaluatedNumber != null) {
          updated = updated.copyWith(
            assemblySpec: updated.assemblySpec.copyWith(
              defectWastagePct: evaluatedNumber,
            ),
          );
        }
        break;

      // --- BIDIRECTIONAL PRICING ENGINE ---
      case 'target_markup_pct':
        if (evaluatedNumber != null) {
          updated = updated.copyWith(
            targetMarkupPct: evaluatedNumber,
            marketSellingPrice: null, // switch back to forward markup
          );
        }
        break;

      case 'selling_price':
        // User typed market selling price -> triggers reverse pricing!
        if (evaluatedNumber != null && evaluatedNumber > 0) {
          updated = updated.copyWith(marketSellingPrice: evaluatedNumber);
        }
        break;
    }

    ref.read(productItemsProvider.notifier).updateItem(updated);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(productItemsProvider);

    _syncRowsFromState(items);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PlutoGrid(
          columns: _columns,
          rows: _rows,
          onLoaded: (PlutoGridOnLoadedEvent event) {
            _stateManager = event.stateManager;
            _stateManager?.setSelectingMode(PlutoGridSelectingMode.cell);
          },
          onChanged: _onCellChanged,
          configuration: PlutoGridConfiguration(
            style: PlutoGridStyleConfig(
              gridBackgroundColor: const Color(0xFF090D16),
              rowColor: const Color(0xFF0F172A),
              oddRowColor: const Color(0xFF131D38),
              gridBorderColor: const Color(0xFF1E293B),
              borderColor: const Color(0xFF334155),
              columnTextStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              cellTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
              activatedColor: const Color(0xFF0284C7).withValues(alpha: 0.25),
              activatedBorderColor: const Color(0xFF38BDF8),
              menuBackgroundColor: const Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}
