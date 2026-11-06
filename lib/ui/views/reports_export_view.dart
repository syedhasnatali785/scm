import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/calculation_results.dart';
import '../../core/services/report_generator.dart';
import '../../state/shipment_state.dart';

class ReportsExportView extends ConsumerWidget {
  const ReportsExportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(productItemsProvider);
    final container = ref.watch(containerSpecProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final role = ref.watch(userRoleProvider);
    final isOwner = role == AppUserRole.ownerExecutive;

    final calculatedLines = <String, CalculatedLineItem?>{};
    for (final item in items) {
      calculatedLines[item.id] = ref.watch(calculatedLineItemProvider(item.id));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'ROLE-BASED SANITIZED PRO-FORMA EXPORTS & AUDIT REPORTS',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generate sanitized document packages. Third-party documents automatically sanitize internal margins, cascading WeBOC taxes, and confidential clearance rates:',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Report 1: Owner Complete Audit
          _buildReportCard(
            context: context,
            title: "1. Owner's Complete Financial Audit & Profit Sheet",
            description: 'Full un-redacted financials: FOB China costs, freight apportionment, WeBOC/PSW taxes (CD, ACD, RD, ST, WHT), local SKD assembly costs, Unit Landed Cost (ULC), and net profit margins.',
            badge: 'OWNER CONFIDENTIAL',
            badgeColor: const Color(0xFF10B981),
            isRestricted: !isOwner,
            onExportExcel: () {
              ReportGenerator.exportOwnerFinancialAuditExcel(
                items: items,
                container: container,
                totals: totals,
                calculatedLines: calculatedLines,
              );
            },
            onExportPdf: () {
              ReportGenerator.exportOwnerFinancialAuditPdf(
                items: items,
                container: container,
                totals: totals,
                calculatedLines: calculatedLines,
              );
            },
          ),
          const SizedBox(height: 16),

          // Report 2: China Supplier PO
          _buildReportCard(
            context: context,
            title: '2. China Supplier Purchase Order (PO)',
            description: 'Commercial PO in origin currency (RMB only). Strictly redacts and hides all Pakistan customs duties, taxes, domestic haulage, and profit margins to protect commercial negotiation leverage.',
            badge: 'SUPPLIER FACING (RMB ONLY)',
            badgeColor: const Color(0xFF38BDF8),
            isRestricted: false,
            onExportExcel: () {
              ReportGenerator.exportSupplierPurchaseOrderExcel(
                items: items,
                container: container,
              );
            },
            onExportPdf: () {
              ReportGenerator.exportSupplierPurchaseOrderPdf(
                items: items,
                container: container,
              );
            },
          ),
          const SizedBox(height: 16),

          // Report 3: Warehouse Receiving Checklist
          _buildReportCard(
            context: context,
            title: '3. Warehouse Receiving & Assembly Checklist',
            description: 'Tally and QA sheet with carton dimensions, expected vs. received carton checkboxes, gross weights, SKD assembly flags, and damaged carton inspection rows. Strictly redacts all monetary and pricing data.',
            badge: 'WAREHOUSE / LABOR (ZERO PRICES)',
            badgeColor: const Color(0xFFF59E0B),
            isRestricted: false,
            onExportExcel: () {
              ReportGenerator.exportWarehouseReceivingChecklistExcel(
                items: items,
                container: container,
              );
            },
            onExportPdf: () {
              ReportGenerator.exportWarehouseReceivingChecklistPdf(
                items: items,
                container: container,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String description,
    required String badge,
    required Color badgeColor,
    required bool isRestricted,
    required VoidCallback onExportExcel,
    required VoidCallback onExportPdf,
  }) {
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
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 16),

          if (isRestricted)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, size: 14, color: Color(0xFFF87171)),
                  SizedBox(width: 8),
                  Text(
                    'Restricted to Company Owner role. Switch to "Owner Executive" mode to export.',
                    style: TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.table_chart_rounded, size: 15),
                  label: const Text('Export Excel (.xlsx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onExportExcel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading Excel (.xlsx)...'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                  label: const Text('Export PDF Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onExportPdf();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading PDF report...'),
                        backgroundColor: Color(0xFF0284C7),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

