import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CommandNavigationTab {
  dashboard(
    'Executive HUD & Analytics',
    Icons.insights_rounded,
    'KPI Metrics, Waterfall Cost Anatomy & Sensitivity Sliders',
  ),
  auditGrid(
    'Parametric Audit Grid',
    Icons.table_chart_rounded,
    'High-Speed Reciprocal Packaging & Statutory Duty Grid',
  ),
  orderItems(
    'Visual Order Items',
    Icons.view_agenda_rounded,
    'SKU Packaging Cards, Media Thumbnails & Value-Addition',
  ),
  container3D(
    '3D Container CMS',
    Icons.view_in_ar_rounded,
    'Extreme-Point Bin Packing, 3D Orbit & Axle Limits',
  ),
  costPipeline(
    'Cost Pipeline & Duties',
    Icons.account_tree_rounded,
    '4-Stage Freight, Customs & Haulage Apportionment',
  ),
  sourcingSandbox(
    'Sourcing Sandbox',
    Icons.compare_arrows_rounded,
    'Supplier Quote Benchmarking & Landed Cost Scenarios',
  ),
  exports(
    'Reports & Exports',
    Icons.file_download_rounded,
    'Role-Based Pro-Forma Excel & PDF Document Generator',
  );

  final String label;
  final IconData icon;
  final String subtitle;
  const CommandNavigationTab(this.label, this.icon, this.subtitle);
}

final activeNavigationTabProvider = StateProvider<CommandNavigationTab>(
  (ref) => CommandNavigationTab.dashboard,
);

