import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/instrument.dart';
import '../../data/models/order.dart';
import '../utils/currency_formatter.dart';

/// 1. API Error Mapping Model
class ApiErrorInfo {
  final int statusCode;
  final String errorCategory;
  final String userTitle;
  final String userMessage;
  final String suggestedAction;
  final bool isRetryable;

  const ApiErrorInfo({
    required this.statusCode,
    required this.errorCategory,
    required this.userTitle,
    required this.userMessage,
    required this.suggestedAction,
    required this.isRetryable,
  });

  static ApiErrorInfo fromStatusCode(int code, {String? customMessage}) {
    switch (code) {
      case 400:
        return ApiErrorInfo(
          statusCode: 400,
          errorCategory: 'BAD_REQUEST',
          userTitle: 'Invalid Request',
          userMessage: customMessage ??
              'The trade parameters or input values are invalid. Please check and try again.',
          suggestedAction: 'Review Order Parameters',
          isRetryable: false,
        );
      case 401:
        return ApiErrorInfo(
          statusCode: 401,
          errorCategory: 'UNAUTHORIZED',
          userTitle: 'Session Expired',
          userMessage: customMessage ??
              'Your trading session has expired or authentication token is invalid. Please log in again.',
          suggestedAction: 'Re-authenticate',
          isRetryable: false,
        );
      case 403:
        return ApiErrorInfo(
          statusCode: 403,
          errorCategory: 'FORBIDDEN',
          userTitle: 'Segment Disabled',
          userMessage: customMessage ??
              'Your trading account is not activated for this segment or exchange. Please submit segment activation.',
          suggestedAction: 'Contact Support or Activate Segment',
          isRetryable: false,
        );
      case 404:
        return ApiErrorInfo(
          statusCode: 404,
          errorCategory: 'NOT_FOUND',
          userTitle: 'Resource Not Found',
          userMessage: customMessage ??
              'The requested order, contract, or notification could not be found on the server.',
          suggestedAction: 'Return to Dashboard',
          isRetryable: false,
        );
      case 409:
        return ApiErrorInfo(
          statusCode: 409,
          errorCategory: 'CONFLICT',
          userTitle: 'Order Conflict',
          userMessage: customMessage ??
              'Duplicate request or state conflict. The order may have already been placed.',
          suggestedAction: 'Check Order Book',
          isRetryable: false,
        );
      case 429:
        return ApiErrorInfo(
          statusCode: 429,
          errorCategory: 'RATE_LIMIT',
          userTitle: 'Too Many Requests',
          userMessage: customMessage ??
              'Exchange rate limit exceeded. Please wait a few moments before placing another order.',
          suggestedAction: 'Wait 5 Seconds & Retry',
          isRetryable: true,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiErrorInfo(
          statusCode: code,
          errorCategory: 'SERVER_ERROR',
          userTitle: 'Exchange Gateway Error',
          userMessage: customMessage ??
              'Exchange core systems are experiencing temporary latency. Your funds are safe.',
          suggestedAction: 'Retry in 30 Seconds',
          isRetryable: true,
        );
      default:
        return ApiErrorInfo(
          statusCode: code,
          errorCategory: 'UNKNOWN',
          userTitle: 'Communication Error',
          userMessage: customMessage ??
              'An unexpected network error occurred. Code: $code',
          suggestedAction: 'Check Connection & Retry',
          isRetryable: true,
        );
    }
  }
}

/// 2. App Version Compatibility Status
enum VersionStatus {
  compatible,
  optionalUpdateAvailable,
  forceUpdateRequired,
}

class AppVersionResult {
  final VersionStatus status;
  final String currentVersion;
  final String minSupportedVersion;
  final String latestVersion;
  final String? updateUrl;
  final String message;

  const AppVersionResult({
    required this.status,
    required this.currentVersion,
    required this.minSupportedVersion,
    required this.latestVersion,
    this.updateUrl,
    required this.message,
  });

  bool get isUsable => status != VersionStatus.forceUpdateRequired;
  bool get needsForceUpdate => status == VersionStatus.forceUpdateRequired;
}

/// 3. In-Flight Order Journal Entry
class InFlightJournalEntry {
  final String idempotencyKey;
  final OrderRequest request;
  final DateTime timestamp;
  final bool isPersisted;
  final String? serverOrderId;

  const InFlightJournalEntry({
    required this.idempotencyKey,
    required this.request,
    required this.timestamp,
    this.isPersisted = false,
    this.serverOrderId,
  });

  InFlightJournalEntry copyWith({
    bool? isPersisted,
    String? serverOrderId,
  }) {
    return InFlightJournalEntry(
      idempotencyKey: idempotencyKey,
      request: request,
      timestamp: timestamp,
      isPersisted: isPersisted ?? this.isPersisted,
      serverOrderId: serverOrderId ?? this.serverOrderId,
    );
  }
}

/// 4. Deep Link & Push Notification Fallback Resolution
class DeepLinkResolution {
  final bool isFound;
  final String resolvedRoute;
  final String? userAlertMessage;

  const DeepLinkResolution({
    required this.isFound,
    required this.resolvedRoute,
    this.userAlertMessage,
  });
}

/// 5. Pre-flight Edge Validation Result
class PreFlightValidationResult {
  final bool isValid;
  final String? rejectionReason;

  const PreFlightValidationResult({
    required this.isValid,
    this.rejectionReason,
  });
}

/// Comprehensive Edge Case Service
class EdgeCaseService extends ChangeNotifier {
  final Map<String, InFlightJournalEntry> _inFlightJournal = {};
  String _activeNetworkType = 'WIFI';

  EdgeCaseService();

  Map<String, InFlightJournalEntry> get inFlightJournal =>
      Map.unmodifiable(_inFlightJournal);
  String get activeNetworkType => _activeNetworkType;

  // ---------------------------------------------------------------------------
  // A. In-Flight Order Recovery Journal
  // ---------------------------------------------------------------------------
  void recordInFlightOrder(OrderRequest request, String idempotencyKey) {
    _inFlightJournal[idempotencyKey] = InFlightJournalEntry(
      idempotencyKey: idempotencyKey,
      request: request,
      timestamp: DateTime.now(),
      isPersisted: false,
    );
    notifyListeners();
  }

  void markOrderPersisted(String idempotencyKey, String serverOrderId) {
    if (_inFlightJournal.containsKey(idempotencyKey)) {
      _inFlightJournal[idempotencyKey] = _inFlightJournal[idempotencyKey]!.copyWith(
        isPersisted: true,
        serverOrderId: serverOrderId,
      );
      notifyListeners();
    }
  }

  List<InFlightJournalEntry> recoverInFlightOrders() {
    return _inFlightJournal.values.where((e) => !e.isPersisted).toList();
  }

  void clearJournal() {
    _inFlightJournal.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // B. Semantic Versioning & Forced Update Check
  // ---------------------------------------------------------------------------
  static AppVersionResult checkVersionCompatibility({
    required String currentVersion,
    required String minSupportedVersion,
    required String latestVersion,
    String? updateUrl,
  }) {
    final curSem = _parseVersion(currentVersion);
    final minSem = _parseVersion(minSupportedVersion);
    final latSem = _parseVersion(latestVersion);

    if (_compareSemVer(curSem, minSem) < 0) {
      return AppVersionResult(
        status: VersionStatus.forceUpdateRequired,
        currentVersion: currentVersion,
        minSupportedVersion: minSupportedVersion,
        latestVersion: latestVersion,
        updateUrl: updateUrl ?? 'https://zerodalali.com/app/update',
        message:
            'A critical security or exchange update is required. Please update to version $minSupportedVersion or higher to continue trading.',
      );
    }

    if (_compareSemVer(curSem, latSem) < 0) {
      return AppVersionResult(
        status: VersionStatus.optionalUpdateAvailable,
        currentVersion: currentVersion,
        minSupportedVersion: minSupportedVersion,
        latestVersion: latestVersion,
        updateUrl: updateUrl ?? 'https://zerodalali.com/app/update',
        message:
            'A new version ($latestVersion) is available with enhanced charting and speed optimizations.',
      );
    }

    return AppVersionResult(
      status: VersionStatus.compatible,
      currentVersion: currentVersion,
      minSupportedVersion: minSupportedVersion,
      latestVersion: latestVersion,
      updateUrl: updateUrl,
      message: 'App version is up to date and fully compatible.',
    );
  }

  static List<int> _parseVersion(String v) {
    return v
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }

  static int _compareSemVer(List<int> a, List<int> b) {
    final len = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < len; i++) {
      final partA = i < a.length ? a[i] : 0;
      final partB = i < b.length ? b[i] : 0;
      if (partA != partB) {
        return partA.compareTo(partB);
      }
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // C. Network Handover (Wi-Fi <-> Cellular)
  // ---------------------------------------------------------------------------
  bool handleNetworkHandover({
    required String fromType,
    required String toType,
    required bool hasActiveSession,
  }) {
    _activeNetworkType = toType;
    notifyListeners();
    // Invariant: Network handover MUST NOT invalidate session or corrupt drafts
    return hasActiveSession;
  }

  // ---------------------------------------------------------------------------
  // D. Safe Deep-Link & Push Notification Fallback Resolver
  // ---------------------------------------------------------------------------
  static DeepLinkResolution resolveDeepLinkTarget({
    required String entityType, // 'order' | 'quote' | 'ticket'
    required String entityId,
    required bool exists,
  }) {
    if (exists) {
      switch (entityType) {
        case 'order':
          return DeepLinkResolution(
            isFound: true,
            resolvedRoute: '/order-detail/$entityId',
          );
        case 'quote':
          return DeepLinkResolution(
            isFound: true,
            resolvedRoute: '/quote/$entityId',
          );
        case 'ticket':
          return DeepLinkResolution(
            isFound: true,
            resolvedRoute: '/help/tickets/$entityId',
          );
        default:
          return const DeepLinkResolution(
            isFound: true,
            resolvedRoute: '/quotes',
          );
      }
    }

    // Graceful fallback when object was deleted, expired, or unavailable
    switch (entityType) {
      case 'order':
        return DeepLinkResolution(
          isFound: false,
          resolvedRoute: '/orders',
          userAlertMessage:
              'Order #$entityId is no longer available or was archived. Redirected to Orders Book.',
        );
      case 'quote':
        return DeepLinkResolution(
          isFound: false,
          resolvedRoute: '/quotes',
          userAlertMessage:
              'Instrument "$entityId" is delisted or unavailable. Redirected to Watchlist.',
        );
      case 'ticket':
        return DeepLinkResolution(
          isFound: false,
          resolvedRoute: '/help',
          userAlertMessage:
              'Support ticket #$entityId was resolved or closed. Redirected to Help Desk.',
        );
      default:
        return const DeepLinkResolution(
          isFound: false,
          resolvedRoute: '/quotes',
          userAlertMessage: 'Item unavailable. Redirected to Watchlist.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // E. Pre-Flight Order Edge-Case Validation
  // ---------------------------------------------------------------------------
  static PreFlightValidationResult validatePreFlightOrder({
    required Instrument instrument,
    required double price,
    required double quantity,
    required double availableMargin,
    required double requiredMargin,
    required bool isMarketOpen,
    required bool isAmo,
    double? lowerCircuit,
    double? upperCircuit,
  }) {
    // 1. Instrument suspension check
    if (instrument.isSuspended) {
      return PreFlightValidationResult(
        isValid: false,
        rejectionReason:
            'Trading in ${instrument.symbol} is currently suspended by the exchange.',
      );
    }

    // 2. Market hours vs AMO check
    if (!isMarketOpen && !isAmo) {
      return const PreFlightValidationResult(
        isValid: false,
        rejectionReason:
            'Exchange is closed. Regular orders are rejected. Please use After Market Order (AMO).',
      );
    }

    // 3. Quantity validation
    if (!CurrencyFormatter.validateQuantityPrecision(quantity)) {
      return PreFlightValidationResult(
        isValid: false,
        rejectionReason:
            'Invalid quantity: $quantity. Must be positive integer lots.',
      );
    }

    // 4. Circuit limit check
    if (price > 0 && lowerCircuit != null && upperCircuit != null) {
      if (price < lowerCircuit || price > upperCircuit) {
        return PreFlightValidationResult(
          isValid: false,
          rejectionReason:
              'Price ₹$price violates exchange circuit limits (₹$lowerCircuit - ₹$upperCircuit).',
        );
      }
    }

    // 5. Margin balance check
    if (requiredMargin > availableMargin) {
      final deficit = requiredMargin - availableMargin;
      return PreFlightValidationResult(
        isValid: false,
        rejectionReason:
            'Insufficient margin: Required ₹${CurrencyFormatter.format(requiredMargin, showSymbol: false)} exceeds available ₹${CurrencyFormatter.format(availableMargin, showSymbol: false)} (Shortfall: ₹${CurrencyFormatter.format(deficit, showSymbol: false)}).',
      );
    }

    return const PreFlightValidationResult(isValid: true);
  }
}

final edgeCaseServiceProvider = ChangeNotifierProvider<EdgeCaseService>((ref) {
  return EdgeCaseService();
});
