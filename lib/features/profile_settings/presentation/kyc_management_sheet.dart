import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/kyc_repository.dart';

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
  late final TextEditingController _panNumberController;
  late final TextEditingController _aadhaarNumberController;
  bool _isUploading = false;
  String? _uploadingDocType;
  String? _uploadedPanUrl;
  String? _uploadedAadhaarUrl;
  String? _panFileName;
  String? _aadhaarFileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).session?.profile;
    _panNumberController = TextEditingController(text: profile?.pan ?? '');
    _aadhaarNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _panNumberController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  Future<void> _uploadDocument(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    List<int>? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {}
    }

    if (bytes == null || bytes.isEmpty) {
      setState(() => _errorMessage = 'Unable to read selected file data.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadingDocType = docType;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(kycRepositoryProvider);
      final base64Data = base64Encode(bytes);
      final uploadRes = await repo.uploadDocument(
        documentType: docType,
        fileName: file.name,
        fileData: base64Data,
      );

      final fileUrl = (uploadRes['url'] ??
              uploadRes['document']?['url'] ??
              uploadRes['fileUrl'] ??
              '')
          .toString();

      final resolvedUrl = fileUrl.isNotEmpty
          ? fileUrl
          : '/uploads/kyc/$docType/${file.name}';

      if (docType == 'PAN') {
        _uploadedPanUrl = resolvedUrl;
        _panFileName = file.name;
      } else {
        _uploadedAadhaarUrl = resolvedUrl;
        _aadhaarFileName = file.name;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docType document (${file.name}) uploaded successfully.'),
            backgroundColor: const Color(0xFF00A854),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Upload failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingDocType = null;
        });
      }
    }
  }

  Future<void> _submitKyc() async {
    final pan = _panNumberController.text.trim();
    final aadhaar = _aadhaarNumberController.text.trim();

    if (pan.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid 10-character PAN number.');
      return;
    }
    if (aadhaar.isEmpty) {
      setState(() => _errorMessage = 'Please enter your 12-digit Aadhaar number.');
      return;
    }
    if (_uploadedPanUrl == null) {
      setState(() => _errorMessage = 'Please pick and attach your PAN document image/PDF.');
      return;
    }
    if (_uploadedAadhaarUrl == null) {
      setState(() => _errorMessage = 'Please pick and attach your Aadhaar document image/PDF.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(kycRepositoryProvider);
      final profile = ref.read(authControllerProvider).session?.profile;

      await repo.submitKyc(
        panNumber: pan,
        panDocumentUrl: _uploadedPanUrl!,
        aadhaarNumber: aadhaar,
        aadhaarDocumentUrl: _uploadedAadhaarUrl!,
        fullName: profile?.name.isNotEmpty == true ? profile!.name : 'Verified Trader',
        dob: profile?.dob ?? '1995-01-01',
        address: profile?.address?.isNotEmpty == true ? profile!.address! : 'Registered Demat Address',
      );

      ref.invalidate(kycStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC documents submitted for compliance review.'),
            backgroundColor: Color(0xFF00A854),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Submission failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final kycAsync = ref.watch(kycStatusProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KYC Verification',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'SEBI / KRA Identity & Address Compliance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              kycAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bearish.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 18, color: colors.bearish),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load KYC status: $err',
                          style: TextStyle(color: colors.bearish, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(kycStatusProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (kyc) {
                  final status = kyc.status.toUpperCase();
                  final isApproved = status == 'APPROVED' || status == 'VERIFIED';
                  final isUnderReview = status == 'SUBMITTED' || status == 'UNDER_REVIEW';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status, colors),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getStatusBorderColor(status, colors)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isApproved
                                  ? LucideIcons.badgeCheck
                                  : isUnderReview
                                      ? LucideIcons.clock
                                      : LucideIcons.alertCircle,
                              color: _getStatusColor(status, colors),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: $status',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _getStatusColor(status, colors),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isApproved
                                        ? 'Your identity is fully verified with the regulatory KYC database.'
                                        : isUnderReview
                                            ? 'Your documents have been submitted and are under compliance review.'
                                            : 'Please submit your PAN & Aadhaar details to activate trading.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.bearish.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colors.bearish, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Form Fields
                      if (!isApproved) ...[
                        TextField(
                          controller: _panNumberController,
                          decoration: InputDecoration(
                            labelText: 'PAN Number',
                            hintText: 'ABCDE1234F',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _aadhaarNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Aadhaar Number (12 digits)',
                            hintText: '123456789012',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Document Upload Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploading ? null : () => _uploadDocument('PAN'),
                                icon: _isUploading && _uploadingDocType == 'PAN'
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(_uploadedPanUrl != null ? LucideIcons.check : LucideIcons.upload, size: 16),
                                label: Text(
                                  _isUploading && _uploadingDocType == 'PAN'
                                      ? 'Uploading...'
                                      : (_panFileName != null ? 'PAN: $_panFileName' : 'Attach PAN'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isUploading ? null : () => _uploadDocument('AADHAAR'),
                                icon: _isUploading && _uploadingDocType == 'AADHAAR'
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(_uploadedAadhaarUrl != null ? LucideIcons.check : LucideIcons.upload, size: 16),
                                label: Text(
                                  _isUploading && _uploadingDocType == 'AADHAAR'
                                      ? 'Uploading...'
                                      : (_aadhaarFileName != null ? 'Aadhaar: $_aadhaarFileName' : 'Attach Aadhaar'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _isUploading ? null : _submitKyc,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('SUBMIT KYC FOR REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusBgColor(String status, TradingColors colors) {
    if (status == 'APPROVED' || status == 'VERIFIED') return colors.bullish.withValues(alpha: 0.08);
    if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') return Colors.orange.withValues(alpha: 0.08);
    if (status == 'REJECTED') return colors.bearish.withValues(alpha: 0.08);
    return colors.surface;
  }

  Color _getStatusBorderColor(String status, TradingColors colors) {
    if (status == 'APPROVED' || status == 'VERIFIED') return colors.bullish.withValues(alpha: 0.3);
    if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') return Colors.orange.withValues(alpha: 0.3);
    if (status == 'REJECTED') return colors.bearish.withValues(alpha: 0.3);
    return colors.divider;
  }

  Color _getStatusColor(String status, TradingColors colors) {
    if (status == 'APPROVED' || status == 'VERIFIED') return colors.bullish;
    if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') return Colors.orange;
    if (status == 'REJECTED') return colors.bearish;
    return colors.textSecondary;
  }
}
