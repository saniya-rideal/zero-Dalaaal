import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../data/models/option_strategy.dart';

/// A custom painter that renders a 2D option strategy payoff chart.
///
/// Features:
/// - P&L curve colored green (profit) / red (loss), split at zero
/// - Subtle filled area above/below the zero line
/// - Dashed vertical breakeven lines with labels
/// - Current spot price marker
/// - Axis tick labels (spot price + P&L in ₹)
class PayoffChartPainter extends CustomPainter {
  final List<PayoffPoint> points;
  final StrategyMetrics metrics;
  final double spotPrice;
  final Color bullishColor;
  final Color bearishColor;
  final Color axisColor;
  final Color gridColor;
  final Color textColor;

  static const double _paddingLeft = 64.0;
  static const double _paddingRight = 16.0;
  static const double _paddingTop = 16.0;
  static const double _paddingBottom = 40.0;

  const PayoffChartPainter({
    required this.points,
    required this.metrics,
    required this.spotPrice,
    required this.bullishColor,
    required this.bearishColor,
    required this.axisColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - _paddingLeft - _paddingRight;
    final chartH = size.height - _paddingTop - _paddingBottom;

    final minSpot = points.first.spot;
    final maxSpot = points.last.spot;
    final allPnl = points.map((p) => p.pnl).toList();
    final rawMinPnl = allPnl.reduce(math.min);
    final rawMaxPnl = allPnl.reduce(math.max);

    // Add 10% padding to P&L range
    final pnlRange = rawMaxPnl - rawMinPnl;
    final padding = pnlRange * 0.12;
    final minPnl = rawMinPnl - padding;
    final maxPnl = rawMaxPnl + padding;

    // Coordinate helpers
    Offset toCanvas(double spot, double pnl) {
      final x = _paddingLeft + (spot - minSpot) / (maxSpot - minSpot) * chartW;
      final y = _paddingTop + (1 - (pnl - minPnl) / (maxPnl - minPnl)) * chartH;
      return Offset(x, y);
    }

    final zeroY = _paddingTop + (1 - (0 - minPnl) / (maxPnl - minPnl)) * chartH;
    final zeroYClamped = zeroY.clamp(_paddingTop, _paddingTop + chartH);

    // ── Draw background grid lines ──────────────────────────────────────────
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = _paddingTop + (chartH / gridLines) * i;
      canvas.drawLine(
        Offset(_paddingLeft, y),
        Offset(_paddingLeft + chartW, y),
        gridPaint,
      );
    }

    // ── Zero line (highlight) ───────────────────────────────────────────────
    final zeroLinePaint = Paint()
      ..color = axisColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(_paddingLeft, zeroYClamped),
      Offset(_paddingLeft + chartW, zeroYClamped),
      zeroLinePaint,
    );

    // ── Filled area above zero (profit zone) ───────────────────────────────
    final profitFillPaint = Paint()
      ..color = bullishColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final lossFillPaint = Paint()
      ..color = bearishColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    _drawFilledArea(canvas, points, minSpot, maxSpot, minPnl, maxPnl,
        zeroYClamped, chartW, chartH, profitFillPaint, lossFillPaint);

    // ── Payoff curve (split at zero) ───────────────────────────────────────
    final profitPaint = Paint()
      ..color = bullishColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final lossPaint = Paint()
      ..color = bearishColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Path? profitPath;
    Path? lossPath;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final o = toCanvas(p.spot, p.pnl);

      if (p.pnl >= 0) {
        if (profitPath == null) {
          profitPath = Path()..moveTo(o.dx, o.dy);
        } else {
          profitPath.lineTo(o.dx, o.dy);
        }
        // Close loss path at zero crossing
        if (lossPath != null) {
          lossPath.lineTo(o.dx, zeroYClamped);
          canvas.drawPath(lossPath, lossPaint);
          lossPath = null;
          profitPath = Path()..moveTo(o.dx, zeroYClamped)..lineTo(o.dx, o.dy);
        }
      } else {
        if (lossPath == null) {
          lossPath = Path()..moveTo(o.dx, o.dy);
        } else {
          lossPath.lineTo(o.dx, o.dy);
        }
        // Close profit path at zero crossing
        if (profitPath != null) {
          profitPath.lineTo(o.dx, zeroYClamped);
          canvas.drawPath(profitPath, profitPaint);
          profitPath = null;
          lossPath = Path()..moveTo(o.dx, zeroYClamped)..lineTo(o.dx, o.dy);
        }
      }
    }
    if (profitPath != null) canvas.drawPath(profitPath, profitPaint);
    if (lossPath != null) canvas.drawPath(lossPath, lossPaint);

    // ── Breakeven vertical dashed lines ────────────────────────────────────
    for (final be in metrics.breakevens) {
      if (be >= minSpot && be <= maxSpot) {
        final x = _paddingLeft + (be - minSpot) / (maxSpot - minSpot) * chartW;
        _drawDashedLine(canvas, Offset(x, _paddingTop),
            Offset(x, _paddingTop + chartH), axisColor.withValues(alpha: 0.7));

        // BE label badge
        _drawLabel(
          canvas,
          '₹${_formatK(be)}',
          Offset(x, _paddingTop + chartH + 4),
          axisColor,
          textColor,
          fontSize: 9.5,
          center: true,
        );
      }
    }

    // ── Current spot vertical line ─────────────────────────────────────────
    if (spotPrice >= minSpot && spotPrice <= maxSpot) {
      final sx = _paddingLeft +
          (spotPrice - minSpot) / (maxSpot - minSpot) * chartW;
      final spotPaint = Paint()
        ..color = axisColor.withValues(alpha: 0.4)
        ..strokeWidth = 1.5;
      canvas.drawLine(
          Offset(sx, _paddingTop), Offset(sx, _paddingTop + chartH), spotPaint);
    }

    // ── Y-axis labels (P&L) ────────────────────────────────────────────────
    const yTicks = 5;
    final textStyle = TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 9.5);

    for (int i = 0; i <= yTicks; i++) {
      final pnlVal = minPnl + (maxPnl - minPnl) * (yTicks - i) / yTicks;
      final y = _paddingTop + (chartH / yTicks) * i;
      final tp = TextPainter(
        text: TextSpan(text: _formatPnl(pnlVal), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_paddingLeft - tp.width - 4, y - tp.height / 2));
    }

    // ── X-axis labels (Spot Price) ─────────────────────────────────────────
    const xTicks = 4;
    for (int i = 0; i <= xTicks; i++) {
      final spotVal = minSpot + (maxSpot - minSpot) * i / xTicks;
      final x = _paddingLeft + chartW * i / xTicks;
      final tp = TextPainter(
        text: TextSpan(text: _formatK(spotVal), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.drawLine(
        Offset(x, _paddingTop + chartH),
        Offset(x, _paddingTop + chartH + 4),
        Paint()..color = axisColor.withValues(alpha: 0.5)..strokeWidth = 1,
      );
      tp.paint(canvas,
          Offset(x - tp.width / 2, _paddingTop + chartH + 6));
    }

    // ── Axes ───────────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = axisColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    // Y-axis
    canvas.drawLine(
      const Offset(_paddingLeft, _paddingTop),
      Offset(_paddingLeft, _paddingTop + chartH),
      axisPaint,
    );
    // X-axis
    canvas.drawLine(
      Offset(_paddingLeft, _paddingTop + chartH),
      Offset(_paddingLeft + chartW, _paddingTop + chartH),
      axisPaint,
    );
  }

  void _drawFilledArea(
    Canvas canvas,
    List<PayoffPoint> pts,
    double minSpot,
    double maxSpot,
    double minPnl,
    double maxPnl,
    double zeroY,
    double chartW,
    double chartH,
    Paint profitPaint,
    Paint lossPaint,
  ) {
    Offset toC(double spot, double pnl) {
      final x = _paddingLeft + (spot - minSpot) / (maxSpot - minSpot) * chartW;
      final y = _paddingTop + (1 - (pnl - minPnl) / (maxPnl - minPnl)) * chartH;
      return Offset(x, y);
    }

    final profitPath = Path();
    final lossPath = Path();
    bool profitStarted = false;
    bool lossStarted = false;

    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      final o = toC(p.spot, p.pnl);

      if (p.pnl >= 0) {
        if (!profitStarted) {
          profitPath.moveTo(o.dx, zeroY);
          profitStarted = true;
        }
        profitPath.lineTo(o.dx, o.dy);
      } else {
        if (!lossStarted) {
          lossPath.moveTo(o.dx, zeroY);
          lossStarted = true;
        }
        lossPath.lineTo(o.dx, o.dy);
      }
    }

    if (profitStarted) {
      profitPath.lineTo(_paddingLeft + chartW, zeroY);
      profitPath.close();
      canvas.drawPath(profitPath, profitPaint);
    }
    if (lossStarted) {
      lossPath.lineTo(_paddingLeft + chartW, zeroY);
      lossPath.close();
      canvas.drawPath(lossPath, lossPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    const dashLen = 5.0;
    const gapLen = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len;
    final uy = dy / len;
    double drawn = 0;
    while (drawn < len) {
      final s = Offset(start.dx + ux * drawn, start.dy + uy * drawn);
      drawn += dashLen;
      final e = Offset(start.dx + ux * math.min(drawn, len),
          start.dy + uy * math.min(drawn, len));
      canvas.drawLine(s, e, paint);
      drawn += gapLen;
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position, Color bg,
      Color fg, {double fontSize = 10, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: center
          ? Offset(position.dx, position.dy + tp.height / 2)
          : Offset(position.dx + tp.width / 2, position.dy + tp.height / 2),
      width: tp.width + 6,
      height: tp.height + 4,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = bg.withValues(alpha: 0.15));
    tp.paint(
      canvas,
      center
          ? Offset(position.dx - tp.width / 2, position.dy)
          : position,
    );
  }

  String _formatK(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  String _formatPnl(double value) {
    if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(PayoffChartPainter oldDelegate) =>
      points != oldDelegate.points;
}

/// The Flutter widget wrapping [PayoffChartPainter].
class PayoffChart extends StatelessWidget {
  final List<PayoffPoint> points;
  final StrategyMetrics metrics;
  final double spotPrice;
  final double height;

  const PayoffChart({
    super.key,
    required this.points,
    required this.metrics,
    required this.spotPrice,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const bullish = Color(0xFF00C087);
    const bearish = Color(0xFFE53935);
    final axisColor = isDark ? Colors.white54 : Colors.black38;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: PayoffChartPainter(
          points: points,
          metrics: metrics,
          spotPrice: spotPrice,
          bullishColor: bullish,
          bearishColor: bearish,
          axisColor: axisColor,
          gridColor: gridColor,
          textColor: textColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
