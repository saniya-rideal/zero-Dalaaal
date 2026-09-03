import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../shared_widgets/news_ticker_strip.dart';
import '../../../shared_widgets/script_selector_bar.dart';
import '../../../shared_widgets/zero_bottom_nav_bar.dart';
import '../../../shared_widgets/zero_drawer.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Profile settings
  bool _enable2FA = false;
  bool _biometricLogin = false;

  // General settings
  String _selectedLanguage = 'English';
  bool _keepScreenAwake = true;
  bool _muteAllSounds = false;
  bool _openWhereLeft = true;

  // Trading settings
  double _defaultAmount = 0.0;
  bool _quotesGrouping = false;
  bool _showStickyScripts = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

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
          const NewsTickerStrip(),

          // Dual Script Selector Bar
          const ScriptSelectorBar(),

          // Main Scrollable Settings Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ================= SECTION 1: PROFILE =================
                  _buildSectionTitle('Profile', colors),
                  _buildNavRow(
                    icon: Icons.lock_outline,
                    title: 'Change Passwords',
                    onTap: () => _showChangePasswordSheet(context, colors),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.phonelink_lock_outlined,
                    title: 'Enable two-factor authentication',
                    value: _enable2FA,
                    onChanged: (val) {
                      setState(() => _enable2FA = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? '2FA Enabled' : '2FA Disabled'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.fingerprint,
                    title: 'Biometric Login',
                    value: _biometricLogin,
                    onChanged: (val) {
                      setState(() => _biometricLogin = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Biometric Login Enabled' : 'Biometric Login Disabled'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.devices_outlined,
                    title: 'Active Devices & Sessions',
                    onTap: () => _showDeviceManagementSheet(context, colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.person_remove_outlined,
                    title: 'Delete My User',
                    onTap: () => _showDeleteUserDialog(context, colors),
                    colors: colors,
                  ),

                  const SizedBox(height: 16),

                  // ================= SECTION 2: GENERAL =================
                  _buildSectionTitle('General', colors),
                  _buildLanguageRow(context, colors),
                  _buildSwitchRow(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Dark Theme',
                    value: isDark,
                    onChanged: (val) {
                      ref.read(themeModeProvider.notifier).state =
                          val ? ThemeMode.dark : ThemeMode.light;
                    },
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.screen_lock_portrait_outlined,
                    title: 'Keep Screen Awake',
                    value: _keepScreenAwake,
                    onChanged: (val) => setState(() => _keepScreenAwake = val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.volume_off_outlined,
                    title: 'Mute All Sounds',
                    value: _muteAllSounds,
                    onChanged: (val) => setState(() => _muteAllSounds = val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.wifi_off_outlined,
                    title: 'Simulate Offline Mode (Demo)',
                    value: ref.watch(isOfflineProvider),
                    onChanged: (val) {
                      ref.read(connectivityServiceProvider.notifier).setSimulatedOffline(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Offline mode simulated' : 'Online mode restored'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.all_inclusive_outlined,
                    title: 'Open From Where We Left?',
                    value: _openWhereLeft,
                    onChanged: (val) => setState(() => _openWhereLeft = val),
                    colors: colors,
                  ),

                  const SizedBox(height: 16),

                  // ================= SECTION 3: TRADING =================
                  _buildSectionTitle('Trading', colors),
                  _buildAmountStepperRow(context, colors),
                  _buildSwitchRow(
                    icon: Icons.layers_outlined,
                    title: 'Quotes Grouping',
                    value: _quotesGrouping,
                    onChanged: (val) => setState(() => _quotesGrouping = val),
                    colors: colors,
                  ),
                  _buildSwitchRow(
                    icon: Icons.tab_unselected_outlined,
                    title: 'Show Sticky Scripts',
                    value: _showStickyScripts,
                    onChanged: (val) => setState(() => _showStickyScripts = val),
                    colors: colors,
                  ),

                  const SizedBox(height: 16),

                  // ================= SECTION 4: SUPPORT =================
                  _buildSectionTitle('Support', colors),
                  _buildNavRow(
                    icon: Icons.description_outlined,
                    title: 'Terms and Conditions',
                    onTap: () => _showTermsDialog(context, colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.help_outline,
                    title: 'Help',
                    onTap: () => _showHelpDialog(context, colors),
                    colors: colors,
                  ),
                  _buildNavRow(
                    icon: Icons.security,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyPolicyDialog(context, colors),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ZeroBottomNavBar(
        currentIndex: 0,
        isExpanded: false,
        onCenterToggle: () {},
        onTabSelected: (index) {
          if (index == 0) context.go('/quotes');
          if (index == 1) context.go('/deals');
          if (index == 2) context.go('/net-deals');
          if (index == 3) context.go('/history');
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required TradingColors colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: Icon(icon, color: colors.textPrimary, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textPrimary, size: 24),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TradingColors colors,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      leading: Icon(icon, color: colors.textPrimary, size: 24),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFFE82B57), // 1:1 Vibrant Crimson / Pink track
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: colors.surface,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLanguageRow(BuildContext context, TradingColors colors) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: Icon(Icons.translate_outlined, color: colors.textPrimary, size: 24),
        title: Text(
          'Language',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        trailing: InkWell(
          onTap: () => _showLanguagePicker(context, colors),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedLanguage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: colors.textPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountStepperRow(BuildContext context, TradingColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, color: colors.textPrimary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'One-Click / Default Amount',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              // Red Circle Minus Button (-)
              InkWell(
                onTap: () {
                  if (_defaultAmount > 0.0) {
                    setState(() => _defaultAmount = (_defaultAmount - 0.1).clamp(0.0, 100.0));
                  }
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE82B57),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: Colors.white, size: 14),
                ),
              ),

              // Default Amount Text (tappable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: InkWell(
                  onTap: () => _showDefaultAmountDialog(context),
                  child: Text(
                    _defaultAmount.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),

              // Blue Circle Plus Button (+)
              InkWell(
                onTap: () {
                  setState(() => _defaultAmount = (_defaultAmount + 0.1).clamp(0.0, 100.0));
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The default amount for one-click trading from Quotes tab and Trade screen. Put 0 to make it as Min Amount Per Deal per script',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context, TradingColors colors) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
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
            Text('Change Password',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 14),
            TextField(
              controller: oldPass,
              obscureText: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Old Password',
                labelStyle: GoogleFonts.inter(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              style: GoogleFonts.inter(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: GoogleFonts.inter(color: colors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, TradingColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Delete User Account', style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to permanently delete your user profile and all associated data?',
          style: GoogleFonts.inter(color: colors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User account deletion request registered')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE82B57), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, TradingColors colors) {
    final languages = ['English', 'Hindi', 'Gujarati', 'Marathi', 'Bengali', 'Tamil'];
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: languages.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
          itemBuilder: (_, i) {
            final lang = languages[i];
            final isSelected = lang == _selectedLanguage;
            return ListTile(
              title: Text(
                lang,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1E88E5) : colors.textPrimary,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF1E88E5)) : null,
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(ctx);
              },
            );
          },
        ),
      ),
    );
  }

  void _showDefaultAmountDialog(BuildContext context) {
    final controller = TextEditingController(text: _defaultAmount.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Default Lot Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Default Lots (0 for Min)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                setState(() => _defaultAmount = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, TradingColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Terms and Conditions', style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            'Welcome to ZeroDalali. By trading on this platform, you agree to our terms of service, real-time market risk disclosures, and leverage execution guidelines.',
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: colors.primary))),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, TradingColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Zero Support 24/7', style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Need assistance with your orders, margins, or quotes? Reach our 24/7 dedicated support desk at support@zerodalali.com or call 1800-ZERO-DESK.',
          style: GoogleFonts.inter(color: colors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: colors.primary))),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, TradingColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        title: Text('Privacy Policy', style: GoogleFonts.inter(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            'ZeroDalali protects your personal financial data using 256-bit encryption. We never sell your trading information to third-party marketing entities.',
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: colors.primary))),
        ],
      ),
    );
  }

  void _showDeviceManagementSheet(BuildContext context, TradingColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Devices & Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'These devices are currently signed into your Zero account.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Current Device
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.bullish.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android, color: Color(0xFF00A854), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Android App (This Device)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A854).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ACTIVE NOW',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF00A854),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'OnePlus 12 • Android 14 • IP: 103.21.14.82',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Other Device 1
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.laptop_chromebook, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WebTrader (Chrome 128)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Windows 11 • Active 2h ago • IP: 103.21.14.82',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.bearish, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session revoked successfully.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Other Device 2
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_iphone, color: colors.textSecondary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'iPhone 15 Pro (Safari)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'iOS 17.5 • Active 3 days ago • IP: 49.37.12.11',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: colors.bearish, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session revoked successfully.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Revoke All Other Sessions Button
              OutlinedButton.icon(
                icon: Icon(Icons.logout, color: colors.bearish, size: 18),
                label: Text(
                  'REVOKE ALL OTHER SESSIONS',
                  style: GoogleFonts.inter(
                    color: colors.bearish,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.bearish.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All other active sessions have been revoked.'),
                      backgroundColor: Color(0xFF00A854),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
