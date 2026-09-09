import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/trading_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../shared_widgets/shared_widgets.dart';

class NotificationPreferencesSheet extends ConsumerStatefulWidget {
  const NotificationPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationPreferencesSheet(),
    );
  }

  @override
  ConsumerState<NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends ConsumerState<NotificationPreferencesSheet> {
  late bool _orders;
  late bool _funds;
  late bool _riskMargin;
  late bool _priceAlerts;
  late bool _news;
  late bool _security;

  late bool _quietHours;
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;
  late bool _allowCritical;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(notificationServiceProvider).preferences;
    _orders = prefs.ordersEnabled;
    _funds = prefs.fundsEnabled;
    _riskMargin = prefs.riskMarginEnabled;
    _priceAlerts = prefs.priceAlertsEnabled;
    _news = prefs.newsEnabled;
    _security = prefs.securityEnabled;

    _quietHours = prefs.quietHoursEnabled;
    _startHour = prefs.quietHoursStartHour;
    _startMinute = prefs.quietHoursStartMinute;
    _endHour = prefs.quietHoursEndHour;
    _endMinute = prefs.quietHoursEndMinute;
    _allowCritical = prefs.allowCriticalInQuietHours;
  }

  void _savePreferences() {
    final newPrefs = NotificationPreferences(
      ordersEnabled: _orders,
      fundsEnabled: _funds,
      riskMarginEnabled: _riskMargin,
      priceAlertsEnabled: _priceAlerts,
      newsEnabled: _news,
      securityEnabled: _security,
      quietHoursEnabled: _quietHours,
      quietHoursStartHour: _startHour,
      quietHoursStartMinute: _startMinute,
      quietHoursEndHour: _endHour,
      quietHoursEndMinute: _endMinute,
      allowCriticalInQuietHours: _allowCritical,
    );
    ref.read(notificationServiceProvider).updatePreferences(newPrefs);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences updated successfully.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetDefaults() {
    setState(() {
      const def = NotificationPreferences();
      _orders = def.ordersEnabled;
      _funds = def.fundsEnabled;
      _riskMargin = def.riskMarginEnabled;
      _priceAlerts = def.priceAlertsEnabled;
      _news = def.newsEnabled;
      _security = def.securityEnabled;
      _quietHours = def.quietHoursEnabled;
      _startHour = def.quietHoursStartHour;
      _startMinute = def.quietHoursStartMinute;
      _endHour = def.quietHoursEndHour;
      _endMinute = def.quietHoursEndMinute;
      _allowCritical = def.allowCriticalInQuietHours;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? _startHour : _endHour,
      minute: isStart ? _startMinute : _endMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startHour = picked.hour;
          _startMinute = picked.minute;
        } else {
          _endHour = picked.hour;
          _endMinute = picked.minute;
        }
      });
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const ZeroDragHandle(padding: EdgeInsets.only(top: 12, bottom: 8)),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Preferences',
                        style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control push alerts & quiet hours',
                        style: AppTypography.caption(color: colors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _resetDefaults,
                  child: Text(
                    'Reset',
                    style: AppTypography.caption(color: colors.primary, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Categories Section
                Text(
                  'ALERT CATEGORIES',
                  style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _buildToggleCard(
                  title: 'Orders & Executions',
                  subtitle: 'Order submitted, filled, partial fills, cancellations & rejections',
                  icon: LucideIcons.receipt,
                  value: _orders,
                  activeColor: colors.bullish,
                  onChanged: (v) => setState(() => _orders = v),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  title: 'Funds & Banking',
                  subtitle: 'Deposit confirmations, pending transfers & withdrawal status',
                  icon: LucideIcons.wallet,
                  value: _funds,
                  activeColor: colors.primary,
                  onChanged: (v) => setState(() => _funds = v),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  title: 'Risk & Margin Warnings',
                  subtitle: 'High margin utilization (>80%), margin calls & RMS liquidation',
                  icon: LucideIcons.alertTriangle,
                  value: _riskMargin,
                  activeColor: colors.bearish,
                  onChanged: (v) => setState(() => _riskMargin = v),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  title: 'Price Alerts & Triggers',
                  subtitle: 'Pre-set price conditions, target triggers and volume spikes',
                  icon: LucideIcons.bellRing,
                  value: _priceAlerts,
                  activeColor: colors.warning,
                  onChanged: (v) => setState(() => _priceAlerts = v),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  title: 'Market News & Insights',
                  subtitle: 'Breaking headlines, macroeconomic releases & RBI policy updates',
                  icon: LucideIcons.newspaper,
                  value: _news,
                  activeColor: colors.primary,
                  onChanged: (v) => setState(() => _news = v),
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  title: 'Security & Account Notices',
                  subtitle: 'New device sign-ins, password updates, KYC status & corporate actions',
                  icon: LucideIcons.shield,
                  value: _security,
                  activeColor: Colors.purpleAccent,
                  onChanged: (v) => setState(() => _security = v),
                  colors: colors,
                ),

                const SizedBox(height: 24),

                // 2. Quiet Hours Section
                Text(
                  'QUIET HOURS (DO NOT DISTURB)',
                  style: AppTypography.labelSmall(color: colors.textSecondary, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(LucideIcons.moon, color: colors.warning, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enable Quiet Hours',
                                        style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Mute standard alerts during rest hours',
                                        style: AppTypography.caption(color: colors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _quietHours,
                            activeColor: colors.warning,
                            onChanged: (v) => setState(() => _quietHours = v),
                          ),
                        ],
                      ),

                      if (_quietHours) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.divider),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('From', style: AppTypography.labelSmall(color: colors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(_startHour, _startMinute),
                                        style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.divider),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('To', style: AppTypography.labelSmall(color: colors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(_endHour, _endMinute),
                                        style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Critical Alert Override Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deliver Critical Risk & Security Alerts',
                                    style: AppTypography.caption(color: colors.textPrimary, weight: FontWeight.w600),
                                  ),
                                  Text(
                                    'RMS Liquidation & Security breaches bypass Quiet Hours',
                                    style: AppTypography.labelSmall(color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _allowCritical,
                              activeColor: colors.bearish,
                              onChanged: (v) => setState(() => _allowCritical = v),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(top: BorderSide(color: colors.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Save Preferences',
                  style: AppTypography.body(color: Colors.white, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    required dynamic colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: activeColor.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, color: activeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(color: colors.textPrimary, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tradingColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Notification Preferences', style: AppTypography.h2(color: colors.textPrimary, weight: FontWeight.w700)),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: const NotificationPreferencesSheet(),
    );
  }
}
