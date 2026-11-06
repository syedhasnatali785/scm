import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/calculation_results.dart';
import '../../../core/utils/formatters.dart';
import '../../../state/shipment_state.dart';

class ExecutiveHUD extends ConsumerWidget {
  final VoidCallback onOpenFillTheGap;

  const ExecutiveHUD({super.key, required this.onOpenFillTheGap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(calculatedTotalsProvider);
    final role = ref.watch(userRoleProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation & Role Toggle
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              // Logo & Workspace Tag
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Color(0xFF38BDF8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '71 INTERNATIONAL // COMMAND ENGINE',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Active Container Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text(
                              'WEB BASED ONLINE PORTAL',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Role Toggle (Owner Executive vs Internal Operator)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roleButton(
                      ref: ref,
                      targetRole: AppUserRole.ownerExecutive,
                      currentRole: role,
                      label: 'Owner Executive',
                      icon: Icons.admin_panel_settings_rounded,
                      activeColor: const Color(0xFF0284C7),
                    ),
                    _roleButton(
                      ref: ref,
                      targetRole: AppUserRole.internalOperator,
                      currentRole: role,
                      label: 'Operator Mode',
                      icon: Icons.badge_outlined,
                      activeColor: const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4 Visual KPI Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpiCard(
                    width: isWide
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2,
                    title: 'TOTAL LANDED INVESTMENT',
                    value: Formatters.pkr(totals.totalLandedCostBase),
                    subtitle:
                        '${totals.totalPieces} Pcs across ${totals.totalCartons} Cartons',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF38BDF8),
                  ),
                  _kpiCard(
                    width: isWide
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2,
                    title: 'PROJECTED NET PROFIT',
                    value: isOwner
                        ? '+${Formatters.pkr(totals.totalProjectedNetProfit)}'
                        : '*** CONFIDENTIAL ***',
                    subtitle: isOwner
                        ? '${totals.overallMarginPct.toStringAsFixed(1)}% Net Margin · ${totals.overallRoiPct.toStringAsFixed(1)}% ROI'
                        : 'Locked by Company Owner',
                    icon: isOwner
                        ? Icons.trending_up_rounded
                        : Icons.lock_rounded,
                    accentColor: isOwner
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                    badge: isOwner && totals.totalProjectedNetProfit > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${totals.overallMarginPct.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  _containerUtilizationCard(
                    width: isWide
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2,
                    totals: totals,
                  ),
                  _costRibbonCard(
                    width: isWide
                        ? (constraints.maxWidth - 48) / 4
                        : (constraints.maxWidth - 16) / 2,
                    totals: totals,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleButton({
    required WidgetRef ref,
    required AppUserRole targetRole,
    required AppUserRole currentRole,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = targetRole == currentRole;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => ref.read(userRoleProvider.notifier).state = targetRole,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _containerUtilizationCard({
    required double width,
    required CalculatedShipmentTotals totals,
  }) {
    final pct = (totals.volumeUtilizationPct / 100.0).clamp(0.0, 1.0);
    final hasSpace = totals.remainingCbm > 1.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONTAINER UTILIZATION',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${totals.volumeUtilizationPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: totals.volumeUtilizationPct >= 90
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF59E0B),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(
                totals.volumeUtilizationPct >= 90
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${totals.totalCbm.toStringAsFixed(1)} / ${totals.containerUsableCbm.toStringAsFixed(1)} CBM',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasSpace && totals.topUpRecommendations.isNotEmpty)
                InkWell(
                  onTap: onOpenFillTheGap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.6),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Fill The Gap',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (totals.isOverweightAxle) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFD97706)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.scale_rounded, size: 12, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Axle Overload: +${totals.excessAxleWeightKg.toStringAsFixed(0)} kg over ${totals.roadAxleLimitKg.toStringAsFixed(0)} kg',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 9.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
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

  Widget _costRibbonCard({
    required double width,
    required CalculatedShipmentTotals totals,
  }) {
    final totalCost = totals.totalLandedCostBase > 0
        ? totals.totalLandedCostBase
        : 1.0;
    final purPct = (totals.totalPurchaseCostBase / totalCost).clamp(0.0, 1.0);
    final logPct = (totals.totalLogisticsCostBase / totalCost).clamp(0.0, 1.0);
    final dutyPct = (totals.totalDutyCostBase / totalCost).clamp(0.0, 1.0);
    final assPct = (totals.totalAssemblyCostBase / totalCost).clamp(0.0, 1.0);

    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COST ANATOMY COMPOSITION',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          // Multi-color Stacked Ribbon
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _legendDot(
                color: const Color(0xFF3B82F6),
                label: 'Purchase ${(purPct * 100).toStringAsFixed(0)}%',
              ),
              _legendDot(
                color: const Color(0xFF6366F1),
                label: 'Freight ${(logPct * 100).toStringAsFixed(0)}%',
              ),
              _legendDot(
                color: const Color(0xFFF59E0B),
                label: 'Duty ${(dutyPct * 100).toStringAsFixed(0)}%',
              ),
              _legendDot(
                color: const Color(0xFF10B981),
                label: 'Assy ${(assPct * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }
}
