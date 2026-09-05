import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import 'notification_service.dart';

enum LogLevel { debug, info, warn, error }

class StructuredLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String component;
  final String message;
  final Map<String, dynamic> context;
  final String? traceId;
  final String? spanId;

  const StructuredLogEntry({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.message,
    this.context = const {},
    this.traceId,
    this.spanId,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name.toUpperCase(),
    'component': component,
    'message': message,
    'context': context,
    'traceId': traceId,
    'spanId': spanId,
  };
}

enum MetricType { counter, gauge, latencyHistogram }

class MetricRecord {
  final String name;
  final MetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, String> tags;

  const MetricRecord({
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.tags = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'tags': tags,
  };
}

class TraceSpan {
  final String traceId;
  final String spanId;
  final String? parentSpanId;
  final String operationName;
  final DateTime startTime;
  DateTime? endTime;
  int? durationMs;
  final Map<String, String> tags;

  TraceSpan({
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    required this.operationName,
    required this.startTime,
    this.endTime,
    this.durationMs,
    this.tags = const {},
  });

  void finish() {
    endTime = DateTime.now();
    durationMs = endTime!.difference(startTime).inMilliseconds;
  }
}

class CrashReport {
  final String reportId;
  final DateTime timestamp;
  final String error;
  final String stackTrace;
  final Map<String, String> deviceInfo;
  final List<String> breadcrumbs;

  const CrashReport({
    required this.reportId,
    required this.timestamp,
    required this.error,
    required this.stackTrace,
    required this.deviceInfo,
    required this.breadcrumbs,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'timestamp': timestamp.toIso8601String(),
    'error': error,
    'stackTrace': stackTrace,
    'deviceInfo': deviceInfo,
    'breadcrumbs': breadcrumbs,
  };
}

class ObservabilityService extends ChangeNotifier {
  final Ref? _ref;
  final List<StructuredLogEntry> _logs = [];
  final List<MetricRecord> _metrics = [];
  final Map<String, TraceSpan> _activeSpans = {};
  final List<TraceSpan> _completedSpans = [];
  final List<CrashReport> _crashReports = [];
  final List<String> _breadcrumbs = [];

  // Failure tracking counters
  int _consecutiveOrderFailures = 0;
  int _consecutivePaymentFailures = 0;
  int _marketDataLatencyBreachCount = 0;

  ObservabilityService([this._ref]);

  List<StructuredLogEntry> get logs => List.unmodifiable(_logs);
  List<MetricRecord> get metrics => List.unmodifiable(_metrics);
  List<TraceSpan> get completedSpans => List.unmodifiable(_completedSpans);
  List<CrashReport> get crashReports => List.unmodifiable(_crashReports);
  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  // ─── 1. Structured Logging ────────────────────────────────────────────────

  void log({
    required LogLevel level,
    required String component,
    required String message,
    Map<String, dynamic> context = const {},
    String? traceId,
    String? spanId,
  }) {
    final entry = StructuredLogEntry(
      timestamp: DateTime.now(),
      level: level,
      component: component,
      message: message,
      context: context,
      traceId: traceId,
      spanId: spanId,
    );
    _logs.insert(0, entry);
    if (_logs.length > 500) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  void logInfo(String component, String message, [Map<String, dynamic>? context]) =>
      log(level: LogLevel.info, component: component, message: message, context: context ?? {});

  void logWarn(String component, String message, [Map<String, dynamic>? context]) =>
      log(level: LogLevel.warn, component: component, message: message, context: context ?? {});

  void logError(String component, String message, [Map<String, dynamic>? context]) =>
      log(level: LogLevel.error, component: component, message: message, context: context ?? {});

  // ─── 2. Metrics Tracking ──────────────────────────────────────────────────

  void incrementCounter(String name, {double by = 1.0, Map<String, String> tags = const {}}) {
    _metrics.insert(0, MetricRecord(
      name: name,
      type: MetricType.counter,
      value: by,
      unit: 'count',
      timestamp: DateTime.now(),
      tags: tags,
    ));
    notifyListeners();
  }

  void recordGauge(String name, double value, {String unit = 'value', Map<String, String> tags = const {}}) {
    _metrics.insert(0, MetricRecord(
      name: name,
      type: MetricType.gauge,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      tags: tags,
    ));
    notifyListeners();
  }

  void recordLatency(String name, int latencyMs, {Map<String, String> tags = const {}}) {
    _metrics.insert(0, MetricRecord(
      name: name,
      type: MetricType.latencyHistogram,
      value: latencyMs.toDouble(),
      unit: 'ms',
      timestamp: DateTime.now(),
      tags: tags,
    ));
    notifyListeners();
  }

  // ─── 3. Distributed Tracing ───────────────────────────────────────────────

  TraceSpan startSpan({
    required String operationName,
    String? traceId,
    String? parentSpanId,
    Map<String, String> tags = const {},
  }) {
    final effectiveTraceId = traceId ?? 'trace_${DateTime.now().microsecondsSinceEpoch}';
    final spanId = 'span_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000)}';

    final span = TraceSpan(
      traceId: effectiveTraceId,
      spanId: spanId,
      parentSpanId: parentSpanId,
      operationName: operationName,
      startTime: DateTime.now(),
      tags: tags,
    );

    _activeSpans[spanId] = span;
    return span;
  }

  void finishSpan(TraceSpan span) {
    span.finish();
    _activeSpans.remove(span.spanId);
    _completedSpans.insert(0, span);
    recordLatency('span_duration_ms', span.durationMs ?? 0, tags: {'operation': span.operationName});
    notifyListeners();
  }

  // ─── 4. Crash Reporting & Breadcrumbs ─────────────────────────────────────

  void addBreadcrumb(String message) {
    final entry = '${DateTime.now().toIso8601String()} • $message';
    _breadcrumbs.insert(0, entry);
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeLast();
    }
  }

  CrashReport recordCrash(dynamic error, StackTrace stackTrace, {Map<String, String>? context}) {
    final now = DateTime.now();
    final report = CrashReport(
      reportId: 'crash_${now.millisecondsSinceEpoch}',
      timestamp: now,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      deviceInfo: {
        'platform': defaultTargetPlatform.name,
        'appVersion': '1.0.0+2026',
        ...?context,
      },
      breadcrumbs: List.from(_breadcrumbs),
    );

    _crashReports.insert(0, report);
    logError('CRASH_REPORTER', 'Uncaught application error recorded: $error', {
      'reportId': report.reportId,
    });
    notifyListeners();
    return report;
  }

  // ─── 5. Failure Monitoring & Operational Alerting ─────────────────────────

  void recordOrderFailure(String reason, {Map<String, dynamic>? context}) {
    _consecutiveOrderFailures++;
    incrementCounter('order_failure_count', tags: {'reason': reason});
    logWarn('ORDER_MONITOR', 'Order execution failure recorded: $reason', context ?? {});

    // Alert threshold: 3 consecutive failures trigger high priority alert
    if (_consecutiveOrderFailures >= 3) {
      try {
        _ref?.read(notificationServiceProvider).notify(NotificationItem(
          id: 'alert_order_burst_fail_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.securityAlert,
          category: NotificationCategory.security,
          title: 'System Alert: Elevated Order Rejection Rate',
          body: '$_consecutiveOrderFailures consecutive order failures detected. Check exchange connectivity and RMS freeze limits.',
          timestamp: DateTime.now(),
          deepLink: '/history',
          isCritical: true,
        ));
      } catch (_) {}
    }
  }

  void resetOrderFailureCounter() {
    _consecutiveOrderFailures = 0;
  }

  void recordMarketDataLatency(String token, int latencyMs) {
    recordLatency('market_data_tick_latency', latencyMs, tags: {'token': token});

    if (latencyMs > 500) {
      _marketDataLatencyBreachCount++;
      logWarn('FEED_MONITOR', 'Market data latency breach: $latencyMs ms for $token', {
        'token': token,
        'latencyMs': latencyMs,
      });

      if (_marketDataLatencyBreachCount >= 5) {
        try {
          _ref?.read(notificationServiceProvider).notify(NotificationItem(
            id: 'alert_feed_latency_${DateTime.now().millisecondsSinceEpoch}',
            type: NotificationType.securityAlert,
            category: NotificationCategory.security,
            title: 'High Market Data Latency Detected',
            body: 'Market data latency exceeded SLA (500ms) for $token ($latencyMs ms). Falling back to cached tick streams.',
            timestamp: DateTime.now(),
            deepLink: '/quotes',
            isCritical: false,
          ));
        } catch (_) {}
        _marketDataLatencyBreachCount = 0;
      }
    }
  }

  int get consecutivePaymentFailures => _consecutivePaymentFailures;

  void resetPaymentFailureCounter() {
    _consecutivePaymentFailures = 0;
  }

  void recordPaymentFailure(String paymentRef, String reason) {
    _consecutivePaymentFailures++;
    incrementCounter('payment_failure_count', tags: {'ref': paymentRef});
    logError('PAYMENT_MONITOR', 'Payment gateway failure for $paymentRef: $reason');

    if (_consecutivePaymentFailures >= 3) {
      logWarn('PAYMENT_MONITOR', 'Elevated payment failure rate: $_consecutivePaymentFailures failures');
    }

    try {
      _ref?.read(notificationServiceProvider).notify(NotificationItem(
        id: 'alert_pay_fail_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.depositFailed,
        category: NotificationCategory.funds,
        title: 'Payment Gateway Interruption',
        body: 'Payment for $paymentRef could not be settled: $reason',
        timestamp: DateTime.now(),
        deepLink: '/funds',
        isCritical: true,
      ));
    } catch (_) {}
  }
}

final observabilityServiceProvider = ChangeNotifierProvider<ObservabilityService>((ref) {
  return ObservabilityService(ref);
});
