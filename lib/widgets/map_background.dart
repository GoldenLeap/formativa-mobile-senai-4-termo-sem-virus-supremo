import 'package:flutter/material.dart';

class MapBackground extends StatelessWidget {
  const MapBackground({super.key, this.showParks = true});

  final bool showParks;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: CustomPaint(
          size: Size.infinite,
          painter: _MapBackgroundPainter(showParks: showParks),
        ),
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  const _MapBackgroundPainter({required this.showParks});

  final bool showParks;

  static const _background = Color(0xFFE9EBEA);
  static const _street = Color(0xFFF9FAF9);
  static const _blockColors = [
    Color(0xFFE3E6E4),
    Color(0xFFE7E9E8),
    Color(0xFFE5E8E6),
    Color(0xFFEDF0EE),
  ];

  static const _columns = [
    -620.0,
    -579.0,
    -545.0,
    -497.0,
    -461.0,
    -414.0,
    -376.0,
    -334.0,
    -292.0,
    -245.0,
    -207.0,
    -162.0,
    -128.0,
    -86.0,
    -45.0,
    0.0,
    39.0,
    84.0,
    121.0,
    169.0,
    211.0,
    249.0,
    296.0,
    335.0,
    378.0,
    423.0,
    459.0,
    506.0,
    548.0,
    590.0,
    635.0,
    679.0,
  ];
  static const _rows = [
    -280.0,
    -237.0,
    -200.0,
    -156.0,
    -116.0,
    -72.0,
    -31.0,
    13.0,
    55.0,
    94.0,
    139.0,
    174.0,
    219.0,
    258.0,
    303.0,
    342.0,
    387.0,
    428.0,
    470.0,
    507.0,
    551.0,
    590.0,
    635.0,
    673.0,
    717.0,
    758.0,
    804.0,
    848.0,
    892.0,
    935.0,
    980.0,
  ];

  Offset _point(double column, double row) {
    return Offset(column * .766 + row * .643, -column * .643 + row * .766);
  }

  Path _block(double left, double top, double right, double bottom) {
    final points = [
      _point(left, top),
      _point(right, top),
      _point(right, bottom),
      _point(left, bottom),
    ];
    return Path()..addPolygon(points, true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / 390, size.height / 680);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 390, 680),
      Paint()..color = _background,
    );

    _paintBlocks(canvas);
    _paintLocalStreets(canvas);
    if (showParks) _paintParks(canvas);
    _paintAvenues(canvas);
    canvas.restore();
  }

  void _paintBlocks(Canvas canvas) {
    final paint = Paint();
    final divider = Paint()
      ..color = const Color(0xFFF1F3F2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var column = 0; column < _columns.length - 1; column++) {
      for (var row = 0; row < _rows.length - 1; row++) {
        final left = _columns[column] + 3.4;
        final right = _columns[column + 1] - 3.4;
        final top = _rows[row] + 3.4;
        final bottom = _rows[row + 1] - 3.4;
        final bounds = _block(left, top, right, bottom);
        if (!bounds.getBounds().overlaps(const Rect.fromLTWH(0, 0, 390, 680))) {
          continue;
        }

        paint.color =
            _blockColors[(column * 7 + row * 3) % _blockColors.length];
        canvas.drawPath(bounds, paint);

        // Subtle parcel divisions provide detail without competing with pins.
        final split = left + (right - left) * .52;
        canvas.drawLine(
          _point(split, top + 2),
          _point(split, bottom - 2),
          divider,
        );
        if ((column + row) % 3 == 0) {
          final middle = top + (bottom - top) * .48;
          canvas.drawLine(
            _point(left + 2, middle),
            _point(split - 1, middle),
            divider,
          );
        }
      }
    }
  }

  void _paintLocalStreets(Canvas canvas) {
    final paint = Paint()
      ..color = _street
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < _columns.length; index++) {
      paint.strokeWidth = index % 4 == 0 ? 3.8 : 2.2;
      canvas.drawLine(
        _point(_columns[index], _rows.first),
        _point(_columns[index], _rows.last),
        paint,
      );
    }
    for (var index = 0; index < _rows.length; index++) {
      paint.strokeWidth = index % 5 == 0 ? 4.0 : 2.1;
      canvas.drawLine(
        _point(_columns.first, _rows[index]),
        _point(_columns.last, _rows[index]),
        paint,
      );
    }

    // A few shorter streets break up the continuous grid.
    paint.strokeWidth = 2.4;
    final paths = [
      Path()
        ..moveTo(-12, 193)
        ..lineTo(72, 210)
        ..lineTo(124, 203),
      Path()
        ..moveTo(230, 52)
        ..lineTo(267, 109)
        ..lineTo(292, 170),
      Path()
        ..moveTo(286, 269)
        ..lineTo(319, 328)
        ..lineTo(375, 368),
      Path()
        ..moveTo(24, 485)
        ..lineTo(67, 501)
        ..lineTo(104, 536),
      Path()
        ..moveTo(195, 554)
        ..lineTo(223, 608)
        ..lineTo(236, 685),
    ];
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  void _paintParks(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFDFE6DD);
    final parks = [
      Path()
        ..moveTo(53, 380)
        ..lineTo(84, 392)
        ..quadraticBezierTo(96, 407, 85, 425)
        ..lineTo(72, 459)
        ..lineTo(32, 437)
        ..lineTo(39, 412)
        ..close(),
      Path()
        ..moveTo(32, 554)
        ..lineTo(78, 565)
        ..lineTo(88, 588)
        ..lineTo(74, 621)
        ..lineTo(21, 612)
        ..lineTo(20, 583)
        ..close(),
      Path()
        ..moveTo(324, 431)
        ..lineTo(350, 413)
        ..lineTo(371, 442)
        ..lineTo(348, 459)
        ..close(),
    ];
    for (final park in parks) {
      canvas.drawPath(park, paint);
    }

    final trail = Paint()
      ..color = const Color(0xFFEAF0E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(
      Path()
        ..moveTo(40, 430)
        ..quadraticBezierTo(64, 415, 78, 400),
      trail,
    );
    canvas.drawPath(
      Path()
        ..moveTo(27, 595)
        ..quadraticBezierTo(49, 591, 77, 575),
      trail,
    );
  }

  void _paintAvenues(Canvas canvas) {
    // Broad streets gently bend as they pass between neighbourhoods.
    final diagonal = Path()
      ..moveTo(-38, 337)
      ..cubicTo(23, 301, 69, 269, 126, 232)
      ..cubicTo(207, 178, 311, 108, 428, 26);
    final crossing = Path()
      ..moveTo(-35, 293)
      ..cubicTo(25, 321, 64, 365, 112, 380)
      ..cubicTo(169, 397, 193, 415, 230, 463)
      ..cubicTo(275, 519, 336, 556, 428, 603);
    final leftCurve = Path()
      ..moveTo(-56, 541)
      ..cubicTo(2, 491, 23, 418, 61, 359)
      ..cubicTo(84, 324, 119, 287, 158, 260);
    final upperCrossing = Path()
      ..moveTo(16, -44)
      ..cubicTo(64, 42, 143, 132, 189, 185)
      ..cubicTo(249, 254, 316, 335, 430, 427);
    final bottomCurve = Path()
      ..moveTo(-42, 603)
      ..cubicTo(82, 612, 116, 637, 218, 660)
      ..cubicTo(295, 677, 347, 689, 430, 719);

    _avenue(canvas, upperCrossing, 8);
    _avenue(canvas, leftCurve, 9);
    _avenue(canvas, diagonal, 10);
    _avenue(canvas, bottomCurve, 14);
    _avenue(canvas, crossing, 15);

    // The central avenue has a very pale divider, like a two-way boulevard.
    canvas.drawPath(
      crossing,
      Paint()
        ..color = const Color(0xFFE9ECE9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  void _avenue(Canvas canvas, Path path, double width) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    paint
      ..color = const Color(0xFFDDE1DE)
      ..strokeWidth = width + 2.4;
    canvas.drawPath(path, paint);
    paint
      ..color = const Color(0xFFF8FAF8)
      ..strokeWidth = width;
    canvas.drawPath(path, paint);

    // Fine parallel edges are already painted underneath the white road.
    // No shadows: the map should remain flat and unobtrusive.
  }

  @override
  bool shouldRepaint(_MapBackgroundPainter oldDelegate) {
    return oldDelegate.showParks != showParks;
  }
}
