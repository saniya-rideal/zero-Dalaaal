import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import 'notification_service.dart';

class PrivacyConsentRecord {
  final String consentId;
  final String userId;
  final String termsVersion;
  final String privacyPolicyVersion;
  final String riskDisclosureVersion;
  final DateTime acceptedAt;
  final String ipAddress;
  final bool isAuditLogged;

  const PrivacyConsentRecord({
    required this.consentId,
    required this.userId,
    required this.termsVersion,
    required this.privacyPolicyVersion,
    required this.riskDisclosureVersion,
    required this.acceptedAt,
    required this.ipAddress,
    this.isAuditLogged = true,
  });

  Map<String, dynamic> toJson() => {
    'consentId': consentId,
    'userId': userId,
    'termsVersion': termsVersion,
    'privacyPolicyVersion': privacyPolicyVersion,
    'riskDisclosureVersion': riskDisclosureVersion,
    'acceptedAt': acceptedAt.toIso8601String(),
    'ipAddress': ipAddress,
    'isAuditLogged': isAuditLogged,
  };
}

class AttemptTracker {
  int failedAttempts = 0;
  DateTime? lockedUntil;

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  int get remainingLockoutSeconds {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

class SecurityPrivacyService extends ChangeNotifier {
  final Ref? _ref;
  final Map<String, AttemptTracker> _trackers = {};
  PrivacyConsentRecord _consentRecord = PrivacyConsentRecord(
    consentId: 'consent_initial_2026',
    userId: 'ZD84920',
    termsVersion: 'v2026.1 (August 2026)',
    privacyPolicyVersion: 'v2026.1 (August 2026)',
    riskDisclosureVersion: 'SEBI/2023/73',
    acceptedAt: DateTime.now().subtract(const Duration(days: 15)),
    ipAddress: '103.21.14.82',
  );

  bool _isScreenProtectionActive = false;

  SecurityPrivacyService([this._ref]);

  PrivacyConsentRecord get consentRecord => _consentRecord;
  bool get isScreenProtectionActive => _isScreenProtectionActive;

  // ─── 1. Brute-Force & Rate-Limiting Controls ───────────────────────────────

  bool isTargetLocked(String targetKey) {
    final tracker = _trackers[targetKey];
    if (tracker == null) return false;
    return tracker.isLocked;
  }

  int getRemainingLockoutSeconds(String targetKey) {
    final tracker = _trackers[targetKey];
    if (tracker == null) return 0;
    return tracker.remainingLockoutSeconds;
  }

  void recordFailedAttempt(String targetKey, {int maxAttempts = 3, int lockoutDurationSeconds = 60}) {
    final tracker = _trackers.putIfAbsent(targetKey, () => AttemptTracker());
    tracker.failedAttempts++;

    if (tracker.failedAttempts >= maxAttempts) {
      tracker.lockedUntil = DateTime.now().add(Duration(seconds: lockoutDurationSeconds));

      // Dispatch security notification on brute-force lockout
      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'notif_sec_lockout_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.securityAlert,
          category: NotificationCategory.security,
          title: 'Account Access Temporarily Suspended',
          body: 'Too many failed verification attempts on $targetKey. Locked for $lockoutDurationSeconds seconds.',
          timestamp: DateTime.now(),
          deepLink: '/settings',
          isCritical: true,
        ));
      } catch (_) {}
    }
    notifyListeners();
  }

  void resetAttempts(String targetKey) {
    final tracker = _trackers[targetKey];
    if (tracker != null) {
      tracker.failedAttempts = 0;
      tracker.lockedUntil = null;
      notifyListeners();
    }
  }

  // ─── 2. Session Anomaly Detection ──────────────────────────────────────────

  bool checkSessionAnomaly({
    required String incomingIp,
    required String incomingDevice,
    required List<ActiveSessionItem> existingSessions,
  }) {
    final hasMatchingIp = existingSessions.any((s) => s.ipAddress == incomingIp);
    final hasMatchingDevice = existingSessions.any((s) => s.deviceName.toLowerCase().contains(incomingDevice.toLowerCase()));

    // If both device and IP are completely novel, flag as anomalous
    if (!hasMatchingIp && !hasMatchingDevice && existingSessions.isNotEmpty) {
      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'notif_anomaly_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.loginNewDevice,
          category: NotificationCategory.security,
          title: 'Security Alert: Login from Unrecognized Device',
          body: 'New login detected from $incomingDevice (IP: $incomingIp). If this was not you, revoke sessions immediately.',
          timestamp: DateTime.now(),
          deepLink: '/settings',
          isCritical: true,
        ));
      } catch (_) {}
      return true; // Anomaly detected
    }

    return false; // Normal session
  }

  // ─── 3. Screen Protection / Screenshot Prevention Policy ──────────────────

  void setScreenProtection(bool active) {
    if (_isScreenProtectionActive != active) {
      _isScreenProtectionActive = active;
      notifyListeners();
    }
  }

  // ─── 4. Versioned Privacy Consent Recording ────────────────────────────────

  void updatePrivacyConsent({
    required String termsVersion,
    required String privacyPolicyVersion,
    required String riskDisclosureVersion,
    required String userId,
    required String ipAddress,
  }) {
    _consentRecord = PrivacyConsentRecord(
      consentId: 'consent_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      termsVersion: termsVersion,
      privacyPolicyVersion: privacyPolicyVersion,
      riskDisclosureVersion: riskDisclosureVersion,
      acceptedAt: DateTime.now(),
      ipAddress: ipAddress,
      isAuditLogged: true,
    );
    notifyListeners();
  }
}

final securityPrivacyServiceProvider = ChangeNotifierProvider<SecurityPrivacyService>((ref) {
  return SecurityPrivacyService(ref);
});

final privacyConsentProvider = Provider<PrivacyConsentRecord>((ref) {
  final service = ref.watch(securityPrivacyServiceProvider);
  return service.consentRecord;
});

final screenProtectionProvider = Provider<bool>((ref) {
  final service = ref.watch(securityPrivacyServiceProvider);
  return service.isScreenProtectionActive;
});
