import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../auth/presentation/auth_controller.dart';

class KycManagementSheet extends ConsumerStatefulWidget {
  const KycManagementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KycManagementSheet(),
    );
  }

  @override
  ConsumerState<KycManagementSheet> createState() => _KycManagementSheetState();
}

class _KycManagementSheetState extends ConsumerState<KycManagementSheet> {
  String _kycStatus = 'VERIFIED'; // 'VERIFIED', 'PENDING', 'REJECTED'
  String _selectedDocType = 'PAN Card';
  String? _uploadedFileName = 'pan_card_front.jpg';
  int _uploadedFileSizeKb = 1420;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _validationError;

  void _simulateUpload() {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _validationError = null;
    });

    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_uploadProgress < 1.0) {
        setState(() => _uploadProgress += 0.2);
      } else {
        timer.cancel();
        setState(() {
          _isUploading = false;
          _uploadedFileName = '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_upload.pdf';
          _uploadedFileSizeKb = 1850;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedDocType uploaded successfully. Under review.'),
            backgroundColor: const Color(0xFF00A854),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final authState = ref.watch(authControllerProvider);
    final pan = authState.session?.profile.pan ?? 'ABCDE1234F';

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Identity & KYC Verification',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // KYC Status Badge Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(colors),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _getStatusBorderColor(colors)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_getStatusIcon(), color: _getStatusTextColor(colors), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Status: $_kycStatus',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _getStatusTextColor(colors),
                              ),
                            ),
                          ],
                        ),
                        // Status Switcher (For testing states)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.tune, size: 18, color: _getStatusTextColor(colors)),
                          onSelected: (val) => setState(() => _kycStatus = val),
                          itemBuilder: (_) => ['VERIFIED', 'PENDING', 'REJECTED'].map((s) {
                            return PopupMenuItem(value: s, child: Text(s));
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(),
                      style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary),
                    ),
                    if (_kycStatus == 'REJECTED') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.bearish.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rejection Reason: Name mismatch between Aadhaar and PAN Card. Please re-upload valid government proof.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: colors.bearish, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section: KYC Documents Upload
              Text(
                'Upload Identification Documents',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Document Type Selector
              DropdownButtonFormField<String>(
                value: _selectedDocType,
                dropdownColor: colors.cardBackground,
                decoration: InputDecoration(
                  labelText: 'Document Type',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['PAN Card', 'Aadhaar Card (Front & Back)', 'Passport', 'Driving License', 'Bank Proof / Cheque']
                    .map((doc) => DropdownMenuItem(value: doc, child: Text(doc, style: TextStyle(color: colors.textPrimary, fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDocType = val);
                },
              ),

              const SizedBox(height: 14),

              // Document Upload Box / Preview
              if (_uploadedFileName != null && !_isUploading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.description, color: colors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uploadedFileName!,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_uploadedFileSizeKb / 1024).toStringAsFixed(1)} MB • Verified & Encrypted',
                              style: GoogleFonts.inter(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Replace', style: TextStyle(fontSize: 12)),
                        onPressed: _simulateUpload,
                      ),
                    ],
                  ),
                ),
              ] else if (_isUploading) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('Uploading $_selectedDocType (${(_uploadProgress * 100).toInt()}%)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: colors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text('Upload $_selectedDocType (JPG, PNG, PDF < 5MB)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _simulateUpload,
                ),
              ],

              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(_validationError!, style: GoogleFonts.inter(fontSize: 11.5, color: colors.bearish)),
              ],

              const SizedBox(height: 18),

              // Existing Verified Identifiers List
              _buildVerifiedRow('Permanent Account Number (PAN)', pan, colors),
              _buildVerifiedRow('Aadhaar Number (UIDAI)', '•••• •••• 9812', colors),
              _buildVerifiedRow('e-KYC CKYC Number', 'IN-CKYC-2024-81923', colors),

              const SizedBox(height: 20),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedRow(String title, String value, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary)),
          Row(
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF00A854)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(TradingColors colors) {
    switch (_kycStatus) {
      case 'VERIFIED':
        return colors.bullish.withValues(alpha: 0.12);
      case 'PENDING':
        return const Color(0xFFF5A623).withValues(alpha: 0.12);
      case 'REJECTED':
        return colors.bearish.withValues(alpha: 0.12);
      default:
        return colors.surface;
    }
  }

  Color _getStatusBorderColor(TradingColors colors) {
    switch (_kycStatus) {
      case 'VERIFIED':
        return colors.bullish.withValues(alpha: 0.4);
      case 'PENDING':
        return const Color(0xFFF5A623).withValues(alpha: 0.4);
      case 'REJECTED':
        return colors.bearish.withValues(alpha: 0.4);
      default:
        return colors.divider;
    }
  }

  Color _getStatusTextColor(TradingColors colors) {
    switch (_kycStatus) {
      case 'VERIFIED':
        return colors.bullish;
      case 'PENDING':
        return const Color(0xFFE65100);
      case 'REJECTED':
        return colors.bearish;
      default:
        return colors.textPrimary;
    }
  }

  IconData _getStatusIcon() {
    switch (_kycStatus) {
      case 'VERIFIED':
        return Icons.verified_user;
      case 'PENDING':
        return Icons.pending_actions;
      case 'REJECTED':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription() {
    switch (_kycStatus) {
      case 'VERIFIED':
        return 'Your CKYC and Aadhaar/PAN validation are fully approved. All exchange trading permissions active.';
      case 'PENDING':
        return 'Documents submitted. KRA / CKYC verification is under standard 24-hour review.';
      case 'REJECTED':
        return 'Your KYC application was rejected. Please re-upload correct proofs.';
      default:
        return '';
    }
  }
}
