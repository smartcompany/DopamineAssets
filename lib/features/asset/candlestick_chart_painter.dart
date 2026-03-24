import 'package:flutter/material.dart';

import '../../data/models/asset_chart_bar.dart';
import '../../theme/dopamine_theme.dart';

/// 일봉 OHLC 캔들 (좌→우 시간순).
class CandlestickChartPainter extends CustomPainter {
  CandlestickChartPainter({
    required this.bars,
    required this.bullColor,
    required this.bearColor,
    required this.gridColor,
  });

  final List<AssetChartBar> bars;
  final Color bullColor;
  final Color bearColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final minP = bars.map((e) => e.l).reduce((a, b) => a < b ? a : b);
    final maxP = bars.map((e) => e.h).reduce((a, b) => a > b ? a : b);
    var pad = (maxP - minP) * 0.06;
    if (pad <= 0 || !pad.isFinite) {
      pad = maxP * 0.002;
    }
    final lo = minP - pad;
    final hi = maxP + pad;
    final range = hi - lo;
    if (range <= 0 || !range.isFinite) return;

    final w = size.width;
    final h = size.height;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = h * i / gridLines;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    final n = bars.length;
    final slot = w / n;
    final bodyW = (slot * 0.62).clamp(1.0, 12.0);

    double yFor(double price) => h - (price - lo) / range * h;

    for (var i = 0; i < n; i++) {
      final e = bars[i];
      final cx = (i + 0.5) * slot;
      final bull = e.c >= e.o;
      final color = bull ? bullColor : bearColor;

      final yHi = yFor(e.h);
      final yLo = yFor(e.l);
      final yOpen = yFor(e.o);
      final yClose = yFor(e.c);

      canvas.drawLine(
        Offset(cx, yHi),
        Offset(cx, yLo),
        Paint()
          ..color = color
          ..strokeWidth = 1.2,
      );

      final top = yOpen < yClose ? yOpen : yClose;
      final bottom = yOpen > yClose ? yOpen : yClose;
      final bodyH = (bottom - top).clamp(1.0, h);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, top + bodyH / 2),
            width: bodyW,
            height: bodyH,
          ),
          const Radius.circular(1),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickChartPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.bullColor != bullColor ||
        oldDelegate.bearColor != bearColor ||
        oldDelegate.gridColor != gridColor;
  }
}

Color candleGridLineColor() {
  return DopamineTheme.textSecondary.withValues(alpha: 0.18);
}
