import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/navigation_state.dart';
import '../views/audit_grid_view.dart';
import '../views/container_cms_view.dart';
import '../views/cost_pipeline_view.dart';
import '../views/dashboard_view.dart';
import '../views/order_items_view.dart';
import '../views/reports_export_view.dart';
import '../views/sourcing_sandbox_view.dart';
import '../widgets/dialogs/export_reports_dialog.dart';
import '../widgets/dialogs/fill_the_gap_dialog.dart';
import '../widgets/dialogs/paste_quote_dialog.dart';
import '../widgets/dialogs/product_edit_dialog.dart';
import '../widgets/sidebar/desktop_sidebar.dart';
import '../widgets/topbar/desktop_top_bar.dart';

class ImportCommandCenterScreen extends ConsumerStatefulWidget {
  const ImportCommandCenterScreen({super.key});

  @override
  ConsumerState<ImportCommandCenterScreen> createState() => _ImportCommandCenterScreenState();
}

class _ImportCommandCenterScreenState extends ConsumerState<ImportCommandCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeNavigationTabProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Row(
          children: [
            // 1. Fixed Left Desktop Sidebar
            DesktopSidebar(
              onAddProduct: () => _openAddProduct(context),
              onPasteQuote: () => _openPasteQuote(context),
              onOpenFillTheGap: () => _openFillTheGap(context),
            ),

            // 2. Right Workspace Area (Top Bar + Active Dedicated View)
            Expanded(
              child: Column(
                children: [
                  // Desktop Top Navigation Bar
                  DesktopTopBar(
                    onAddProduct: () => _openAddProduct(context),
                    onPasteQuote: () => _openPasteQuote(context),
                    onExport: () => _openExport(context),
                  ),

                  // Dedicated Workspace Views (No clutter, full screen real estate)
                  Expanded(
                    child: _buildActiveView(activeTab),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView(CommandNavigationTab tab) {
    switch (tab) {
      case CommandNavigationTab.dashboard:
        return DashboardView(
          onOpenFillTheGap: () => _openFillTheGap(context),
        );
      case CommandNavigationTab.auditGrid:
        return const AuditGridView();
      case CommandNavigationTab.orderItems:
        return const OrderItemsView();
      case CommandNavigationTab.container3D:
        return const ContainerCmsView();
      case CommandNavigationTab.costPipeline:
        return const CostPipelineView();
      case CommandNavigationTab.sourcingSandbox:
        return const SourcingSandboxView();
      case CommandNavigationTab.exports:
        return const ReportsExportView();
    }
  }

  // --- Modal Helpers ---
  void _openAddProduct(BuildContext context) {
    showDialog(context: context, builder: (_) => const ProductEditDialog());
  }

  void _openPasteQuote(BuildContext context) {
    showDialog(context: context, builder: (_) => const PasteQuoteDialog());
  }

  void _openFillTheGap(BuildContext context) {
    showDialog(context: context, builder: (_) => const FillTheGapDialog());
  }

  void _openExport(BuildContext context) {
    showDialog(context: context, builder: (_) => const ExportReportsDialog());
  }
}
