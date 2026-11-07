import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/auth_state.dart';
import '../../../state/navigation_state.dart';
import '../../../state/shipment_state.dart';

class DesktopSidebar extends ConsumerWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onPasteQuote;
  final VoidCallback onOpenFillTheGap;

  const DesktopSidebar({
    super.key,
    required this.onAddProduct,
    required this.onPasteQuote,
    required this.onOpenFillTheGap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeNavigationTabProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final role = ref.watch(userRoleProvider);
    final rates = ref.watch(currencyRatesProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF0B132B),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Consumer(
                      builder: (context, ref, _) {
                        final authUser = ref.watch(authProvider).value;
                        final org = authUser?.activeOrganization;
                        final orgName = org?.name ?? '71 International';

                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '71 INTERNATIONAL // COMMAND ENGINE',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orgName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Equipment Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                container.name,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: totals.volumeUtilizationPct >= 90
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${totals.volumeUtilizationPct.toStringAsFixed(0)}% Vol',
                          style: TextStyle(
                            color: totals.volumeUtilizationPct >= 90 ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Navigation Items List (Scrollable if viewport is small)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'WORKSPACES',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                for (final tab in CommandNavigationTab.values)
                  _navTile(
                    tab: tab,
                    isSelected: activeTab == tab,
                    onTap: () => ref.read(activeNavigationTabProvider.notifier).state = tab,
                    badge: _buildTabBadge(tab, totals, items),
                  ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'QUICK COMMANDS',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                _actionButton(
                  icon: Icons.add_rounded,
                  label: 'Add Line Item',
                  accentColor: const Color(0xFF0284C7),
                  onTap: onAddProduct,
                ),
                const SizedBox(height: 4),
                _actionButton(
                  icon: Icons.content_paste_rounded,
                  label: 'Import Quote / Excel',
                  accentColor: const Color(0xFF818CF8),
                  onTap: onPasteQuote,
                ),
                const SizedBox(height: 4),
                _actionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Fill-The-Gap Engine',
                  accentColor: const Color(0xFF10B981),
                  onTap: onOpenFillTheGap,
                ),
              ],
            ),
          ),

          // 3. User Role Switcher (Owner Executive vs Operator Mode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF070B19),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCESS ROLE',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      Expanded(
                        child: _roleOption(
                          label: 'Owner Executive',
                          icon: Icons.admin_panel_settings_rounded,
                          isSelected: isOwner,
                          activeColor: const Color(0xFF0284C7),
                          onTap: () => ref.read(userRoleProvider.notifier).state = AppUserRole.ownerExecutive,
                        ),
                      ),
                      Expanded(
                        child: _roleOption(
                          label: 'Operator Mode',
                          icon: Icons.badge_outlined,
                          isSelected: !isOwner,
                          activeColor: const Color(0xFF475569),
                          onTap: () => ref.read(userRoleProvider.notifier).state = AppUserRole.internalOperator,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Live FX Mini Bar
                Row(
                  children: [
                    const Icon(Icons.currency_exchange_rounded, size: 12, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    const Text('FX:', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    if (rates.containsKey('RMB'))
                      Text(
                        '¥1=${rates['RMB']!.rateToBase.toStringAsFixed(1)}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                    const SizedBox(width: 6),
                    if (rates.containsKey('USD'))
                      Text(
                        '\$1=${rates['USD']!.rateToBase.toStringAsFixed(1)}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
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

  Widget _navTile({
    required CommandNavigationTab tab,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              tab.icon,
              size: 17,
              color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tab.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildTabBadge(
    CommandNavigationTab tab,
    dynamic totals,
    List<dynamic> items,
  ) {
    switch (tab) {
      case CommandNavigationTab.dashboard:
        if (totals.totalProjectedNetProfit > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${totals.overallMarginPct.toStringAsFixed(0)}%',
              style: const TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          );
        }
        return null;

      case CommandNavigationTab.auditGrid:
      case CommandNavigationTab.orderItems:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${items.length}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        );

      case CommandNavigationTab.container3D:
        if (totals.doorwayCollisionsCount > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '⚠️ Alert',
              style: TextStyle(color: Color(0xFFF87171), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          );
        }
        return null;

      case CommandNavigationTab.costPipeline:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '4 Stages',
            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9, fontWeight: FontWeight.bold),
          ),
        );

      default:
        return null;
    }
  }
}
