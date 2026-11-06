import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../../../engine/packing/packed_box.dart';

class Container3DData {
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final List<PackedBox> boxes;
  final int visibleCount;

  Container3DData({
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.boxes,
    required this.visibleCount,
  });
}

/// Hardware-accelerated 3D CustomPainter backed by a true 4x4 perspective projection Matrix4
class Container3DPainter extends CustomPainter {
  final Container3DData data;
  final double yaw;   // Orbit rotation around vertical axis (radians)
  final double pitch; // Orbit tilt angle (radians)
  final double zoom;  // Camera distance scale factor
  final PackedBox? selectedBox;

  Container3DPainter({
    required this.data,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    this.selectedBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 15);

    // Dynamic viewport fit
    final maxDim = math.max(data.lengthCm, math.max(data.widthCm, data.heightCm));
    final baseScale = (math.min(size.width, size.height) * 0.72) / maxDim;
    final scale = baseScale * zoom;

    final originOffset = Offset(center.dx, center.dy);

    // Construct 4x4 Perspective Projection & Camera Transformation Matrix
    // We position the camera and apply perspective divide (depth factor in [3][2])
    final vmath.Matrix4 mvp = vmath.Matrix4.identity()
      ..setEntry(3, 2, 0.0006) // Perspective foreshortening
      ..rotateX(pitch)
      ..rotateY(yaw);

    // 3D coordinate -> 2D screen coordinate projection
    Offset project(double x, double y, double z) {
      // Translate origin to container centroid
      final cx = x - data.lengthCm / 2;
      final cy = y - data.widthCm / 2;
      final cz = z - data.heightCm / 2;

      // Coordinate mapping:
      // X = container length
      // Y = container height (upwards)
      // Z = container width (depth)
      final v4 = mvp.transform(vmath.Vector4(cx, -cz, cy, 1.0));
      final w = v4.w.abs() > 0.0001 ? v4.w : 1.0;

      final sx = originOffset.dx + (v4.x / w) * scale;
      final sy = originOffset.dy + (v4.y / w) * scale;
      return Offset(sx, sy);
    }

    // Depth sorter helper using Matrix4 transformed Z
    double getDepth(double x, double y, double z) {
      final cx = x - data.lengthCm / 2;
      final cy = y - data.widthCm / 2;
      final cz = z - data.heightCm / 2;
      final v4 = mvp.transform(vmath.Vector4(cx, -cz, cy, 1.0));
      return v4.z;
    }

    // --- 1. Draw Floor / Ground Grid & Shadow ---
    final floorPaint = Paint()
      ..color = const Color(0x1838BDF8)
      ..style = PaintingStyle.fill;
    final floorBorder = Paint()
      ..color = const Color(0x4038BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final p00 = project(0, 0, 0);
    final pL0 = project(data.lengthCm, 0, 0);
    final pLW = project(data.lengthCm, data.widthCm, 0);
    final p0W = project(0, data.widthCm, 0);

    final floorPath = Path()
      ..moveTo(p00.dx, p00.dy)
      ..lineTo(pL0.dx, pL0.dy)
      ..lineTo(pLW.dx, pLW.dy)
      ..lineTo(p0W.dx, p0W.dy)
      ..close();
    canvas.drawPath(floorPath, floorPaint);
    canvas.drawPath(floorPath, floorBorder);

    // Floor grid lines every 100 cm
    final gridPaint = Paint()
      ..color = const Color(0x1F38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double x = 100; x < data.lengthCm; x += 100) {
      final a = project(x, 0, 0);
      final b = project(x, data.widthCm, 0);
      canvas.drawLine(a, b, gridPaint);
    }

    // --- 2. Sort Boxes Back-to-Front (Painter's Algorithm using Matrix4 Depth) ---
    final visibleBoxes = data.boxes.take(data.visibleCount).toList();

    visibleBoxes.sort((a, b) {
      final depthA = getDepth(a.x + a.dx / 2, a.y + a.dy / 2, a.z + a.dz / 2);
      final depthB = getDepth(b.x + b.dx / 2, b.y + b.dy / 2, b.z + b.dz / 2);
      return depthA.compareTo(depthB);
    });

    // --- 3. Draw Each Shaded 3D Box ---
    for (final box in visibleBoxes) {
      _drawBox(canvas, box, project);
    }

    // --- 4. Draw Container Wireframe Cage & Corner Posts ---
    _drawContainerCage(canvas, data, project);
  }

  void _drawBox(
    Canvas canvas,
    PackedBox box,
    Offset Function(double x, double y, double z) project,
  ) {
    final x = box.x;
    final y = box.y;
    final z = box.z;
    final dx = box.dx;
    final dy = box.dy;
    final dz = box.dz;

    // Projected vertices
    final v1 = project(x + dx, y, z);
    final v2 = project(x + dx, y + dy, z);
    final v3 = project(x, y + dy, z);
    final v4 = project(x, y, z + dz);
    final v5 = project(x + dx, y, z + dz);
    final v6 = project(x + dx, y + dy, z + dz);
    final v7 = project(x, y + dy, z + dz);

    final isSelected = selectedBox?.cartonIndex == box.cartonIndex && selectedBox?.itemId == box.itemId;
    final baseColor = isSelected ? const Color(0xFFFBBF24) : box.color;

    // Dynamic 3D lighting face shading
    final topColor = HSLColor.fromColor(baseColor)
        .withLightness(math.min(1.0, HSLColor.fromColor(baseColor).lightness + 0.16))
        .toColor();
    final sideColor1 = HSLColor.fromColor(baseColor)
        .withLightness(math.max(0.0, HSLColor.fromColor(baseColor).lightness - 0.08))
        .toColor();
    final sideColor2 = HSLColor.fromColor(baseColor)
        .withLightness(math.max(0.0, HSLColor.fromColor(baseColor).lightness - 0.22))
        .toColor();

    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.2 : 0.8;

    // Top Face (v4, v5, v6, v7)
    final topPath = Path()
      ..moveTo(v4.dx, v4.dy)
      ..lineTo(v5.dx, v5.dy)
      ..lineTo(v6.dx, v6.dy)
      ..lineTo(v7.dx, v7.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor.withOpacity(0.92));
    canvas.drawPath(topPath, borderPaint);

    // Front Face (v1, v2, v6, v5)
    final frontPath = Path()
      ..moveTo(v1.dx, v1.dy)
      ..lineTo(v2.dx, v2.dy)
      ..lineTo(v6.dx, v6.dy)
      ..lineTo(v5.dx, v5.dy)
      ..close();
    canvas.drawPath(frontPath, Paint()..color = sideColor1.withOpacity(0.92));
    canvas.drawPath(frontPath, borderPaint);

    // Side Face (v2, v3, v7, v6)
    final leftPath = Path()
      ..moveTo(v2.dx, v2.dy)
      ..lineTo(v3.dx, v3.dy)
      ..lineTo(v7.dx, v7.dy)
      ..lineTo(v6.dx, v6.dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = sideColor2.withOpacity(0.92));
    canvas.drawPath(leftPath, borderPaint);
  }

  void _drawContainerCage(
    Canvas canvas,
    Container3DData data,
    Offset Function(double x, double y, double z) project,
  ) {
    final L = data.lengthCm;
    final W = data.widthCm;
    final H = data.heightCm;

    // 8 container corners
    final c0 = project(0, 0, 0);
    final c1 = project(L, 0, 0);
    final c2 = project(L, W, 0);
    final c3 = project(0, W, 0);
    final c4 = project(0, 0, H);
    final c5 = project(L, 0, H);
    final c6 = project(L, W, H);
    final c7 = project(0, W, H);

    final cagePaint = Paint()
      ..color = const Color(0x6038BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final postPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Roof outline
    canvas.drawLine(c4, c5, cagePaint);
    canvas.drawLine(c5, c6, cagePaint);
    canvas.drawLine(c6, c7, cagePaint);
    canvas.drawLine(c7, c4, cagePaint);

    // 4 Vertical Steel Corner Posts
    canvas.drawLine(c0, c4, postPaint);
    canvas.drawLine(c1, c5, postPaint);
    canvas.drawLine(c2, c6, postPaint);
    canvas.drawLine(c3, c7, postPaint);

    // Door Frame Portal (at X = L, container rear opening)
    final doorPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawLine(c1, c5, doorPaint);
    canvas.drawLine(c2, c6, doorPaint);
    canvas.drawLine(c5, c6, doorPaint);
  }

  @override
  bool shouldRepaint(covariant Container3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.data.visibleCount != data.visibleCount ||
        oldDelegate.selectedBox != selectedBox ||
        oldDelegate.data.boxes != data.boxes;
  }
}
