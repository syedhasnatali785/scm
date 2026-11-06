import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/container_spec.dart';
import '../../core/utils/formatters.dart';
import '../../state/shipment_state.dart';
import '../widgets/container_3d/container_3d_view.dart';
import '../widgets/dialogs/container_spec_dialog.dart';
import '../widgets/dialogs/fill_the_gap_dialog.dart';

class ContainerCmsView extends ConsumerWidget {
  const ContainerCmsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final container = ref.watch(containerSpecProvider);
    final totals = ref.watch(calculatedTotalsProvider);
    final packingResult = ref.watch(packingResultProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: 3D Studio Canvas & Loading Timeline (Flex 65)
              Expanded(
                flex: 65,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container3DView(
                    container: container,
                    packingResult: packingResult,
                    hasDoorCollision: totals.doorwayCollisionsCount > 0,
                  ),
                ),
              ),

              // Vertical Border Divider
              Container(width: 1, color: const Color(0xFF1E293B)),

              // Right: Specifications, Presets, Doorway & Axle Gatekeeper (Flex 35)
              Expanded(
                flex: 35,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preset Selector Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONTAINER SPECIFICATIONS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: const Size(60, 26),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 12),
                            label: const Text(
                              'Edit Dimensions',
                              style: TextStyle(fontSize: 11),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const ContainerSpecDialog(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ISO Presets Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in ContainerPreset.values)
                            _presetChip(
                              preset: preset,
                              isSelected: container.preset == preset,
                              onTap: () {
                                ref
                                    .read(containerSpecProvider.notifier)
                                    .selectPreset(preset);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Dimensions Summary Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              container.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCol(
                                    'Internal L*W*H',
                                    '${container.lengthCm.toStringAsFixed(0)}*${container.widthCm.toStringAsFixed(0)}*${container.heightCm.toStringAsFixed(0)} cm',
                                  ),
                                ),
                                Expanded(
                                  child: _metricCol(
                                    'Doorway (W*H)',
                                    '${container.doorWidthCm.toStringAsFixed(0)}*${container.doorHeightCm.toStringAsFixed(0)} cm',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCol(
                                    'Max Payload',
                                    '${Formatters.number(container.maxGrossPayloadKg.round())} kg',
                                  ),
                                ),
                                Expanded(
                                  child: _metricCol(
                                    'Road Axle Limit',
                                    '${Formatters.number(container.roadAxleLimitKg.round())} kg',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Doorway Clearance Gatekeeper Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: totals.doorwayCollisionsCount > 0
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: totals.doorwayCollisionsCount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  totals.doorwayCollisionsCount > 0
                                      ? Icons.error_outline_rounded
                                      : Icons.check_circle_outline_rounded,
                                  color: totals.doorwayCollisionsCount > 0
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFF34D399),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  totals.doorwayCollisionsCount > 0
                                      ? 'DOORWAY COLLISION WARNING'
                                      : 'DOORWAY CLEARANCE VALIDATED',
                                  style: TextStyle(
                                    color: totals.doorwayCollisionsCount > 0
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFF34D399),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totals.doorwayCollisionsCount > 0
                                  ? '${totals.doorwayCollisionsCount} cargo carton orientations exceed the container door height of ${container.doorHeightCm.toStringAsFixed(0)} cm. Rotate cartons upright or choose a High Cube (40HC) container.'
                                  : 'All packaged SKUs clear the ${container.doorHeightCm.toStringAsFixed(0)} cm doorway aperture.',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                              ),
                            ),
                            if (totals.doorwayCollidingSkus.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final sku in totals.doorwayCollidingSkus)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sku,
                                        style: const TextStyle(
                                          color: Color(0xFFFCA5A5),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fill The Gap Quick Launcher
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Color(0xFF38BDF8),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'FILL-THE-GAP OPTIMIZER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Remaining free: ${totals.remainingCbm.toStringAsFixed(1)} CBM (${Formatters.number(totals.remainingPayloadKg.round())} kg available). Top up with high-margin items to eliminate dead freight.',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(Icons.bolt_rounded, size: 16),
                              label: const Text(
                                'Calculate Top-Up SKUs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => const FillTheGapDialog(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Mobile/Narrow fallback: column
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 400,
                  child: Container3DView(
                    container: container,
                    packingResult: packingResult,
                    hasDoorCollision: totals.doorwayCollisionsCount > 0,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _presetChip({
    required ContainerPreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF38BDF8)
                : const Color(0xFF334155),
          ),
        ),
        child: Text(
          preset.name,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
