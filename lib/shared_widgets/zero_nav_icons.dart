import 'package:flutter/material.dart';

class ZeroNavIcons {
  /// Tab 0: Quotes (Dual vertical arrows: Left arrow Up, Right arrow Down)
  static Widget quotesIcon({required Color color, double size = 22}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _QuotesIconPainter(color: color),
    );
  }

  /// Tab 1: Deals (3 vertical bars with $ symbol on right)
  static Widget dealsIcon({required Color color, double size = 22}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DealsIconPainter(color: color),
    );
  }

  /// Tab 2: Net Deals (3 vertical bars with $ and Sigma Σ symbol on right)
  static Widget netDealsIcon({required Color color, double size = 22}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NetDealsIconPainter(color: color),
    );
  }

  /// Tab 3: History (Clock face with counter-clockwise arrow at top-left and L hands)
  static Widget historyIcon({required Color color, double size = 22}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HistoryIconPainter(color: color),
    );
  }
}

class _QuotesIconPainter extends CustomPainter {
  final Color color;
  _QuotesIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left Arrow: Pointing UP
    const x1 = 8.0;
    canvas.drawLine(const Offset(x1, 19.5), const Offset(x1, 4.5), paint);
    canvas.drawLine(const Offset(x1 - 3.8, 8.5), const Offset(x1, 4.5), paint);
    canvas.drawLine(const Offset(x1 + 3.8, 8.5), const Offset(x1, 4.5), paint);

    // Right Arrow: Pointing DOWN
    const x2 = 16.0;
    canvas.drawLine(const Offset(x2, 4.5), const Offset(x2, 19.5), paint);
    canvas.drawLine(const Offset(x2 - 3.8, 15.5), const Offset(x2, 19.5), paint);
    canvas.drawLine(const Offset(x2 + 3.8, 15.5), const Offset(x2, 19.5), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QuotesIconPainter oldDelegate) => oldDelegate.color != color;
}

class _DealsIconPainter extends CustomPainter {
  final Color color;
  _DealsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 3 rounded vertical bars (Candlestick / bar chart)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2.5, 4.0, 3.8, 16.5), const Radius.circular(1.8)),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8.0, 9.0, 3.8, 11.5), const Radius.circular(1.8)),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(13.5, 12.0, 3.8, 8.5), const Radius.circular(1.8)),
      barPaint,
    );

    // Mini "$" text superscript on top right
    final textPainter = TextPainter(
      text: TextSpan(
        text: r'$',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, const Offset(16.5, 0.5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DealsIconPainter oldDelegate) => oldDelegate.color != color;
}

class _NetDealsIconPainter extends CustomPainter {
  final Color color;
  _NetDealsIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 3 rounded vertical bars
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2.5, 4.0, 3.8, 16.5), const Radius.circular(1.8)),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8.0, 9.0, 3.8, 11.5), const Radius.circular(1.8)),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(13.5, 12.0, 3.8, 8.5), const Radius.circular(1.8)),
      barPaint,
    );

    // Mini "$Σ" superscript on top right
    final textPainter = TextPainter(
      text: TextSpan(
        text: r'$Σ',
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, const Offset(16.0, 0.5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NetDealsIconPainter oldDelegate) => oldDelegate.color != color;
}

class _HistoryIconPainter extends CustomPainter {
  final Color color;
  _HistoryIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Clock Arc: Circle with radius 8.0 centered at (12.5, 13.0)
    final arcPath = Path();
    arcPath.addArc(
      Rect.fromCircle(center: const Offset(12.5, 13.0), radius: 8.0),
      -2.4, // starts at ~10 o'clock
      5.3,  // sweeps clockwise ~300° back to ~9 o'clock
    );
    canvas.drawPath(arcPath, paint);

    // 2. Counter-clockwise Arrowhead at top-left (pointing up-left)
    final arrowPath = Path();
    arrowPath.moveTo(5.0, 5.0);
    arrowPath.lineTo(7.0, 9.2);
    arrowPath.lineTo(11.2, 9.2);
    canvas.drawPath(arrowPath, paint);

    // 3. Clock Hands: Vertical 12 o'clock and Horizontal 3 o'clock (L shape)
    final handsPath = Path();
    handsPath.moveTo(12.5, 8.5);
    handsPath.lineTo(12.5, 13.0);
    handsPath.lineTo(16.5, 13.0);
    canvas.drawPath(handsPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HistoryIconPainter oldDelegate) => oldDelegate.color != color;
}
