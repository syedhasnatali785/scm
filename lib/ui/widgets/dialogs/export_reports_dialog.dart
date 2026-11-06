import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/calculation_results.dart';
import '../../../core/services/report_generator.dart';
import '../../../state/shipment_state.dart';

class ExportReportsDialog extends ConsumerWidget {
  const ExportReportsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final role = ref.watch(userRoleProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    // Pre-calculate line calculations for all items
    final calculatedLines = <String, CalculatedLineItem?>{};
    for (final item in items) {
      calculatedLines[item.id] = ref.watch(calculatedLineItemProvider(item.id));
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.download_rounded, color: Color(0xFF38BDF8), size: 22),
          SizedBox(width: 10),
          Text(
            'Sanitized Document & Report Generator',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select export format. Third-party documents automatically sanitize internal margins, bank figures, and confidential clearance rates:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Report 1: Owner's Complete Financial Audit
              _reportCard(
                context: context,
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: "1. Owner's Complete Financial Audit & Landed Cost Sheet",
                subtitle: 'Full CIF cost breakdown, customs tax cascade, FX safety buffers, and net profit margins across all SKUs.',
                tag: isOwner ? 'Confidential Internal' : 'Owner Locked',
                tagColor: isOwner ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                isLocked: !isOwner,
                onExportPdf: () async {
                  await ReportGenerator.exportOwnerFinancialAuditPdf(
                    items: items,
                    container: container,
                    totals: totals,
                    calculatedLines: calculatedLines,
                  );
                  if (context.mounted) _showSuccess(context, "Owner's Financial Audit PDF downloaded!");
                },
                onExportExcel: () async {
                  await ReportGenerator.exportOwnerFinancialAuditExcel(
                    items: items,
                    container: container,
                    totals: totals,
                    calculatedLines: calculatedLines,
                  );
                  if (context.mounted) _showSuccess(context, "Owner's Financial Audit Excel (.xlsx) downloaded!");
                },
              ),
              const SizedBox(height: 12),

              // Report 2: China Supplier Purchase Order (PO)
              _reportCard(
                context: context,
                icon: Icons.factory_rounded,
                iconColor: const Color(0xFF10B981),
                title: '2. Factory Purchase Order (PO)',
                subtitle: 'Sanitized for China suppliers: shows SKU, master carton quantities, pieces, dimensions, and origin FOB price only. All domestic taxes, logistics, and margins are stripped.',
                tag: 'Sanitized for Supplier',
                tagColor: const Color(0xFF059669),
                onExportPdf: () async {
                  await ReportGenerator.exportSupplierPurchaseOrderPdf(
                    items: items,
                    container: container,
                  );
                  if (context.mounted) _showSuccess(context, 'Supplier Purchase Order PO (PDF) downloaded!');
                },
                onExportExcel: () async {
                  await ReportGenerator.exportSupplierPurchaseOrderExcel(
                    items: items,
                    container: container,
                  );
                  if (context.mounted) _showSuccess(context, 'Supplier Purchase Order PO (Excel) downloaded!');
                },
              ),
              const SizedBox(height: 12),

              // Report 3: Warehouse Receiving & Assembly Checklist
              _reportCard(
                context: context,
                icon: Icons.warehouse_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: '3. Warehouse Receiving & SKD Assembly Checklist',
                subtitle: 'Sanitized for warehouse workers: shows carton counts, gross weights, carton dimensions, and assembly targets without any monetary figures or costs.',
                tag: 'Sanitized for Floor Staff',
                tagColor: const Color(0xFFD97706),
                onExportPdf: () async {
                  await ReportGenerator.exportWarehouseReceivingChecklistPdf(
                    items: items,
                    container: container,
                  );
                  if (context.mounted) _showSuccess(context, 'Warehouse Receiving Checklist (PDF) downloaded!');
                },
                onExportExcel: () async {
                  await ReportGenerator.exportWarehouseReceivingChecklistExcel(
                    items: items,
                    container: container,
                  );
                  if (context.mounted) _showSuccess(context, 'Warehouse Receiving Checklist (Excel) downloaded!');
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      ],
    );
  }

  Widget _reportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required VoidCallback onExportPdf,
    required VoidCallback onExportExcel,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223154)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 10),
                if (isLocked)
                  const Text('Requires Owner Executive Mode to generate financial audit sheet', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11))
                else
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(60, 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFF87171)),
                        label: const Text('Export PDF', style: TextStyle(fontSize: 11)),
                        onPressed: onExportPdf,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(60, 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.table_chart_rounded, size: 14, color: Color(0xFF34D399)),
                        label: const Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 11)),
                        onPressed: onExportExcel,
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

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
