import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class TicketQMark extends StatelessWidget {
  final double size;
  final bool elevated;

  const TicketQMark({
    super.key,
    this.size = 96,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo TICKET-Q',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: AppColors.brandNavyDeep.withValues(alpha: 0.22),
                    blurRadius: size * 0.22,
                    offset: Offset(0, size * 0.1),
                  ),
                ]
              : const [],
        ),
        child: CustomPaint(
          size: Size.square(size),
          painter: _TicketQMarkPainter(),
        ),
      ),
    );
  }
}

class _TicketQMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final ticketSize = shortest * 0.74;
    final ticketLeft = center.dx - ticketSize / 2;
    final ticketTop = center.dy - ticketSize / 2;
    final ticketRect = Rect.fromLTWH(
      ticketLeft,
      ticketTop,
      ticketSize,
      ticketSize,
    );
    final ticketRadius = Radius.circular(ticketSize * 0.18);
    final notchRadius = ticketSize * 0.09;

    final ticketPath = Path()
      ..addRRect(RRect.fromRectAndRadius(ticketRect, ticketRadius));
    final leftNotch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(ticketLeft, center.dy),
          radius: notchRadius,
        ),
      );
    final rightNotch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(ticketLeft + ticketSize, center.dy),
          radius: notchRadius,
        ),
      );
    final shapedTicket = Path.combine(
      PathOperation.difference,
      Path.combine(PathOperation.difference, ticketPath, leftNotch),
      rightNotch,
    );

    canvas.drawPath(
      shapedTicket,
      Paint()..color = AppColors.white,
    );

    final ringRect = Rect.fromCircle(
      center: center.translate(0, -ticketSize * 0.02),
      radius: ticketSize * 0.2,
    );
    canvas.drawArc(
      ringRect,
      math.pi * 0.2,
      math.pi * 1.75,
      false,
      Paint()
        ..color = AppColors.brandNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = ticketSize * 0.12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(center.dx + ticketSize * 0.11, center.dy + ticketSize * 0.1),
      Offset(center.dx + ticketSize * 0.26, center.dy + ticketSize * 0.24),
      Paint()
        ..color = AppColors.brandCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = ticketSize * 0.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
