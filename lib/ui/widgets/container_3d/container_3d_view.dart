import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/container_spec.dart';
import '../../../engine/packing/packed_box.dart';
import '../../../state/shipment_state.dart';
import 'container_3d_painter.dart';

class Container3DView extends ConsumerStatefulWidget {
  final ContainerSpec container;
  final PackingResult packingResult;
  final bool hasDoorCollision;

  const Container3DView({
    super.key,
    required this.container,
    required this.packingResult,
    this.hasDoorCollision = false,
  });

  @override
  ConsumerState<Container3DView> createState() => _Container3DViewState();
}

class _Container3DViewState extends ConsumerState<Container3DView>
    with SingleTickerProviderStateMixin {
  double _yaw = 0.85; // initial isometric angle
  double _pitch = 0.45;
  double _zoom = 1.0;
  int _visibleBoxesCount = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  PackedBox? _selectedBox;

  @override
  void initState() {
    super.initState();
    _visibleBoxesCount = widget.packingResult.totalPackedCartons;
  }

  @override
  void didUpdateWidget(covariant Container3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packingResult != widget.packingResult) {
      if (!_isPlaying) {
        _visibleBoxesCount = widget.packingResult.totalPackedCartons;
      }
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() {
        _isPlaying = true;
        if (_visibleBoxesCount >= widget.packingResult.totalPackedCartons) {
          _visibleBoxesCount = 0;
        }
      });
      _playbackTimer =
          Timer.periodic(const Duration(milliseconds: 40), (timer) {
            if (_visibleBoxesCount < widget.packingResult.totalPackedCartons) {
              setState(() {
                _visibleBoxesCount = (_visibleBoxesCount + 1).clamp(
                  0,
                  widget.packingResult.totalPackedCartons,
                );
              });
            } else {
              timer.cancel();
              setState(() => _isPlaying = false);
            }
          });
    }
  }

  void _stepBackward() {
    if (_visibleBoxesCount > 0) {
      setState(() => _visibleBoxesCount--);
    }
  }

  void _stepForward() {
    if (_visibleBoxesCount < widget.packingResult.totalPackedCartons) {
      setState(() => _visibleBoxesCount++);
    }
  }

  void _resetCamera() {
    setState(() {
      _yaw = 0.85;
      _pitch = 0.45;
      _zoom = 1.0;
      _visibleBoxesCount = widget.packingResult.totalPackedCartons;
      _selectedBox = null;
    });
  }

  void _showDoorwayAlertDetails(BuildContext context, List<String> collidingSkus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Doorway Collision Alert', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Container: ${widget.container.name}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            Text(
              'Max Door Clearance: ${(widget.container.doorHeightCm * 10).toStringAsFixed(0)} mm H × ${(widget.container.doorWidthCm * 10).toStringAsFixed(0)} mm W',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'The following carton items exceed the door opening and cannot be loaded:',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...collidingSkus.map((sku) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(sku, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Acknowledge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAxleAlertDetails(BuildContext context, double totalGw, double limit, double excess) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.scale_rounded, color: Color(0xFFF59E0B), size: 24),
            SizedBox(width: 10),
            Text('Road Axle Weight Gatekeeper Alert', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gross Cargo Weight: ${totalGw.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Road Axle Legal Limit: ${limit.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                'Overweight Penalty Risk: Cargo exceeds legal highway weight limit by +${excess.toStringAsFixed(0)} kg. Heavy axle surcharge or container cross-stuffing required!',
                style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBoxes = widget.packingResult.totalPackedCartons;
    final totals = ref.watch(calculatedTotalsProvider);

    // Current inspecting box info during timeline scrubbing
    final inspectingBox = (_visibleBoxesCount > 0 &&
            _visibleBoxesCount <= widget.packingResult.boxes.length)
        ? widget.packingResult.boxes[_visibleBoxesCount - 1]
        : null;

    final occupiedPct = widget.packingResult.occupiedPct;
    final voidWastePct = widget.packingResult.voidWastePct;
    final freePct = widget.packingResult.freePct;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Interactive 3D Canvas
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _yaw += details.delta.dx * 0.008;
                  _pitch = (_pitch + details.delta.dy * 0.008).clamp(-0.8, 1.2);
                });
              },
              child: CustomPaint(
                painter: Container3DPainter(
                  data: Container3DData(
                    lengthCm: widget.container.lengthCm,
                    widthCm: widget.container.widthCm,
                    heightCm: widget.container.heightCm,
                    boxes: widget.packingResult.boxes,
                    visibleCount: _visibleBoxesCount,
                  ),
                  yaw: _yaw,
                  pitch: _pitch,
                  zoom: _zoom,
                  selectedBox: _selectedBox,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // Top Status & Gatekeeper Badges Bar
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Container Spec Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.view_in_ar_rounded,
                          size: 15,
                          color: Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.container.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0369A1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.container.usableCbm.toStringAsFixed(1)} CBM Usable',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gatekeeper Alerts & Density Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Doorway Collision Warning Gatekeeper
                      if (totals.doorwayCollisionsCount > 0)
                        InkWell(
                          onTap: () => _showDoorwayAlertDetails(context, totals.doorwayCollidingSkus),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Door Collision (${totals.doorwayCollisionsCount})',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 2. Road Axle Weight Overload Gatekeeper
                      if (totals.isOverweightAxle)
                        InkWell(
                          onTap: () => _showAxleAlertDetails(
                            context,
                            totals.totalGrossWeightKg,
                            totals.roadAxleLimitKg,
                            totals.excessAxleWeightKg,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.scale_rounded, size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Axle Overload +${totals.excessAxleWeightKg.toStringAsFixed(0)}kg',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 3. Density Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xCC065F46),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF059669)),
                        ),
                        child: Text(
                          '${widget.packingResult.packingDensityPct.toStringAsFixed(1)}% Packed',
                          style: const TextStyle(
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
            ),

            // Top Right Navigation Controls (Zoom & Reset)
            Positioned(
              right: 14,
              top: 55,
              child: Column(
                children: [
                  _circleButton(
                    icon: Icons.add,
                    tooltip: 'Zoom In',
                    onTap: () =>
                        setState(() => _zoom = (_zoom * 1.15).clamp(0.5, 3.0)),
                  ),
                  const SizedBox(height: 6),
                  _circleButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onTap: () =>
                        setState(() => _zoom = (_zoom / 1.15).clamp(0.5, 3.0)),
                  ),
                  const SizedBox(height: 6),
                  _circleButton(
                    icon: Icons.refresh,
                    tooltip: 'Reset View',
                    onTap: _resetCamera,
                  ),
                ],
              ),
            ),

            // Bottom Panel: 3-Segment Capacity Bar & Loading Timeline Scrubber
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Three-Segment Capacity Bar (Occupied vs Stacking Void vs Free CBM)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xF00B132B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CONTAINER VOLUMETRIC CAPACITY BREAKDOWN',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Target: ${widget.container.usableCbm.toStringAsFixed(1)} m³',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // The 3-Segment Visual Multi-color Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 10,
                            child: Row(
                              children: [
                                // Segment 1: Occupied Cargo CBM
                                if (occupiedPct > 0)
                                  Flexible(
                                    flex: (occupiedPct * 10).round(),
                                    child: Container(
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                // Segment 2: Stacking Void Waste CBM
                                if (voidWastePct > 0)
                                  Flexible(
                                    flex: (voidWastePct * 10).round(),
                                    child: Container(
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                // Segment 3: Free Usable CBM
                                if (freePct > 0)
                                  Flexible(
                                    flex: (freePct * 10).round(),
                                    child: Container(
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Capacity Legend Readout
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Occupied
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(
                                  'Occupied: ${widget.packingResult.packedCbm.toStringAsFixed(1)} m³ (${occupiedPct.toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            // Stacking Void Waste
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(
                                  'Void Waste: ${widget.packingResult.voidWasteCbm.toStringAsFixed(1)} m³ (${voidWastePct.toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            // Free Space
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(
                                  'Free Space: ${widget.packingResult.freeCbm.toStringAsFixed(1)} m³ (${freePct.toStringAsFixed(1)}%)',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 2. Interactive Step-by-Step Loading Timeline Scrubber
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xEE1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Play/Pause Step Animation
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: const Color(0xFF38BDF8),
                                size: 28,
                              ),
                              onPressed: totalBoxes > 0 ? _togglePlayback : null,
                            ),
                            const SizedBox(width: 4),
                            // Step -1
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.skip_previous, size: 20, color: Color(0xFF94A3B8)),
                              onPressed: _visibleBoxesCount > 0 ? _stepBackward : null,
                            ),
                            // Step +1
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.skip_next, size: 20, color: Color(0xFF94A3B8)),
                              onPressed: _visibleBoxesCount < totalBoxes ? _stepForward : null,
                            ),
                            const SizedBox(width: 8),

                            // Carton Count Status
                            Text(
                              '$_visibleBoxesCount / $totalBoxes ctns',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Scrubber Slider
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  activeTrackColor: const Color(0xFF38BDF8),
                                  inactiveTrackColor: const Color(0xFF475569),
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                ),
                                child: Slider(
                                  value: _visibleBoxesCount.toDouble(),
                                  min: 0,
                                  max: totalBoxes > 0 ? totalBoxes.toDouble() : 1.0,
                                  onChanged: totalBoxes > 0
                                      ? (v) => setState(
                                          () => _visibleBoxesCount = v.toInt(),
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            Text(
                              '${widget.packingResult.packedCbm.toStringAsFixed(1)} m³',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),

                        // Current Placed Carton Live Inspector Info
                        if (inspectingBox != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(color: inspectingBox.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Loading: ${inspectingBox.itemName} (#${inspectingBox.cartonIndex + 1})',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Layer ${inspectingBox.layer}  •  ${inspectingBox.stackingTier.label}  •  ${inspectingBox.weightKg} kg',
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xCC1E293B),
      shape: const CircleBorder(side: BorderSide(color: Color(0xFF475569))),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
