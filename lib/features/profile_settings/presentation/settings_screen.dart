import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../data/mock/legal_documents.dart';
import '../../../data/mock/settings_repository.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

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
    final repo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const ZeroDrawer(activeRoute: '/settings'),
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colors.textPrimary, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                  _buildSectionHeader('Profile', colors),
                  _buildNavRow(
                    icon: Icons.password,
                    title: 'Change Passwords',
                    onTap: () => _showChangePasswordSheet(context, repo, colors),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.phonelink_lock_outlined,
                    title: 'Enable two-factor authentication',
                    value: settings.twoFactorEnabled,
                    onChanged: (val) => repo.setTwoFactorEnabled(val),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.person_remove_outlined,
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
                    icon: Icons.wb_sunny_outlined,
                    title: 'Dark Theme',
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (isDark) {
                      repo.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                    },
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.screen_lock_portrait_outlined,
                    title: 'Keep Screen Awake',
                    value: settings.keepScreenAwake,
                    onChanged: (val) => repo.setKeepScreenAwake(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.volume_off_outlined,
                    title: 'Mute All Sounds',
                    value: settings.muteAllSounds,
                    onChanged: (val) => repo.setMuteAllSounds(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.all_inclusive,
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
                    icon: Icons.table_rows_outlined,
                    title: 'Quotes Grouping',
                    value: settings.quotesGrouping,
                    onChanged: (val) => repo.setQuotesGrouping(val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.bookmark_border_outlined,
                    title: 'Show Sticky Scripts',
                    value: settings.showStickyScripts,
                    onChanged: (val) => repo.setShowStickyScripts(val),
                    colors: colors,
                  ),

                  const SizedBox(height: 12),

                  // ================= 4. SUPPORT SECTION =================
                  _buildSectionHeader('Support', colors),
                  _buildNavRow(
                    icon: Icons.assignment_outlined,
                    title: 'Terms and Conditions',
                    onTap: () => _showDocumentViewer(context, LegalDocuments.termsAndConditions, colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.help_outline,
                    title: 'Help',
                    onTap: () => context.push('/help'),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showDocumentViewer(context, LegalDocuments.privacyPolicy, colors),
                    colors: colors,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header Widget ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Nav Row with Chevron ──────────────────────────────────────────────────
  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: colors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 24, color: colors.textPrimary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  // ─── Switch Row ───────────────────────────────────────────────────────────
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
          Icon(icon, size: 24, color: colors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFE53935),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colors.textSecondary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ─── Language Row with Dropdown ───────────────────────────────────────────
  Widget _buildLanguageRow({
    required AppLanguage currentLanguage,
    required ValueChanged<AppLanguage> onLanguageChanged,
    required TradingColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.translate, size: 24, color: colors.textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Language',
              style: GoogleFonts.inter(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<AppLanguage>(
              value: currentLanguage,
              dropdownColor: colors.cardBackground,
              icon: Icon(Icons.arrow_drop_down, color: colors.textPrimary, size: 20),
              items: AppLanguage.values.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(
                    lang.displayName.split(' ').first,
                    style: GoogleFonts.inter(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onLanguageChanged(val);
              },
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
              Icon(Icons.functions, size: 24, color: colors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'One-Click / Default Amount',
                  style: GoogleFonts.inter(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Minus circle
              GestureDetector(
                onTap: () {
                  final next = (amount - 0.1).clamp(0.0, 100.0);
                  onChanged(double.parse(next.toStringAsFixed(1)));
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              // Plus circle
              GestureDetector(
                onTap: () {
                  final next = (amount + 0.1).clamp(0.0, 100.0);
                  onChanged(double.parse(next.toStringAsFixed(1)));
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              'The default amount for one-click trading from Quotes tab and Trade screen. Put 0 to make it as Min Amount Per Deal per script',
              style: GoogleFonts.inter(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
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
            Text('Change Passwords', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
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
                backgroundColor: const Color(0xFFE53935),
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
                    Icon(Icons.warning_amber_rounded, color: colors.bearish, size: 28),
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
                  child: Text(
                    '⚠️ Statutory Retention Notice: Under Section 12 of the PMLA Act, 2002 and SEBI guidelines, KYC documents and trade logs must be preserved for 5 years after account deletion.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: colors.textPrimary, height: 1.35),
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
  void _showDocumentViewer(BuildContext context, LegalDocumentItem doc, TradingColors colors) {
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
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: colors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Text(
                '${doc.subtitle} • Last updated: ${doc.lastUpdated}',
                style: GoogleFonts.inter(fontSize: 11.5, color: colors.textSecondary),
              ),
              const Divider(height: 24),
              Text(
                doc.content,
                style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: colors.textPrimary),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
