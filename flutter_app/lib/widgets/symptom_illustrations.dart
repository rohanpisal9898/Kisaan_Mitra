import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Clean, high-fidelity custom vector painters for Pest Detection Page 1 illustrations.
/// Reproduces the visuals from the reference image with exact agricultural fidelity.
class SymptomIllustrations {
  /// Hero Plant Sprout Illustration (Top Right of Hero Card)
  static Widget heroPlant({double size = 110}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeroPlantPainter(),
      ),
    );
  }

  /// Symptom 1: Holes / eaten leaves
  static Widget holesEatenLeaves({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HolesEatenLeavesPainter(),
      ),
    );
  }

  /// Symptom 2: Insects
  static Widget insects({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InsectsPainter(),
      ),
    );
  }

  /// Symptom 3: Spots / discoloration
  static Widget spotsDiscoloration({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpotsDiscolorationPainter(),
      ),
    );
  }

  /// Symptom 4: Curling / distortion
  static Widget curlingDistortion({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CurlingDistortionPainter(),
      ),
    );
  }

  /// Symptom 5: Webbing
  static Widget webbing({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WebbingPainter(),
      ),
    );
  }

  /// Symptom 6: Sudden damage
  static Widget suddenDamage({double size = 48}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SuddenDamagePainter(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Custom Painters Implementation
// ─────────────────────────────────────────────────────────

class _HeroPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soil base mound
    final soilPaint = Paint()
      ..color = const Color(0xFFF1F7EC)
      ..style = PaintingStyle.fill;
    final soilOutline = Paint()
      ..color = const Color(0xFF3B6E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final soilPath = Path();
    soilPath.moveTo(w * 0.2, h * 0.85);
    soilPath.quadraticBezierTo(w * 0.5, h * 0.70, w * 0.85, h * 0.85);
    soilPath.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.2, h * 0.85);
    canvas.drawPath(soilPath, soilPaint);
    canvas.drawPath(soilPath, soilOutline);

    // Stems & Leaves
    final stemPaint = Paint()
      ..color = const Color(0xFF2C561A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final leafFill = Paint()
      ..color = const Color(0xFF7CB518)
      ..style = PaintingStyle.fill;
    final leafOutline = Paint()
      ..color = const Color(0xFF2C561A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Central Stem
    final mainStem = Path();
    mainStem.moveTo(w * 0.52, h * 0.84);
    mainStem.cubicTo(w * 0.54, h * 0.60, w * 0.48, h * 0.45, w * 0.55, h * 0.32);
    canvas.drawPath(mainStem, stemPaint);

    // Top Leaves Cluster (scaled & positioned comfortably inside canvas)
    _drawLeaf(canvas, Offset(w * 0.55, h * 0.32), -0.5, 13, leafFill, leafOutline);
    _drawLeaf(canvas, Offset(w * 0.55, h * 0.32), 0.6, 14, leafFill, leafOutline);
    _drawLeaf(canvas, Offset(w * 0.52, h * 0.28), 0.1, 15, leafFill, leafOutline);

    // Mid-Right Branch & Leaves
    final rightBranch = Path();
    rightBranch.moveTo(w * 0.51, h * 0.52);
    rightBranch.quadraticBezierTo(w * 0.65, h * 0.50, w * 0.75, h * 0.44);
    canvas.drawPath(rightBranch, stemPaint);
    _drawLeaf(canvas, Offset(w * 0.75, h * 0.44), 0.3, 13, leafFill, leafOutline);
    _drawLeaf(canvas, Offset(w * 0.68, h * 0.47), -0.7, 11, leafFill, leafOutline);

    // Mid-Left Branch & Leaves
    final leftBranch = Path();
    leftBranch.moveTo(w * 0.52, h * 0.64);
    leftBranch.quadraticBezierTo(w * 0.38, h * 0.62, w * 0.28, h * 0.56);
    canvas.drawPath(leftBranch, stemPaint);
    _drawLeaf(canvas, Offset(w * 0.28, h * 0.56), -0.4, 13, leafFill, leafOutline);
    _drawLeaf(canvas, Offset(w * 0.35, h * 0.60), 0.7, 11, leafFill, leafOutline);

    // Ambient decorative sparkle dots
    final dotPaint = Paint()..color = const Color(0xFF9BD841);
    canvas.drawCircle(Offset(w * 0.15, h * 0.42), 2.5, dotPaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.38), 3.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.70), 2.0, dotPaint);
  }

  void _drawLeaf(Canvas canvas, Offset center, double angle, double scale, Paint fill, Paint outline) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(-scale * 0.6, -scale * 0.8, -scale * 0.8, -scale * 1.5, 0, -scale * 2.0);
    path.cubicTo(scale * 0.8, -scale * 1.5, scale * 0.6, -scale * 0.8, 0, 0);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    // Leaf center line
    final mid = Paint()
      ..color = outline.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(0, 0), Offset(0, -scale * 1.8), mid);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HolesEatenLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leafFill = Paint()..color = const Color(0xFF4A7C21);
    final leafOutline = Paint()
      ..color = const Color(0xFF1E3A0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.3);

    // Main Leaf Body with eaten cutouts
    final leafPath = Path();
    leafPath.moveTo(0, h * 0.4);
    leafPath.cubicTo(-w * 0.45, h * 0.1, -w * 0.35, -h * 0.35, 0, -h * 0.45);
    leafPath.cubicTo(w * 0.4, -h * 0.3, w * 0.45, h * 0.15, 0, h * 0.4);

    // Subtract holes
    final hole1 = Path()..addOval(Rect.fromCircle(center: Offset(-w * 0.1, -h * 0.1), radius: 4.5));
    final hole2 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.12, h * 0.05), radius: 3.5));
    final hole3 = Path()..addOval(Rect.fromCircle(center: Offset(-w * 0.05, h * 0.18), radius: 3.0));

    var finalPath = Path.combine(PathOperation.difference, leafPath, hole1);
    finalPath = Path.combine(PathOperation.difference, finalPath, hole2);
    finalPath = Path.combine(PathOperation.difference, finalPath, hole3);

    canvas.drawPath(finalPath, leafFill);
    canvas.drawPath(finalPath, leafOutline);

    // Veins
    final veinPaint = Paint()
      ..color = const Color(0xFF1E3A0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, h * 0.38), Offset(0, -h * 0.42), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsectsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green Caterpillar / Insect
    final bodyPaint = Paint()..color = const Color(0xFF4EA119);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1B4407)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.4);

    // Segmented body curve
    final segments = [
      Offset(-w * 0.35, h * 0.15),
      Offset(-w * 0.20, h * 0.02),
      Offset(-w * 0.05, h * 0.12),
      Offset(w * 0.10, h * 0.0),
      Offset(w * 0.25, -h * 0.12),
      Offset(w * 0.38, -h * 0.22),
    ];

    final radii = [5.5, 6.5, 7.0, 7.5, 7.0, 6.0];

    for (int i = 0; i < segments.length; i++) {
      canvas.drawCircle(segments[i], radii[i], bodyPaint);
      canvas.drawCircle(segments[i], radii[i], outlinePaint);
    }

    // Antennae
    final head = segments.last;
    canvas.drawLine(head, head + const Offset(4, -8), outlinePaint);
    canvas.drawLine(head, head + const Offset(8, -4), outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpotsDiscolorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(0.2);

    final leafPath = Path();
    leafPath.moveTo(0, h * 0.42);
    leafPath.cubicTo(-w * 0.42, h * 0.1, -w * 0.35, -h * 0.38, 0, -h * 0.45);
    leafPath.cubicTo(w * 0.42, -h * 0.38, w * 0.42, h * 0.1, 0, h * 0.42);

    // Yellow / Orange / Brown discolored gradient fill
    final rect = Rect.fromLTWH(-w * 0.5, -h * 0.5, w, h);
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5A11A), Color(0xFFC85A17), Color(0xFF386014)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect);

    final outline = Paint()
      ..color = const Color(0xFF26400A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(leafPath, gradPaint);

    // Dark spots
    final spotPaint = Paint()..color = const Color(0xFF52280A);
    canvas.drawCircle(Offset(-w * 0.12, -h * 0.1), 3.5, spotPaint);
    canvas.drawCircle(Offset(w * 0.10, -h * 0.2), 2.5, spotPaint);
    canvas.drawCircle(Offset(w * 0.15, h * 0.05), 4.0, spotPaint);
    canvas.drawCircle(Offset(-w * 0.08, h * 0.15), 3.0, spotPaint);

    canvas.drawPath(leafPath, outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurlingDistortionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leafFill = Paint()..color = const Color(0xFF68A31D);
    final outline = Paint()
      ..color = const Color(0xFF204209)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);

    // Distortion wavy leaf
    final path = Path();
    path.moveTo(0, h * 0.4);
    path.cubicTo(-w * 0.4, h * 0.2, -w * 0.1, -h * 0.1, -w * 0.35, -h * 0.35);
    path.cubicTo(-w * 0.1, -h * 0.45, w * 0.35, -h * 0.2, w * 0.2, h * 0.15);
    path.cubicTo(w * 0.35, h * 0.35, 0, h * 0.3, 0, h * 0.4);

    canvas.drawPath(path, leafFill);
    canvas.drawPath(path, outline);

    // Fallen deformed leaf tip piece
    final fallen = Path();
    fallen.addOval(Rect.fromLTWH(w * 0.1, h * 0.15, 10, 6));
    canvas.drawPath(fallen, leafFill);
    canvas.drawPath(fallen, outline);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WebbingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leafFill = Paint()..color = const Color(0xFF386819);
    final outline = Paint()
      ..color = const Color(0xFF153307)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);

    final leafPath = Path();
    leafPath.moveTo(0, h * 0.4);
    leafPath.cubicTo(-w * 0.4, h * 0.1, -w * 0.35, -h * 0.35, 0, -h * 0.42);
    leafPath.cubicTo(w * 0.4, -h * 0.35, w * 0.4, h * 0.1, 0, h * 0.4);

    canvas.drawPath(leafPath, leafFill);
    canvas.drawPath(leafPath, outline);

    // Spider web overlay lines
    final webPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(-w * 0.05, -h * 0.05);
    for (int i = 0; i < 6; i++) {
      double angle = i * math.pi / 3;
      Offset dest = center + Offset(math.cos(angle) * 16, math.sin(angle) * 16);
      canvas.drawLine(center, dest, webPaint);
    }

    final webRing = Path();
    webRing.addOval(Rect.fromCircle(center: center, radius: 8));
    webRing.addOval(Rect.fromCircle(center: center, radius: 14));
    canvas.drawPath(webRing, webPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuddenDamagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()..color = const Color(0xFF6B4219);
    final outline = Paint()
      ..color = const Color(0xFF2E1704)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(0.35);

    // Wilted drooped leaf with dead brown spots
    final path = Path();
    path.moveTo(0, h * 0.42);
    path.cubicTo(-w * 0.38, h * 0.2, -w * 0.4, -h * 0.1, 0, -h * 0.4);
    path.cubicTo(w * 0.3, -h * 0.2, w * 0.35, h * 0.25, 0, h * 0.42);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);

    final greenRemnant = Paint()..color = const Color(0xFF496D1D);
    canvas.drawCircle(Offset(-w * 0.08, -h * 0.15), 5.0, greenRemnant);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
