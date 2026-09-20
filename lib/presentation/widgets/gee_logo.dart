import 'package:flutter/material.dart';
import 'package:gee_player/app/gee_colors.dart';

class GeeLogo extends StatelessWidget {
  const GeeLogo({super.key, this.size = 64, this.elevated = false});

  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Gee Player logo',
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.27),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: GeeColors.accent.withValues(alpha: 0.32),
                      blurRadius: size * 0.45,
                      offset: Offset(0, size * 0.12),
                    ),
                  ]
                : null,
          ),
          child: CustomPaint(painter: const _GeeLogoPainter()),
        ),
      ),
    );
  }
}

class _GeeLogoPainter extends CustomPainter {
  const _GeeLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final bounds = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(bounds, Radius.circular(side * 0.27));
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GeeColors.accentLight, GeeColors.accent, Color(0xFF235BD8)],
        ).createShader(bounds),
    );

    final play = Path()
      ..moveTo(side * 0.31, side * 0.21)
      ..quadraticBezierTo(side * 0.28, side * 0.18, side * 0.28, side * 0.25)
      ..lineTo(side * 0.28, side * 0.75)
      ..quadraticBezierTo(side * 0.28, side * 0.82, side * 0.34, side * 0.79)
      ..lineTo(side * 0.73, side * 0.55)
      ..quadraticBezierTo(side * 0.8, side * 0.5, side * 0.73, side * 0.45)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GeeLogoPainter oldDelegate) => false;
}
