import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/quote.dart';

class QuoteStatusBadge extends StatelessWidget {
  final QuoteStatus status;
  final double fontSize;

  const QuoteStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case QuoteStatus.live:
        fg = const Color(0xFF00A854);
        bg = const Color(0xFF00A854).withValues(alpha: 0.12);
        border = const Color(0xFF00A854).withValues(alpha: 0.35);
        break;
      case QuoteStatus.delayed:
        fg = const Color(0xFFF57C00);
        bg = const Color(0xFFF57C00).withValues(alpha: 0.12);
        border = const Color(0xFFF57C00).withValues(alpha: 0.35);
        break;
      case QuoteStatus.stale:
        fg = const Color(0xFF9E9E9E);
        bg = const Color(0xFF9E9E9E).withValues(alpha: 0.15);
        border = const Color(0xFF9E9E9E).withValues(alpha: 0.35);
        break;
      case QuoteStatus.closed:
        fg = const Color(0xFFE53935);
        bg = const Color(0xFFE53935).withValues(alpha: 0.12);
        border = const Color(0xFFE53935).withValues(alpha: 0.35);
        break;
      case QuoteStatus.simulated:
        fg = const Color(0xFF1E88E5);
        bg = const Color(0xFF1E88E5).withValues(alpha: 0.12);
        border = const Color(0xFF1E88E5).withValues(alpha: 0.35);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
