import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/order_simulation_engine.dart';
import '../../data/models/models.dart';
import 'notification_service.dart';

enum WithdrawalLifecycleState {
  requested,
  approvedByRms,
  processingAtBank,
  settled,
  rejected,
  failed,
}

class DepositWebhookPayload {
  final String eventId;
  final String paymentId;
  final String referenceId;
  final double amount;
  final String currency;
  final String status; // captured, failed, pending
  final String signature;
  final DateTime timestamp;
  final String? failureReason;

  const DepositWebhookPayload({
    required this.eventId,
    required this.paymentId,
    required this.referenceId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    required this.signature,
    required this.timestamp,
    this.failureReason,
  });

  String computePayloadString() =>
      '$eventId|$paymentId|$referenceId|${amount.toStringAsFixed(2)}|$currency|$status|${timestamp.millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'paymentId': paymentId,
    'referenceId': referenceId,
    'amount': amount,
    'currency': currency,
    'status': status,
    'signature': signature,
    'timestamp': timestamp.toIso8601String(),
    'failureReason': failureReason,
  };
}

class ReconciliationResult {
  final bool isSuccess;
  final bool isDuplicate;
  final String message;
  final String referenceId;
  final double? updatedBalance;
  final DateTime processedAt;

  const ReconciliationResult({
    required this.isSuccess,
    this.isDuplicate = false,
    required this.message,
    required this.referenceId,
    this.updatedBalance,
    required this.processedAt,
  });
}

class WithdrawalStateEntry {
  final String transactionId;
  final String referenceId;
  final double amount;
  final String destination;
  WithdrawalLifecycleState state;
  final DateTime createdAt;
  DateTime updatedAt;
  String? rejectionReason;
  bool isRefunded;

  WithdrawalStateEntry({
    required this.transactionId,
    required this.referenceId,
    required this.amount,
    required this.destination,
    this.state = WithdrawalLifecycleState.requested,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.isRefunded = false,
  });
}

class MoneyMovementReconciliationService extends ChangeNotifier {
  final Ref? _ref;
  final Set<String> _processedWebhookEventIds = {};
  final Map<String, ReconciliationResult> _webhookAuditRecords = {};
  final Map<String, WithdrawalStateEntry> _withdrawals = {};
  static const String webhookSecretKey = 'zd_sec_wh_key_2026_x89a0b';

  MoneyMovementReconciliationService([this._ref]);

  List<WithdrawalStateEntry> get allWithdrawals =>
      List.unmodifiable(_withdrawals.values.toList());

  // ─── 1. Payment Signature Verification ────────────────────────────────────

  static String generateHmacSha256(String data, String key) {
    // Pure Dart HMAC-SHA256 calculation with no external platform dependencies
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);

    // Standard HMAC construction using SHA-256 block size (64 bytes)
    final k = List<int>.filled(64, 0);
    if (keyBytes.length > 64) {
      final keyHash = _sha256(keyBytes);
      for (int i = 0; i < keyHash.length; i++) {
        k[i] = keyHash[i];
      }
    } else {
      for (int i = 0; i < keyBytes.length; i++) {
        k[i] = keyBytes[i];
      }
    }

    final oKeyPad = List<int>.generate(64, (i) => k[i] ^ 0x5c);
    final iKeyPad = List<int>.generate(64, (i) => k[i] ^ 0x36);

    final innerHash = _sha256([...iKeyPad, ...dataBytes]);
    final outerHash = _sha256([...oKeyPad, ...innerHash]);

    return outerHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool verifyWebhookSignature({
    required String rawBody,
    required String signature,
    required String secret,
  }) {
    final expectedSignature = generateHmacSha256(rawBody, secret);
    return expectedSignature.toLowerCase() == signature.toLowerCase().trim();
  }

  // ─── 2. Deposit Webhook Reconciliation & Idempotent Balance Updates ────────

  Future<ReconciliationResult> reconcileDepositWebhook(DepositWebhookPayload payload) async {
    final now = DateTime.now();

    // 1. Duplicate webhook check (Idempotency guarantee)
    if (_processedWebhookEventIds.contains(payload.eventId)) {
      final cached = _webhookAuditRecords[payload.eventId];
      return ReconciliationResult(
        isSuccess: true,
        isDuplicate: true,
        message: 'Duplicate webhook detected. Payment already settled.',
        referenceId: payload.referenceId,
        updatedBalance: cached?.updatedBalance,
        processedAt: now,
      );
    }

    // 2. Cryptographic signature check
    final payloadString = payload.computePayloadString();
    final isValidSig = verifyWebhookSignature(
      rawBody: payloadString,
      signature: payload.signature,
      secret: webhookSecretKey,
    );

    if (!isValidSig) {
      final failedResult = ReconciliationResult(
        isSuccess: false,
        message: 'Invalid webhook HMAC signature. Request rejected.',
        referenceId: payload.referenceId,
        processedAt: now,
      );
      _webhookAuditRecords[payload.eventId] = failedResult;
      return failedResult;
    }

    _processedWebhookEventIds.add(payload.eventId);

    // 3. Failed payment reconciliation
    if (payload.status != 'captured' && payload.status != 'success') {
      final failureReason = payload.failureReason ?? 'Bank gateway rejected payment';
      final failedResult = ReconciliationResult(
        isSuccess: false,
        message: 'Deposit failed at gateway: $failureReason',
        referenceId: payload.referenceId,
        processedAt: now,
      );
      _webhookAuditRecords[payload.eventId] = failedResult;

      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'notif_wh_fail_${now.millisecondsSinceEpoch}',
          type: NotificationType.depositFailed,
          category: NotificationCategory.funds,
          title: 'Deposit Reconciliation Failed',
          body: 'Deposit of ₹${payload.amount.toStringAsFixed(2)} (${payload.referenceId}) failed: $failureReason',
          timestamp: now,
          deepLink: '/funds',
          isCritical: true,
        ));
      } catch (_) {}

      notifyListeners();
      return failedResult;
    }

    // 4. Idempotent balance credit via OrderSimulationEngine
    double? newBalance;
    if (_ref != null) {
      final engine = _ref.read(orderSimulationEngineProvider);
      // Initiate deposit with success outcome
      await engine.initiateDeposit(
        amount: payload.amount,
        method: PaymentMethod.UPI,
        outcome: WalletTransactionStatus.SUCCESS,
      );
      newBalance = engine.availableEquityMargin;
    }

    final successResult = ReconciliationResult(
      isSuccess: true,
      isDuplicate: false,
      message: 'Deposit webhook verified and reconciled. Balance credited.',
      referenceId: payload.referenceId,
      updatedBalance: newBalance,
      processedAt: now,
    );

    _webhookAuditRecords[payload.eventId] = successResult;
    notifyListeners();
    return successResult;
  }

  // ─── 3. Withdrawal State Machine with Automated Margin Refund ─────────────

  void registerWithdrawal({
    required String transactionId,
    required String referenceId,
    required double amount,
    required String destination,
  }) {
    final now = DateTime.now();
    _withdrawals[transactionId] = WithdrawalStateEntry(
      transactionId: transactionId,
      referenceId: referenceId,
      amount: amount,
      destination: destination,
      state: WithdrawalLifecycleState.requested,
      createdAt: now,
      updatedAt: now,
    );
    notifyListeners();
  }

  bool transitionWithdrawal(
    String transactionId,
    WithdrawalLifecycleState nextState, {
    String? reason,
  }) {
    final entry = _withdrawals[transactionId];
    if (entry == null) return false;

    // Validate state transitions
    final current = entry.state;
    bool isValid = false;

    switch (current) {
      case WithdrawalLifecycleState.requested:
        isValid = nextState == WithdrawalLifecycleState.approvedByRms ||
            nextState == WithdrawalLifecycleState.rejected;
        break;
      case WithdrawalLifecycleState.approvedByRms:
        isValid = nextState == WithdrawalLifecycleState.processingAtBank ||
            nextState == WithdrawalLifecycleState.rejected;
        break;
      case WithdrawalLifecycleState.processingAtBank:
        isValid = nextState == WithdrawalLifecycleState.settled ||
            nextState == WithdrawalLifecycleState.failed;
        break;
      case WithdrawalLifecycleState.settled:
      case WithdrawalLifecycleState.rejected:
      case WithdrawalLifecycleState.failed:
        isValid = false; // Terminal states cannot transition
        break;
    }

    if (!isValid) return false;

    entry.state = nextState;
    entry.updatedAt = DateTime.now();

    // Auto-refund blocked margin back to available balance upon failure or rejection
    if ((nextState == WithdrawalLifecycleState.rejected || nextState == WithdrawalLifecycleState.failed) &&
        !entry.isRefunded) {
      entry.isRefunded = true;
      entry.rejectionReason = reason ?? 'Payout declined by clearing banking partner';

      if (_ref != null) {
        final engine = _ref.read(orderSimulationEngineProvider);
        // Refund margin back into trading balance
        engine.initiateDeposit(
          amount: entry.amount,
          method: PaymentMethod.NET_BANKING,
          outcome: WalletTransactionStatus.SUCCESS,
        );
      }

      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'notif_wth_refund_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.withdrawalFailed,
          category: NotificationCategory.funds,
          title: 'Payout ${nextState.name.toUpperCase()}: ₹${entry.amount.toStringAsFixed(2)} Refunded',
          body: 'Your withdrawal to ${entry.destination} was not completed. Margin of ₹${entry.amount.toStringAsFixed(2)} has been restored to your account.',
          timestamp: DateTime.now(),
          deepLink: '/funds',
          isCritical: true,
        ));
      } catch (_) {}
    } else if (nextState == WithdrawalLifecycleState.settled) {
      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'notif_wth_settle_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.withdrawalCompleted,
          category: NotificationCategory.funds,
          title: 'Payout Processed: ₹${entry.amount.toStringAsFixed(2)}',
          body: 'Your payout of ₹${entry.amount.toStringAsFixed(2)} has been successfully credited to ${entry.destination}.',
          timestamp: DateTime.now(),
          deepLink: '/funds',
        ));
      } catch (_) {}
    }

    notifyListeners();
    return true;
  }

  // ─── SHA-256 Helper (Pure Dart Standard FIPS 180-4) ────────────────────────
  static List<int> _sha256(List<int> data) {
    const k = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];

    int h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    int h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;

    final length = data.length;
    final bitLength = length * 8;
    final paddingLength = (length % 64 < 56) ? (56 - length % 64) : (120 - length % 64);
    final padded = List<int>.from(data)..add(0x80)..addAll(List<int>.filled(paddingLength - 1, 0));

    for (int i = 7; i >= 0; i--) {
      padded.add((bitLength >> (i * 8)) & 0xff);
    }

    final w = List<int>.filled(64, 0);
    int ror(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) |
            (padded[chunk + i * 4 + 1] << 16) |
            (padded[chunk + i * 4 + 2] << 8) |
            (padded[chunk + i * 4 + 3]);
      }
      for (int i = 16; i < 64; i++) {
        final s0 = ror(w[i - 15], 7) ^ ror(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final s1 = ror(w[i - 2], 17) ^ ror(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      int a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;

      for (int i = 0; i < 64; i++) {
        final s1 = ror(e, 6) ^ ror(e, 11) ^ ror(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (h + s1 + ch + k[i] + w[i]) & 0xffffffff;
        final s0 = ror(a, 2) ^ ror(a, 13) ^ ror(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }

    final result = <int>[];
    for (final val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      result.add((val >> 24) & 0xff);
      result.add((val >> 16) & 0xff);
      result.add((val >> 8) & 0xff);
      result.add(val & 0xff);
    }
    return result;
  }
}

final moneyMovementReconciliationServiceProvider =
    ChangeNotifierProvider<MoneyMovementReconciliationService>((ref) {
  return MoneyMovementReconciliationService(ref);
});
