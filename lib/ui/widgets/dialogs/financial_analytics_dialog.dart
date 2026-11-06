import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculation_results.dart';
import '../../../core/models/cost_node.dart';
import '../../../core/utils/formatters.dart';
import '../../../engine/calculation_engine.dart';
import '../../../state/shipment_state.dart';

class FinancialAnalyticsDialog extends ConsumerStatefulWidget {
  const FinancialAnalyticsDialog({super.key});

  @override
  ConsumerState<FinancialAnalyticsDialog> createState() =>
      _FinancialAnalyticsDialogState();
}

class _FinancialAnalyticsDialogState
    extends ConsumerState<FinancialAnalyticsDialog> {
  // Sensitivity Sliders State
  double _rmbShockPct = 0.0; // -15% to +25%
  double _usdShockPct = 0.0; // -15% to +25%
  int _demurrageDays = 0; // 0 to 21 days
  final double _demurragePerDayUsd =
      120.0; // Standard container demurrage/detention
  double _haulageSurchargePct = 0.0; // 0% to +30%

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
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final costNodes = ref.watch(costNodesProvider);
    final rates = ref.watch(currencyRatesProvider);
    final mode = ref.watch(apportionmentModeProvider);

    // 1. Calculate Base Financials
    final baseTotals = CalculationEngine.calculate(
      items: items,
      container: container,
      costNodes: costNodes,
      currencyRates: rates,
      apportionmentMode: mode,
    );

    // 2. Build Stressed Rates & Stressed Cost Nodes for "What-If" Sensitivity Simulation
    final stressedRates = Map<String, dynamic>.from(rates);
    final baseRmb = rates['RMB']?.effectiveRate ?? 39.20;
    final stressedRmbRate = baseRmb * (1.0 + (_rmbShockPct / 100.0));
    final baseUsd = rates['USD']?.effectiveRate ?? 278.50;
    final stressedUsdRate = baseUsd * (1.0 + (_usdShockPct / 100.0));

    if (stressedRates.containsKey('RMB')) {
      stressedRates['RMB'] = stressedRates['RMB']!.copyWith(
        rateToBase: stressedRmbRate,
      );
    }
    if (stressedRates.containsKey('USD')) {
      stressedRates['USD'] = stressedRates['USD']!.copyWith(
        rateToBase: stressedUsdRate,
      );
    }

    // Add Demurrage & Haulage Shock to Cost Nodes
    final stressedNodes = <CostNode>[...costNodes];
    if (_demurrageDays > 0) {
      final totalDemurrageUsd = _demurrageDays * _demurragePerDayUsd;
      stressedNodes.add(
        CostNode(
          id: 'sim_demurrage',
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
          stressedNodes[i] = n.copyWith(
            amount: n.amount * (1.0 + (_haulageSurchargePct / 100.0)),
          );
        }
      }
    }

    // 3. Calculate Stressed Sensitivity Financials
    final stressedTotals = CalculationEngine.calculate(
      items: items,
      container: container,
      costNodes: stressedNodes,
      currencyRates: rates.map((k, v) {
        if (k == 'RMB') {
          return MapEntry(k, v.copyWith(rateToBase: stressedRmbRate));
        }
        if (k == 'USD') {
          return MapEntry(k, v.copyWith(rateToBase: stressedUsdRate));
        }
        return MapEntry(k, v);
      }),
      apportionmentMode: mode,
    );

    // Profit Deltas
    final profitDelta =
        stressedTotals.totalProjectedNetProfit -
        baseTotals.totalProjectedNetProfit;
    final marginDelta =
        stressedTotals.overallMarginPct - baseTotals.overallMarginPct;
    final landedCostDelta =
        stressedTotals.totalLandedCostBase - baseTotals.totalLandedCostBase;

    // Breakeven Currency Calculation (RMB rate where Net Profit == 0)
    // Profit = Revenue - LandedCost = 0  =>  Revenue = OtherCosts + TotalRmb * breakevenRate
    double breakevenRmbRate = 0.0;
    double totalFobRmb = 0.0;
    for (final it in items) {
      if (it.originCurrency == 'RMB') {
        totalFobRmb += it.totalPieces * it.unitPriceOrigin;
      }
    }
    if (totalFobRmb > 0) {
      final nonRmbCosts =
          stressedTotals.totalLogisticsCostBase +
          stressedTotals.totalDutyCostBase +
          stressedTotals.totalAssemblyCostBase;
      final maxAffordableRmbTotal =
          baseTotals.totalProjectedRevenue - nonRmbCosts;
      if (maxAffordableRmbTotal > 0) {
        breakevenRmbRate = maxAffordableRmbTotal / totalFobRmb;
      }
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(
            Icons.waterfall_chart_rounded,
            color: Color(0xFF38BDF8),
            size: 24,
          ),
          const SizedBox(width: 10),
          const Text(
            'Executive Waterfall & Sensitivity Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
            label: const Text(
              'Reset Sliders',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            onPressed: _resetSliders,
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top KPI Cards: Base vs Stressed Scenario
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      title: 'TOTAL LANDED INVESTMENT',
                      baseVal: Formatters.pkr(baseTotals.totalLandedCostBase),
                      stressedVal: Formatters.pkr(
                        stressedTotals.totalLandedCostBase,
                      ),
                      deltaStr:
                          '${landedCostDelta >= 0 ? '+' : ''}${Formatters.pkr(landedCostDelta)}',
                      isPositiveDeltaGood: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      title: 'PROJECTED NET PROFIT',
                      baseVal: Formatters.pkr(
                        baseTotals.totalProjectedNetProfit,
                      ),
                      stressedVal: Formatters.pkr(
                        stressedTotals.totalProjectedNetProfit,
                      ),
                      deltaStr:
                          '${profitDelta >= 0 ? '+' : ''}${Formatters.pkr(profitDelta)}',
                      isPositiveDeltaGood: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      title: 'NET MARGIN %',
                      baseVal:
                          '${baseTotals.overallMarginPct.toStringAsFixed(1)}%',
                      stressedVal:
                          '${stressedTotals.overallMarginPct.toStringAsFixed(1)}%',
                      deltaStr:
                          '${marginDelta >= 0 ? '+' : ''}${marginDelta.toStringAsFixed(1)}%',
                      isPositiveDeltaGood: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      title: 'BREAKEVEN RMB FX',
                      baseVal: '¥ 1 = Rs ${baseRmb.toStringAsFixed(2)}',
                      stressedVal:
                          'Limit: Rs ${breakevenRmbRate.toStringAsFixed(2)}',
                      deltaStr: breakevenRmbRate > baseRmb
                          ? '+${((breakevenRmbRate - baseRmb) / baseRmb * 100).toStringAsFixed(1)}% buffer'
                          : 'Underwater!',
                      isPositiveDeltaGood: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Executive Waterfall Chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF223154)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FINANCIAL WATERFALL: COST ACCUMULATION TO NET PROFIT',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'All figures in PKR (₨)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildWaterfallBarChart(stressedTotals),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section: Interactive "What-If" Sensitivity Sliders
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF223154)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: Color(0xFF38BDF8),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'INTERACTIVE STRESS-TEST & CONTINGENCY SLIDERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slider 1: RMB / PKR Currency Devaluation Shock
                    _sliderRow(
                      label: 'RMB / PKR Currency Shock (China Factory Cost)',
                      valueLabel:
                          '${_rmbShockPct >= 0 ? '+' : ''}${_rmbShockPct.toStringAsFixed(1)}% (Rate: Rs ${stressedRmbRate.toStringAsFixed(2)})',
                      value: _rmbShockPct,
                      min: -15.0,
                      max: 25.0,
                      divisions: 40,
                      accentColor: const Color(0xFFEF4444),
                      onChanged: (v) => setState(() => _rmbShockPct = v),
                    ),
                    const SizedBox(height: 10),

                    // Slider 2: USD / PKR Ocean Freight Rate Shock
                    _sliderRow(
                      label: 'USD / PKR Freight Rate Shock (International Shipping)',
                      valueLabel:
                          '${_usdShockPct >= 0 ? '+' : ''}${_usdShockPct.toStringAsFixed(1)}% (Rate: Rs ${stressedUsdRate.toStringAsFixed(2)})',
                      value: _usdShockPct,
                      min: -15.0,
                      max: 25.0,
                      divisions: 40,
                      accentColor: const Color(0xFF38BDF8),
                      onChanged: (v) => setState(() => _usdShockPct = v),
                    ),
                    const SizedBox(height: 10),

                    // Slider 3: Port Demurrage Contingency (Days)
                    _sliderRow(
                      label: 'Port Demurrage & Detention Delay Contingency',
                      valueLabel:
                          '$_demurrageDays Days (\$${(_demurrageDays * _demurragePerDayUsd).toStringAsFixed(0)} USD)',
                      value: _demurrageDays.toDouble(),
                      min: 0.0,
                      max: 21.0,
                      divisions: 21,
                      accentColor: const Color(0xFFF59E0B),
                      onChanged: (v) =>
                          setState(() => _demurrageDays = v.round()),
                    ),
                    const SizedBox(height: 10),

                    // Slider 4: Upcountry Haulage & Fuel Surcharge
                    _sliderRow(
                      label: 'Domestic Inland Haulage & Diesel Fuel Surcharge',
                      valueLabel:
                          '+${_haulageSurchargePct.toStringAsFixed(0)}% Surcharge',
                      value: _haulageSurchargePct,
                      min: 0.0,
                      max: 30.0,
                      divisions: 30,
                      accentColor: const Color(0xFF8B5CF6),
                      onChanged: (v) =>
                          setState(() => _haulageSurchargePct = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
          ),
          onPressed: () {
            // Apply stressed rates to live workspace
            ref
                .read(currencyRatesProvider.notifier)
                .updateRate('RMB', stressedRmbRate);
            ref
                .read(currencyRatesProvider.notifier)
                .updateRate('USD', stressedUsdRate);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Applied stressed rates (RMB: Rs ${stressedRmbRate.toStringAsFixed(2)}, USD: Rs ${stressedUsdRate.toStringAsFixed(2)}) to workspace!',
                ),
                backgroundColor: const Color(0xFF0284C7),
              ),
            );
          },
          child: const Text(
            'Lock Scenario into Live Workspace',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String baseVal,
    required String stressedVal,
    required String deltaStr,
    required bool isPositiveDeltaGood,
  }) {
    final isDeltaGood = isPositiveDeltaGood
        ? !deltaStr.contains('-')
        : deltaStr.contains('-');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stressedVal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base: $baseVal',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
              ),
              Text(
                deltaStr,
                style: TextStyle(
                  color: isDeltaGood
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: accentColor,
            inactiveTrackColor: const Color(0xFF334155),
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterfallBarChart(CalculatedShipmentTotals totals) {
    final stages = [
      {
        'name': '1. FOB Purchase',
        'amount': totals.totalPurchaseCostBase,
        'color': const Color(0xFF38BDF8),
      },
      {
        'name': '2. Ocean/Air Freight',
        'amount': totals.totalLogisticsCostBase,
        'color': const Color(0xFF6366F1),
      },
      {
        'name': '3. Customs & WeBOC',
        'amount': totals.totalDutyCostBase,
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': '4. Assembly & Haulage',
        'amount': totals.totalAssemblyCostBase,
        'color': const Color(0xFFEC4899),
      },
      {
        'name': '5. Total Landed Cost',
        'amount': totals.totalLandedCostBase,
        'color': const Color(0xFF0284C7),
        'isTotal': true,
      },
      {
        'name': '6. Net Profit Margin',
        'amount': math.max(0.0, totals.totalProjectedNetProfit),
        'color': const Color(0xFF10B981),
        'isNet': true,
      },
    ];

    final maxVal = math.max(
      totals.totalProjectedRevenue,
      totals.totalLandedCostBase * 1.2,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: stages.map((st) {
            final double amount = (st['amount'] as num).toDouble();
            final double pct = maxVal > 0
                ? (amount / maxVal).clamp(0.0, 1.0)
                : 0.0;
            final Color color = st['color'] as Color;
            final bool isTotal = st['isTotal'] == true;
            final bool isNet = st['isNet'] == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      st['name'] as String,
                      style: TextStyle(
                        color: isTotal || isNet
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: isTotal || isNet
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: Text(
                      Formatters.pkr(amount),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isNet
                            ? const Color(0xFF34D399)
                            : (isTotal
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
