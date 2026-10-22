import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/trading_colors.dart';
import '../data/app_config_repository.dart';
import '../data/settings_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';
import '../../auth/data/real_auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final settings = ref.watch(appSettingsProvider);
    final repo = ref.read(settingsRepositoryProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/settings'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved successfully.'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/quotes');
            }
          },
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(LucideIcons.menu, color: colors.textPrimary, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Public & Private News Ticker Strip
          NewsTickerStrip(
            onPublicNewsTap: () => context.push('/news'),
            onPrivateNewsTap: () => context.push('/mails'),
          ),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Main Scrollable Settings Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= 1. PROFILE SECTION =================
                  _buildSectionHeader('Profile & Security', colors),
                  _buildNavRow(
                    icon: LucideIcons.keyRound,
                    title: 'Change Password',
                    onTap: () => _showChangePasswordSheet(context, repo, colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: LucideIcons.shieldCheck,
                    title: 'Change Security PIN',
                    onTap: () => _showChangePinSheet(context, colors),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.smartphone,
                    title: 'Enable Two-Factor Authentication',
                    value: settings.twoFactorEnabled,
                    onChanged: (val) => repo.setTwoFactorEnabled(val),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: LucideIcons.userX,
                    title: 'Delete My User',
                    onTap: () => _showAccountDeletionSheet(context, repo, colors),
                    colors: colors,
                  ),

                  const SizedBox(height: 12),

                  // ================= 2. GENERAL SECTION =================
                  _buildSectionHeader('General', colors),
                  _buildLanguageRow(
                    currentLanguage: settings.language,
                    onLanguageChanged: (lang) => repo.setLanguage(lang),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.sun,
                    title: 'Dark Theme',
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (isDark) {
                      repo.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                    },
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.smartphone,
                    title: 'Keep Screen Awake',
                    value: settings.keepScreenAwake,
                    onChanged: (val) => repo.setKeepScreenAwake(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.volumeX,
                    title: 'Mute All Sounds',
                    value: settings.muteAllSounds,
                    onChanged: (val) => repo.setMuteAllSounds(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.infinity,
                    title: 'Open From Where We Left?',
                    value: settings.openWhereLeft,
                    onChanged: (val) => repo.setOpenWhereLeft(val),
                    colors: colors,
                  ),

                  const SizedBox(height: 12),

                  // ================= 3. TRADING SECTION =================
                  _buildSectionHeader('Trading', colors),
                  _buildOneClickAmountRow(
                    amount: settings.defaultLots,
                    onChanged: (newAmount) => repo.setDefaultLots(newAmount),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.layoutGrid,
                    title: 'Quotes Grouping',
                    value: settings.quotesGrouping,
                    onChanged: (val) => repo.setQuotesGrouping(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: LucideIcons.pin,
                    title: 'Show Sticky Scripts',
                    value: settings.showStickyScripts,
                    onChanged: (val) => repo.setShowStickyScripts(val),
                    colors: colors,
                  ),

                  const SizedBox(height: 12),

                  // ================= 4. SUPPORT SECTION =================
                  _buildSectionHeader('Support', colors),
                  _buildNavRow(
                    icon: LucideIcons.fileText,
                    title: 'Terms and Conditions',
                    onTap: () => _showDocumentViewer(context, 'terms-and-conditions', 'Terms and Conditions', colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: LucideIcons.helpCircle,
                    title: 'Help',
                    onTap: () => context.push('/help'),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: LucideIcons.info,
                    title: 'About Zero',
                    onTap: () => context.push('/about'),
                    colors: colors,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ─── Standard Navigation Row ──────────────────────────────────────────────
  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Icon(icon, size: 20, color: colors.textPrimary),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
      onTap: onTap,
    );
  }

  // ─── Standard Switch Row ──────────────────────────────────────────────────
  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TradingColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: colors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ─── Language Selector Dropdown Row ───────────────────────────────────────
  Widget _buildLanguageRow({
    required AppLanguage currentLanguage,
    required ValueChanged<AppLanguage> onLanguageChanged,
    required TradingColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(LucideIcons.globe, size: 20, color: colors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Language',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: currentLanguage,
                isDense: true,
                dropdownColor: colors.cardBackground,
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onLanguageChanged(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── One-Click / Default Amount Stepper ────────────────────────────────────
  Widget _buildOneClickAmountRow({
    required double amount,
    required ValueChanged<double> onChanged,
    required TradingColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calculator, size: 20, color: colors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'One-Click / Default Lots',
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final next = (amount - 0.1).clamp(0.0, 100.0);
                  onChanged(double.parse(next.toStringAsFixed(1)));
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Center(child: Icon(LucideIcons.minus, size: 14, color: colors.textPrimary)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  amount.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final next = (amount + 0.1).clamp(0.0, 100.0);
                  onChanged(double.parse(next.toStringAsFixed(1)));
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Center(child: Icon(LucideIcons.plus, size: 14, color: colors.textPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Change Password Sheet ────────────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext context, SettingsRepository repo, TradingColors colors) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change Password', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 14),
            TextField(
              controller: oldPass,
              obscureText: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: const InputDecoration(labelText: 'New Password (min 8 chars)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                if (newPass.text.length < 8) {
                  _showToast('New password must be at least 8 characters.');
                  return;
                }
                if (newPass.text != confirmPass.text) {
                  _showToast('Passwords do not match.');
                  return;
                }
                final success = repo.changePassword(oldPassword: oldPass.text, newPassword: newPass.text);
                if (success) {
                  Navigator.pop(ctx);
                  _showToast('Password updated successfully!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('UPDATE PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Change Security PIN Sheet ────────────────────────────────────────────
  void _showChangePinSheet(BuildContext context, TradingColors colors) {
    final currentPin = TextEditingController();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Change Security PIN', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: currentPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(color: colors.textPrimary),
                decoration: const InputDecoration(labelText: 'Current 6-digit PIN', counterText: '', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(color: colors.textPrimary),
                decoration: const InputDecoration(labelText: 'New 6-digit PIN', counterText: '', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(color: colors.textPrimary),
                decoration: const InputDecoration(labelText: 'Confirm New 6-digit PIN', counterText: '', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (currentPin.text.length != 6) {
                    _showToast('Current PIN must be 6 digits.');
                    return;
                  }
                  if (newPin.text.length != 6) {
                    _showToast('New PIN must be 6 digits.');
                    return;
                  }
                  if (newPin.text != confirmPin.text) {
                    _showToast('New PINs do not match.');
                    return;
                  }

                  setModalState(() => isSubmitting = true);
                  try {
                    final authRepo = ref.read(authRepositoryProvider);
                    final success = await authRepo.changePin(
                      currentPin: currentPin.text.trim(),
                      newPin: newPin.text.trim(),
                    );
                    if (success && mounted) {
                      Navigator.pop(ctx);
                      _showToast('Security PIN updated successfully!');
                    }
                  } catch (e) {
                    _showToast(e.toString());
                  } finally {
                    if (mounted) setModalState(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('UPDATE PIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Delete Account Sheet ─────────────────────────────────────────────────
  void _showAccountDeletionSheet(BuildContext context, SettingsRepository repo, TradingColors colors) {
    String selectedReason = 'Switching to another broker';
    final reasons = [
      'Switching to another broker',
      'High market volatility / Taking trading break',
      'Relocating abroad / NRI status',
      'Trading platform dissatisfaction',
      'Other personal reasons',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: colors.bearish, size: 26),
                    const SizedBox(width: 8),
                    Text('Delete My User', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Before account deletion, ensure all open positions are squared off and Demat holdings are transferred.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: colors.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 16, color: colors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Statutory Retention Notice: Under Section 12 of the PMLA Act, 2002 and SEBI guidelines, KYC documents and trade logs must be preserved for 5 years after account deletion.',
                          style: GoogleFonts.inter(fontSize: 11.5, color: colors.textPrimary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('Reason for Deletion', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  isExpanded: true,
                  dropdownColor: colors.cardBackground,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 12.5, color: colors.textPrimary)))).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await repo.requestAccountDeletion(reason: selectedReason);
                    _showToast('User deletion request registered. Confirmation sent to email.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.bearish,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('SUBMIT DELETION REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Legal Document Viewer ────────────────────────────────────────────────
  void _showDocumentViewer(BuildContext context, String slug, String title, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => FutureBuilder<String>(
          future: ref.read(appConfigRepositoryProvider).getLegalDocument(slug),
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
                        ),
                      ),
                      IconButton(icon: Icon(LucideIcons.x, color: colors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(height: 24),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (snapshot.hasError)
                    Text('Failed to load legal document: ${snapshot.error}', style: TextStyle(color: colors.bearish))
                  else
                    Text(
                      snapshot.data ?? 'Document not available.',
                      style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textPrimary),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
