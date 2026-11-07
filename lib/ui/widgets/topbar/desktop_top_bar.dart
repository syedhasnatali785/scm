import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../../../engine/calculation_engine.dart';
import '../../../features/auth/auth_state.dart';
import '../../../state/navigation_state.dart';
import '../../../state/shipment_state.dart';

class DesktopTopBar extends ConsumerWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onPasteQuote;
  final VoidCallback onExport;

  const DesktopTopBar({
    super.key,
    required this.onAddProduct,
    required this.onPasteQuote,
    required this.onExport,
  });

  void _showCurrencyEditDialog(BuildContext context, WidgetRef ref) {
    final rates = ref.read(currencyRatesProvider);
    final rmbRate = rates['RMB']?.rateToBase ?? 39.20;
    final rmbBuffer = rates['RMB']?.safetyBufferPct ?? 1.5;
    final usdRate = rates['USD']?.rateToBase ?? 278.40;
    final usdBuffer = rates['USD']?.safetyBufferPct ?? 1.0;
    final aedRate = rates['AED']?.rateToBase ?? 75.80;
    final aedBuffer = rates['AED']?.safetyBufferPct ?? 1.0;
    final eurRate = rates['EUR']?.rateToBase ?? 302.50;
    final eurBuffer = rates['EUR']?.safetyBufferPct ?? 1.0;

    final rmbCtrl = TextEditingController(text: rmbRate.toStringAsFixed(2));
    final rmbBufCtrl = TextEditingController(text: rmbBuffer.toStringAsFixed(1));
    final usdCtrl = TextEditingController(text: usdRate.toStringAsFixed(2));
    final usdBufCtrl = TextEditingController(text: usdBuffer.toStringAsFixed(1));
    final aedCtrl = TextEditingController(text: aedRate.toStringAsFixed(2));
    final aedBufCtrl = TextEditingController(text: aedBuffer.toStringAsFixed(1));
    final eurCtrl = TextEditingController(text: eurRate.toStringAsFixed(2));
    final eurBufCtrl = TextEditingController(text: eurBuffer.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        title: const Row(
          children: [
            Icon(Icons.currency_exchange_rounded, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text(
              'Direct Currency Rate & Buffer Settings',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Direct manual exchange rates into base PKR (1 foreign currency unit = ? PKR). These rates will immediately recalculate all container economics.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
              const SizedBox(height: 16),
              _buildCurrencyRow('RMB / CNY (Chinese Yuan)', '¥', rmbCtrl, rmbBufCtrl),
              const SizedBox(height: 10),
              _buildCurrencyRow('USD (United States Dollar)', '\$', usdCtrl, usdBufCtrl),
              const SizedBox(height: 10),
              _buildCurrencyRow('AED (UAE Dirham)', 'AED', aedCtrl, aedBufCtrl),
              const SizedBox(height: 10),
              _buildCurrencyRow('EUR (Euro)', '€', eurCtrl, eurBufCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final notifier = ref.read(currencyRatesProvider.notifier);
              final rmb = double.tryParse(rmbCtrl.text);
              if (rmb != null && rmb > 0) {
                notifier.updateRate('RMB', rmb);
              }
              final rmbB = double.tryParse(rmbBufCtrl.text);
              if (rmbB != null) {
                notifier.updateBuffer('RMB', rmbB);
              }

              final usd = double.tryParse(usdCtrl.text);
              if (usd != null && usd > 0) {
                notifier.updateRate('USD', usd);
              }
              final usdB = double.tryParse(usdBufCtrl.text);
              if (usdB != null) {
                notifier.updateBuffer('USD', usdB);
              }

              final aed = double.tryParse(aedCtrl.text);
              if (aed != null && aed > 0) {
                notifier.updateRate('AED', aed);
              }
              final aedB = double.tryParse(aedBufCtrl.text);
              if (aedB != null) {
                notifier.updateBuffer('AED', aedB);
              }

              final eur = double.tryParse(eurCtrl.text);
              if (eur != null && eur > 0) {
                notifier.updateRate('EUR', eur);
              }
              final eurB = double.tryParse(eurBufCtrl.text);
              if (eurB != null) {
                notifier.updateBuffer('EUR', eurB);
              }

              Navigator.pop(ctx);
            },
            child: const Text('Apply Rates', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _buildCurrencyRow(
    String label,
    String symbol,
    TextEditingController rateCtrl,
    TextEditingController bufCtrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: rateCtrl,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '$symbol ',
                  prefixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: TextField(
                controller: bufCtrl,
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEraseAllData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Erase All Container Products?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SizedBox(
          width: 380,
          child: Text(
            'Are you sure you want to erase all products in this active shipment? This will wipe the loaded packing items so you can start a clean import. This action cannot be undone.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Erase All Data', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(productItemsProvider.notifier).clearAll();
              ref.read(shipmentViewModelProvider.notifier).clearAllItems();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All products erased successfully from container.'),
                  backgroundColor: Color(0xFF1E293B),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeNavigationTabProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final apportionmentMode = ref.watch(apportionmentModeProvider);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 1. Current Workspace Title & Subtitle
          Icon(activeTab.icon, size: 20, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeTab.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                activeTab.subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // 2. Middle & Right Controls (Safely scrollable if viewport width is narrow)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Real-time Status Badges (Doorway collision, Axle weight, Dead freight)
                  if (totals.doorwayCollisionsCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 13, color: Color(0xFFF87171)),
                          const SizedBox(width: 4),
                          Text(
                            '${totals.doorwayCollisionsCount} Doorway Alerts',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (totals.isOverweightAxle)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Text(
                        'Axle Limit Exceeded (+${Formatters.number(totals.excessAxleWeightKg.round())} kg)',
                        style: const TextStyle(
                          color: Color(0xFFF87171),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (totals.deadFreightCost > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Text(
                        'Dead Freight: ${Formatters.pkr(totals.deadFreightCost)}',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Apportionment Mode Selector
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ApportionmentMode>(
                        value: apportionmentMode,
                        dropdownColor: const Color(0xFF1E293B),
                        isDense: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF94A3B8), size: 16),
                        items: const [
                          DropdownMenuItem(
                            value: ApportionmentMode.targetCapacity,
                            child: Text('Rule: Usable Capacity'),
                          ),
                          DropdownMenuItem(
                            value: ApportionmentMode.actualLoad,
                            child: Text('Rule: Actual Load'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            ref
                                .read(apportionmentModeProvider.notifier)
                                .state = mode;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Editable Top Bar Currency Bar
                  Consumer(
                    builder: (context, ref, _) {
                      final rates = ref.watch(currencyRatesProvider);
                      final rmb = rates['RMB']?.rateToBase ?? 39.20;
                      final usd = rates['USD']?.rateToBase ?? 278.40;

                      return Tooltip(
                        message: 'Click to edit FX rates & safety buffers directly (No API)',
                        child: InkWell(
                          onTap: () => _showCurrencyEditDialog(context, ref),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.currency_exchange_rounded, size: 13, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  '¥ $rmb',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('|', style: TextStyle(color: Color(0xFF475569), fontSize: 11)),
                                const SizedBox(width: 6),
                                Text(
                                  '\$ $usd',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_rounded, size: 11, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Supabase Real-Time Cloud Status Badge
                  Consumer(
                    builder: (context, ref, _) {
                      final shipmentState =
                          ref.watch(shipmentViewModelProvider);
                      final status = shipmentState.syncStatus;
                      Color color;
                      IconData icon;
                      String label;

                      switch (status) {
                        case SyncStatus.synced:
                          color = const Color(0xFF10B981);
                          icon = Icons.cloud_done_rounded;
                          label = 'Synced';
                          break;
                        case SyncStatus.syncing:
                          color = const Color(0xFF38BDF8);
                          icon = Icons.cloud_sync_rounded;
                          label = 'Syncing...';
                          break;
                        case SyncStatus.offline:
                          color = const Color(0xFFF59E0B);
                          icon = Icons.cloud_off_rounded;
                          label = 'Offline';
                          break;
                        case SyncStatus.error:
                          color = const Color(0xFFEF4444);
                          icon = Icons.error_outline_rounded;
                          label = 'Error';
                          break;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Multi-Tenant Organization Switcher
                  Consumer(
                    builder: (context, ref, _) {
                      final authUser = ref.watch(authProvider).value;
                      final activeOrg = authUser?.activeOrganization;
                      final orgs = authUser?.organizations ?? [];

                      return PopupMenuButton<String>(
                        tooltip: 'Switch Tenant Organization',
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        onSelected: (orgId) {
                          ref
                              .read(authProvider.notifier)
                              .switchOrganization(orgId);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            enabled: false,
                            child: Text(
                              'TENANT ORGANIZATIONS',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          for (final org in orgs)
                            PopupMenuItem(
                              value: org.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    size: 15,
                                    color: org.id == activeOrg?.id
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      org.name,
                                      style: TextStyle(
                                        color: org.id == activeOrg?.id
                                            ? const Color(0xFF38BDF8)
                                            : Colors.white,
                                        fontWeight: org.id == activeOrg?.id
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (org.id == activeOrg?.id) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_rounded,
                                        size: 14, color: Color(0xFF38BDF8)),
                                  ],
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 13, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 130),
                                child: Text(
                                  activeOrg?.name ?? '71 International',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down_rounded,
                                  size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Quick Action CTA Buttons
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      minimumSize: const Size(36, 30),
                    ),
                    icon: const Icon(Icons.content_paste_rounded, size: 12),
                    label: const Text('Import',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: onPasteQuote,
                  ),
                  const SizedBox(width: 6),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF059669)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      minimumSize: const Size(36, 30),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 12),
                    label: const Text('Export',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: onExport,
                  ),
                  const SizedBox(width: 6),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      minimumSize: const Size(36, 30),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Add Item',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: onAddProduct,
                  ),
                  const SizedBox(width: 6),

                  // Erase All Data Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      minimumSize: const Size(36, 30),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                    label: const Text('Erase All',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmEraseAllData(context, ref),
                  ),
                  const SizedBox(width: 8),

                  // User Profile Avatar & Sign Out
                  Consumer(
                    builder: (context, ref, _) {
                      final authUser = ref.watch(authProvider).value;
                      final email = authUser?.email ?? 'User';
                      final initial =
                          email.isNotEmpty ? email[0].toUpperCase() : 'U';

                      return PopupMenuButton<String>(
                        tooltip: 'User Account & Sign Out',
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        onSelected: (val) {
                          if (val == 'signout') {
                            ref.read(authProvider.notifier).signOut();
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authUser?.name ?? 'Executive User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  authUser?.email ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (authUser?.role ?? 'owner').toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'signout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded,
                                    size: 15, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text(
                                  'Sign Out (Clear Session)',
                                  style: TextStyle(
                                    color: Color(0xFFF87171),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
