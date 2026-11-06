import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculation_results.dart';
import '../../../core/models/product_item.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/shipment_state.dart';

class ProductCard extends ConsumerWidget {
  final ProductItem item;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineCalc = ref.watch(calculatedLineItemProvider(item.id));
    final role = ref.watch(userRoleProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    if (lineCalc == null) return const SizedBox.shrink();

    // Cost percentages for the mini stacked ribbon
    final totalCost = lineCalc.totalLineCost > 0 ? lineCalc.totalLineCost : 1.0;
    final purPct = (lineCalc.purchaseBaseTotal / totalCost).clamp(0.0, 1.0);
    final logPct = (lineCalc.logisticsShareTotal / totalCost).clamp(0.0, 1.0);
    final dutyPct = (lineCalc.dutyBaseTotal / totalCost).clamp(0.0, 1.0);
    final assPct = (lineCalc.assemblyBaseTotal / totalCost).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lineCalc.doorwayCollision
              ? const Color(0xFFEF4444)
              : const Color(0xFF223154),
          width: lineCalc.doorwayCollision ? 1.8 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Row ---
            Row(
              children: [
                // Product Color Indicator / 3D Box Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.boxColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.boxColor.withOpacity(0.6)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: item.boxColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & SKU
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            child: Text(
                              item.modelNumber,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.stackingTier.label,
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (item.assemblySpec.isEnabled)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SKD ASSEMBLY',
                                  style: TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Supplier: ${item.supplierName}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Collision Warning Tag
                if (lineCalc.doorwayCollision)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Color(0xFFF87171),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Exceeds Doorway Height!',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action Menu
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  tooltip: 'Edit Item',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  tooltip: 'Duplicate Item',
                  onPressed: onDuplicate,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Remove Item',
                  onPressed: onDelete,
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 16),

            // --- 3 Visual Data Columns ---
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: [
                    // Col 1: Dimensions & Packing
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 40) / 3
                          : constraints.maxWidth,
                      child: _dimensionsColumn(item),
                    ),

                    // Col 2: Cost Anatomy
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 40) / 3
                          : constraints.maxWidth,
                      child: _costAnatomyColumn(item, lineCalc),
                    ),

                    // Col 3: Profit & Selling Engine
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 40) / 3
                          : constraints.maxWidth,
                      child: _profitColumn(
                        context,
                        ref,
                        item,
                        lineCalc,
                        isOwner,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // --- Cost Anatomy Ribbon ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cost Structure Breakdown',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Text(
                      'FOB ${(purPct * 100).toStringAsFixed(0)}% · Freight ${(logPct * 100).toStringAsFixed(0)}% · Duty ${(dutyPct * 100).toStringAsFixed(0)}% · Assembly ${(assPct * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Row(
                      children: [
                        Expanded(
                          flex: (purPct * 100).round(),
                          child: Container(color: const Color(0xFF3B82F6)),
                        ),
                        Expanded(
                          flex: (logPct * 100).round(),
                          child: Container(color: const Color(0xFF6366F1)),
                        ),
                        Expanded(
                          flex: (dutyPct * 100).round(),
                          child: Container(color: const Color(0xFFF59E0B)),
                        ),
                        Expanded(
                          flex: (assPct * 100).round(),
                          child: Container(color: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimensionsColumn(ProductItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DIMENSIONS & PACKAGING',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.aspect_ratio_rounded,
              size: 16,
              color: Color(0xFF38BDF8),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${item.cartonLength} × ${item.cartonWidth} × ${item.cartonHeight} ${item.dimensionUnit.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${item.cbmPerCarton.toStringAsFixed(3)} m³/ctn · ${item.gwPerCartonKg} kg GW',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.orderedCartons} Ctns (${item.totalPieces} Pcs)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Total: ${item.totalLineCbm.toStringAsFixed(1)} CBM',
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _costAnatomyColumn(ProductItem item, CalculatedLineItem lineCalc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COST ANATOMY (PER PIECE)',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        _costRow(
          'Origin FOB',
          '${item.originCurrency} ${item.unitPriceOrigin.toStringAsFixed(0)} (${Formatters.pkr(lineCalc.purchaseBasePerPiece)})',
          const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 4),
        _costRow(
          'Freight Share',
          Formatters.pkr(lineCalc.logisticsSharePerPiece),
          const Color(0xFF6366F1),
        ),
        const SizedBox(height: 4),
        _costRow(
          'Customs Duty',
          Formatters.pkr(lineCalc.dutyBasePerPiece),
          const Color(0xFFF59E0B),
        ),
        if (item.assemblySpec.isEnabled) ...[
          const SizedBox(height: 4),
          _costRow(
            'Local Value-Add',
            Formatters.pkr(lineCalc.assemblyBasePerPiece),
            const Color(0xFF10B981),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unit Landed Cost:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                Formatters.pkr(lineCalc.unitLandedCost),
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _costRow(String label, String value, Color dotColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _profitColumn(
    BuildContext context,
    WidgetRef ref,
    ProductItem item,
    CalculatedLineItem lineCalc,
    bool isOwner,
  ) {
    if (!isOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFIT & PRICING',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text(
                  'Hidden in Operator Mode',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final isHealthy = lineCalc.effectiveMarginPct >= 20.0;
    final badgeColor = isHealthy
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text(
              'PROFIT & SELLING ENGINE',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${lineCalc.effectiveMarginPct.toStringAsFixed(1)}% Margin',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selling Price:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                Formatters.pkr(lineCalc.projectedSellingPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Unit Net Profit:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '+${Formatters.pkr(lineCalc.projectedLineNetProfit / (lineCalc.sellablePieces > 0 ? lineCalc.sellablePieces : 1))}',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Line Total Profit:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '+${Formatters.pkr(lineCalc.projectedLineNetProfit)}',
                style: const TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
