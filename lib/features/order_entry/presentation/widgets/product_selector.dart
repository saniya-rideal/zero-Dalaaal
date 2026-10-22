import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/trading_colors.dart';
import '../../../../data/models/enums.dart';
import '../../../../data/models/instrument.dart';

class ProductSelector extends StatelessWidget {
  final Instrument instrument;
  final ProductType selectedProduct;
  final ValueChanged<ProductType> onProductChanged;

  const ProductSelector({
    super.key,
    required this.instrument,
    required this.selectedProduct,
    required this.onProductChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (instrument.isCryptoOrForex) {
      return const SizedBox.shrink();
    }

    final allowedProducts = instrument.effectiveAllowedProducts;
    if (allowedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.tradingColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF282D37) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product Type',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                ),
              ),
              Text(
                'Indian Markets',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: allowedProducts.map((prod) {
              final isSelected = selectedProduct == prod;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    prod.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colors.accent,
                  backgroundColor: isDark ? const Color(0xFF1E232E) : const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? colors.accent
                          : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  onSelected: (_) => onProductChanged(prod),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _getProductDescription(selectedProduct),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getProductDescription(ProductType type) {
    switch (type) {
      case ProductType.MIS:
        return 'MIS: Intraday position with leverage. Auto squared-off at 15:15 IST.';
      case ProductType.CNC:
        return 'CNC: Cash & Carry delivery with 100% upfront margin. Settled in Demat.';
      case ProductType.NRML:
        return 'NRML: Normal margin for carrying overnight F&O or Commodity derivatives.';
    }
  }
}
