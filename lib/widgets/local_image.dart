import 'package:flutter/material.dart';

class LocalImage extends StatelessWidget {
  const LocalImage({super.key, this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    if (imageUrl == null || imageUrl.isEmpty) return _placeholder();
    return Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Semantics(
      label: 'Local sem foto disponível',
      child: const ColoredBox(
        color: Color(0xFFD7D9D8),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: .46,
            heightFactor: .5,
            child: CustomPaint(painter: _LandscapePainter()),
          ),
        ),
      ),
    );
  }
}

class _LandscapePainter extends CustomPainter {
  const _LandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB5B9B7);
    canvas.drawCircle(
      Offset(size.width * .29, size.height * .18),
      size.shortestSide * .13,
      paint,
    );
    final mountains = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * .3, size.height * .55)
      ..lineTo(size.width * .43, size.height * .72)
      ..lineTo(size.width * .68, size.height * .28)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(mountains, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
