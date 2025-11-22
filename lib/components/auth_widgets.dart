import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Divider widget with "hoặc" text in the middle
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color:
                Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "hoặc",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color:
                Theme.of(context).colorScheme.inversePrimary.withOpacity(0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Google sign in button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const GoogleLogoIcon(size: 24),
        label: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleLogoPainter(),
      size: Size.square(size),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final redPaint = Paint()
      ..color = const Color(0xFFDB4437)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final yellowPaint = Paint()
      ..color = const Color(0xFFF4B400)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final greenPaint = Paint()
      ..color = const Color(0xFF0F9D58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, bluePaint);
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, false, greenPaint);
    canvas.drawArc(rect, 3 * math.pi / 4, math.pi / 2, false, yellowPaint);
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, false, redPaint);

    final barStart = Offset(size.width * 0.55, size.height * 0.55);
    final barEnd = Offset(size.width * 0.9, size.height * 0.55);
    canvas.drawLine(barStart, barEnd, bluePaint);

    final verticalStart = Offset(size.width * 0.9, size.height * 0.55);
    final verticalEnd = Offset(size.width * 0.9, size.height * 0.35);
    canvas.drawLine(verticalStart, verticalEnd, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Navigation link widget (e.g., "Chưa có tài khoản? Đăng ký ngay")
class AuthNavigationLink extends StatelessWidget {
  final String prefixText;
  final String linkText;
  final VoidCallback? onTap;

  const AuthNavigationLink({
    super.key,
    required this.prefixText,
    required this.linkText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          prefixText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
