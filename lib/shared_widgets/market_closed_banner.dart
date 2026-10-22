import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MarketClosedBanner extends StatelessWidget {
  final String? message;

  const MarketClosedBanner({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828).withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFC62828).withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.clock,
            size: 15,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ??
                  'Market is Closed • Prices may be STALE or CLOSED. Market orders are disabled.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
