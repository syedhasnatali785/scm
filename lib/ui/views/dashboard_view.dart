import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/calculation_results.dart';
import '../../core/models/cost_node.dart';
import '../../core/utils/formatters.dart';
import '../../engine/calculation_engine.dart';
import '../../state/shipment_state.dart';

class DashboardView extends ConsumerStatefulWidget {
  final VoidCallback onOpenFillTheGap;

  const DashboardView({super.key, required this.onOpenFillTheGap});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  // Sensitivity Sliders State
  double _rmbShockPct = 0.0;
  double _usdShockPct = 0.0;
  int _demurrageDays = 0;
  final double _demurragePerDayUsd = 120.0;
  double _haulageSurchargePct = 0.0;

  void _resetSliders() {
    setState(() {
      _rmbShockPct = 0.0;
      _usdShockPct = 0.0;
      _demurrageDays = 0;
      _haulageSurchargePct = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(calculatedTotalsProvider);
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final role = ref.watch(userRoleProvider);
    final rates = ref.watch(currencyRatesProvider);
    final costNodes = ref.watch(costNodesProvider);
    final apportionmentMode = ref.watch(apportionmentModeProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    // Stressed calculations for Sensitivity Sliders
    final stressedCurrencies = Map<String, dynamic>.from(rates);
    if (rates.containsKey('RMB')) {
      final rmb = rates['RMB']!;
      stressedCurrencies['RMB'] = rmb.copyWith(
        rateToBase: rmb.rateToBase * (1.0 + (_rmbShockPct / 100.0)),
      );
    }
    if (rates.containsKey('USD')) {
      final usd = rates['USD']!;
      stressedCurrencies['USD'] = usd.copyWith(
        rateToBase: usd.rateToBase * (1.0 + (_usdShockPct / 100.0)),
      );
    }

    final stressedNodes = List<CostNode>.from(costNodes);
    if (_demurrageDays > 0) {
      final totalDemurrageUsd = _demurrageDays * _demurragePerDayUsd;
      stressedNodes.add(
        CostNode(
          id: 'demurrage_stress',
          name: 'Port Demurrage & Detention ($_demurrageDays Days)',
          stage: CostStage.clearance,
          amount: totalDemurrageUsd,
          currencyCode: 'USD',
          allocationRule: ApportionmentRule.byCbm,
        ),
      );
    }

    if (_haulageSurchargePct > 0) {
      for (int i = 0; i < stressedNodes.length; i++) {
        if (stressedNodes[i].stage == CostStage.localDelivery) {
          final n = stressedNodes[i];
          stressedNodes[i] = n.copyWith(amount: n.amount * (1.0 + (_haulageSurchargePct / 100.0)));
        }
      }
    }

    final stressedTotals = CalculationEngine.calculate(
      items: items,
      container: container,
      costNodes: stressedNodes,
      currencyRates: stressedCurrencies.cast(),
      apportionmentMode: apportionmentMode,
    );

    // Break-even RMB rate
    final baselineRmbRate = rates['RMB']?.rateToBase ?? 38.6;
    double? breakEvenRmbRate;
    if (totals.totalPurchaseCostBase > 0 && totals.totalProjectedNetProfit > 0) {
      final profitBuffer = totals.totalProjectedNetProfit;
      final totalFobOrigin = items.fold(0.0, (sum, i) => sum + (i.totalPieces * i.unitPriceOrigin));
      if (totalFobOrigin > 0) {
        breakEvenRmbRate = baselineRmbRate + (profitBuffer / totalFobOrigin);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Primary Executive KPI Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard(
                    width: cardWidth,
                    title: 'TOTAL LANDED INVESTMENT',
                    value: Formatters.pkr(totals.totalLandedCostBase),
                    subtitle: '${totals.totalPieces} Pcs across ${totals.totalCartons} Cartons',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF38BDF8),
                  ),
                  _kpiCard(
                    width: cardWidth,
                    title: 'PROJECTED NET PROFIT',
                    value: isOwner ? '+${Formatters.pkr(totals.totalProjectedNetProfit)}' : '*** CONFIDENTIAL ***',
                    subtitle: isOwner
                        ? '${totals.overallMarginPct.toStringAsFixed(1)}% Net Margin · ${totals.overallRoiPct.toStringAsFixed(1)}% ROI'
                        : 'Locked by Company Owner',
                    icon: isOwner ? Icons.trending_up_rounded : Icons.lock_rounded,
                    accentColor: isOwner ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    badge: isOwner && totals.totalProjectedNetProfit > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${totals.overallMarginPct.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        : null,
                  ),
                  _kpiCard(
                    width: cardWidth,
                    title: 'CONTAINER VOLUME FILL',
                    value: '${totals.totalCbm.toStringAsFixed(1)} / ${totals.containerUsableCbm.toStringAsFixed(1)} CBM',
                    subtitle: '${totals.volumeUtilizationPct.toStringAsFixed(1)}% Usable Fill (${totals.remainingCbm.toStringAsFixed(1)} m³ free)',
                    icon: Icons.grid_view_rounded,
                    accentColor: totals.volumeUtilizationPct >= 90 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    actionLabel: totals.remainingCbm > 0.5 ? 'Fill-The-Gap' : null,
                    onAction: widget.onOpenFillTheGap,
                  ),
                  _kpiCard(
                    width: cardWidth,
                    title: 'DEAD FREIGHT / VOID RISK',
                    value: totals.deadFreightCost > 0 ? Formatters.pkr(totals.deadFreightCost) : 'Optimal (0 PKR)',
                    subtitle: totals.deadFreightCost > 0 ? 'Cost of unused air capacity' : '100% container load efficiency',
                    icon: totals.deadFreightCost > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    accentColor: totals.deadFreightCost > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 2. Middle Row: Waterfall Cost Breakdown + Container Stacking Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1050;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Waterfall Visualizer (Flex 6)
                    Expanded(
                      flex: 6,
                      child: _buildWaterfallCard(totals),
                    ),
                    const SizedBox(width: 20),
                    // Right: Container Stacking & Axle Status (Flex 4)
                    Expanded(
                      flex: 4,
                      child: _buildEquipmentSpecsCard(totals, container),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildWaterfallCard(totals),
                    const SizedBox(height: 20),
                    _buildEquipmentSpecsCard(totals, container),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // 3. Bottom Row: Interactive "What-If" Sensitivity Sliders & Stress Testing
          _buildSensitivityStressCard(totals, stressedTotals, baselineRmbRate, breakEvenRmbRate),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    Widget? badge,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (badge != null)
                badge
              else if (actionLabel != null && onAction != null)
                InkWell(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF0284C7)),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Icon(icon, size: 18, color: accentColor.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallCard(CalculatedShipmentTotals totals) {
    final stages = [
      {'name': '1. FOB Purchase', 'amount': totals.totalPurchaseCostBase, 'color': const Color(0xFF38BDF8)},
      {'name': '2. Ocean/Air Freight', 'amount': totals.totalLogisticsCostBase, 'color': const Color(0xFF6366F1)},
      {'name': '3. Customs & WeBOC', 'amount': totals.totalDutyCostBase, 'color': const Color(0xFFF59E0B)},
      {'name': '4. Assembly & Haulage', 'amount': totals.totalAssemblyCostBase, 'color': const Color(0xFFEC4899)},
      {'name': '5. Total Landed Cost', 'amount': totals.totalLandedCostBase, 'color': const Color(0xFF0284C7), 'isTotal': true},
      {'name': '6. Net Profit Margin', 'amount': math.max(0.0, totals.totalProjectedNetProfit), 'color': const Color(0xFF10B981), 'isNet': true},
    ];

    final maxVal = math.max(totals.totalProjectedRevenue, totals.totalLandedCostBase * 1.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.waterfall_chart_rounded, size: 18, color: Color(0xFF38BDF8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EXECUTIVE WATERFALL COST & PROFIT ANATOMY',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Revenue: ${Formatters.pkr(totals.totalProjectedRevenue)}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waterfall Bars
          for (final stage in stages) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stage['name'] as String,
                        style: TextStyle(
                          color: (stage['isTotal'] == true || stage['isNet'] == true) ? Colors.white : const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: (stage['isTotal'] == true || stage['isNet'] == true) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        Formatters.pkr((stage['amount'] as double)),
                        style: TextStyle(
                          color: stage['color'] as Color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: (stage['isTotal'] == true || stage['isNet'] == true) ? 10 : 8,
                      width: double.infinity,
                      color: const Color(0xFF1E293B),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: maxVal > 0 ? math.min(1.0, (stage['amount'] as double) / maxVal) : 0.0,
                        child: Container(color: stage['color'] as Color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentSpecsCard(CalculatedShipmentTotals totals, dynamic container) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF38BDF8)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EQUIPMENT UTILIZATION & AXLE METER',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  container.name,
                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Volume Utilization Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Volume Fill Rate', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              Text(
                '${totals.totalCbm.toStringAsFixed(1)} / ${totals.containerUsableCbm.toStringAsFixed(1)} CBM (${totals.volumeUtilizationPct.toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: math.min(1.0, totals.volumeUtilizationPct / 100.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(
                totals.volumeUtilizationPct >= 90 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Road Axle Weight Meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Road Axle Payload', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              Text(
                '${Formatters.number(totals.totalGrossWeightKg.round())} / ${Formatters.number(totals.roadAxleLimitKg.round())} kg (${totals.payloadUtilizationPct.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: totals.isOverweightAxle ? const Color(0xFFEF4444) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: math.min(1.0, totals.payloadUtilizationKgRatio),
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(
                totals.isOverweightAxle ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Doorway collision indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: totals.doorwayCollisionsCount > 0
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: totals.doorwayCollisionsCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  totals.doorwayCollisionsCount > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: totals.doorwayCollisionsCount > 0 ? const Color(0xFFF87171) : const Color(0xFF34D399),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totals.doorwayCollisionsCount > 0
                        ? '${totals.doorwayCollisionsCount} Doorway Height Collisions Detected'
                        : 'Doorway Height Clearance Validated (${container.doorHeightCm.toStringAsFixed(0)} cm)',
                    style: TextStyle(
                      color: totals.doorwayCollisionsCount > 0 ? const Color(0xFFF87171) : const Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityStressCard(
    CalculatedShipmentTotals base,
    CalculatedShipmentTotals stressed,
    double baselineRmbRate,
    double? breakEvenRmbRate,
  ) {
    final profitDelta = stressed.totalProjectedNetProfit - base.totalProjectedNetProfit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: Color(0xFFF59E0B)),
                  SizedBox(width: 8),
                  Text(
                    'INTERACTIVE "WHAT-IF" SENSITIVITY SLIDERS & CONTINGENCY MODEL',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 26),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 12),
                label: const Text('Reset Sliders', style: TextStyle(fontSize: 10)),
                onPressed: _resetSliders,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sliders Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final colWidth = isWide ? (constraints.maxWidth - 40) / 3 : constraints.maxWidth;

              return Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  // Slider 1: RMB Shock
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('RMB Currency Shock', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              '${_rmbShockPct >= 0 ? "+" : ""}${_rmbShockPct.toStringAsFixed(1)}% (PKR ${(baselineRmbRate * (1 + _rmbShockPct / 100)).toStringAsFixed(2)})',
                              style: TextStyle(
                                color: _rmbShockPct > 0 ? const Color(0xFFEF4444) : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF38BDF8),
                            thumbColor: const Color(0xFF38BDF8),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _rmbShockPct,
                            min: -15.0,
                            max: 25.0,
                            divisions: 40,
                            onChanged: (val) => setState(() => _rmbShockPct = val),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slider 2: Port Demurrage
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Port Demurrage / Detention', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              '$_demurrageDays Days (\$${(_demurrageDays * _demurragePerDayUsd).round()})',
                              style: TextStyle(
                                color: _demurrageDays > 0 ? const Color(0xFFEF4444) : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFF59E0B),
                            thumbColor: const Color(0xFFF59E0B),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _demurrageDays.toDouble(),
                            min: 0,
                            max: 21,
                            divisions: 21,
                            onChanged: (val) => setState(() => _demurrageDays = val.round()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slider 3: Inland Haulage Surcharge
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Haulage Fuel Surcharge', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              '+${_haulageSurchargePct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _haulageSurchargePct > 0 ? const Color(0xFFEF4444) : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF10B981),
                            thumbColor: const Color(0xFF10B981),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _haulageSurchargePct,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            onChanged: (val) => setState(() => _haulageSurchargePct = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Stress Results Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Stressed Net Profit: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text(
                      Formatters.pkr(stressed.totalProjectedNetProfit),
                      style: TextStyle(
                        color: stressed.totalProjectedNetProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${profitDelta >= 0 ? "+" : ""}${Formatters.pkr(profitDelta)})',
                      style: TextStyle(
                        color: profitDelta >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (breakEvenRmbRate != null)
                  Row(
                    children: [
                      const Text('Break-Even RMB Rate: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      Text(
                        '¥ 1.0 = PKR ${breakEvenRmbRate.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on CalculatedShipmentTotals {
  double get payloadUtilizationKgRatio =>
      roadAxleLimitKg > 0 ? (totalGrossWeightKg / roadAxleLimitKg) : 0.0;
}
