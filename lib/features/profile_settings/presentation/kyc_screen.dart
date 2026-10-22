import 'package:flutter/material.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import 'kyc_management_sheet.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'KYC Verification',
          style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(
        child: KycManagementSheet(),
      ),
    );
  }
}
