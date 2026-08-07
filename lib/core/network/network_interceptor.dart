// lib/core/network/network_interceptor.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------

/// A normalized classification of network failures, independent of the
/// underlying [DioException] shape.
enum NetworkFailureType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  cancelled,
  unknown,
}

// ---------------------------------------------------------------------
// Failure Model
// ---------------------------------------------------------------------

/// A friendly, UI-safe representation of a failed network request.
class NetworkFailure {
  const NetworkFailure({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final NetworkFailureType type;
  final String message;
  final int? statusCode;

  NetworkFailure copyWith({
    NetworkFailureType? type,
    String? message,
    int? statusCode,
  }) {
    return NetworkFailure(
      type: type ?? this.type,
      message: message ?? this.message,
      statusCode: statusCode ?? this.statusCode,
    );
  }

  @override
  String toString() {
    return 'NetworkFailure(type: $type, statusCode: $statusCode, '
        'message: $message)';
  }
}

// ---------------------------------------------------------------------
// Interceptor Class
// ---------------------------------------------------------------------

/// Centralized networking middleware for Student AI Companion.
///
/// Injects authorization tokens, blocks requests when offline, measures
/// request timing, logs requests/responses/errors, maps failures into
/// friendly [NetworkFailure]s, and exposes analytics-ready hooks — all
/// without ever crashing the app, even if a supplied callback throws.
class NetworkInterceptor extends Interceptor {
  NetworkInterceptor({
    this.getAccessToken,
    this.hasConnection,
    this.onUnauthorized,
    this.onFailure,
    this.onAnalyticsEvent,
  });

  final Future<String?> Function()? getAccessToken;
  final Future<bool> Function()? hasConnection;
  final Future<void> Function()? onUnauthorized;
  final void Function(NetworkFailure failure)? onFailure;
  final void Function(String event, Map<String, dynamic> data)? onAnalyticsEvent;

  // ---------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------

  final Map<String, DateTime> _requestTimes = <String, DateTime>{};

  // ---------------------------------------------------------------------
  // Request Handling
  // ---------------------------------------------------------------------

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String requestId =
        '${options.method}_${options.path}_${DateTime.now().millisecondsSinceEpoch}';
    _requestTimes[_requestKey(options)] = DateTime.now();

    // -- Connectivity check ---------------------------------------------
    if (hasConnection != null) {
      bool online = true;
      try {
        online = await hasConnection!.call();
      } catch (error) {
        debugPrint('NetworkInterceptor connectivity check failed: $error');
      }

      if (!online) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: 'No internet connection',
          ),
        );
        return;
      }
    }

    // -- Authorization token ----------------------------------------------
    if (getAccessToken != null) {
      try {
        final String? token = await getAccessToken!.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (error) {
        debugPrint('NetworkInterceptor token injection failed: $error');
      }
    }

    // -- Default headers ---------------------------------------------------
    options.headers['X-App-Platform'] = 'android';
    options.headers['X-App-Name'] = 'StudentAICompanion';
    options.headers['X-Request-Time'] = DateTime.now().toIso8601String();

    // -- Logging -------------------------------------------------------------
    if (kDebugMode) {
      debugPrint('→ [$requestId] ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('   Query: ${options.queryParameters}');
      }
      debugPrint('   Headers: ${_safeHeadersPreview(options.headers)}');
      if (options.data != null) {
        debugPrint('   Body: ${_safeBodyPreview(options.data)}');
      }
    }

    // -- Analytics -----------------------------------------------------------
    _safeAnalytics('request_started', <String, dynamic>{
      'requestId': requestId,
      'method': options.method,
      'path': options.path,
    });

    handler.next(options);
  }

  // ---------------------------------------------------------------------
  // Response Handling
  // ---------------------------------------------------------------------

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final String key = _requestKey(response.requestOptions);
    final DateTime? startedAt = _requestTimes.remove(key);
    final int durationMs = startedAt == null
        ? -1
        : DateTime.now().difference(startedAt).inMilliseconds;

    if (kDebugMode) {
      final int sizeEstimate = response.data?.toString().length ?? 0;
      debugPrint(
        '✓ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.path} (${durationMs}ms, '
        '~$sizeEstimate chars)',
      );
    }

    _safeAnalytics('request_completed', <String, dynamic>{
      'method': response.requestOptions.method,
      'path': response.requestOptions.path,
      'statusCode': response.statusCode,
      'durationMs': durationMs,
    });

    handler.next(response);
  }

  // ---------------------------------------------------------------------
  // Error Handling
  // ---------------------------------------------------------------------

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String key = _requestKey(err.requestOptions);
    final DateTime? startedAt = _requestTimes.remove(key);
    final int durationMs = startedAt == null
        ? -1
        : DateTime.now().difference(startedAt).inMilliseconds;

    final NetworkFailure failure = _mapFailure(err);

    if (failure.statusCode == 401 && onUnauthorized != null) {
      try {
        onUnauthorized!.call();
      } catch (error) {
        debugPrint('NetworkInterceptor onUnauthorized callback failed: $error');
      }
    }

    try {
      onFailure?.call(failure);
    } catch (error) {
      debugPrint('NetworkInterceptor onFailure callback failed: $error');
    }

    debugPrint('✗ NETWORK ERROR');
    debugPrint('Type: ${failure.type.name}');
    debugPrint('Status: ${failure.statusCode ?? '-'}');
    debugPrint('Path: ${err.requestOptions.path}');
    debugPrint('Message: ${failure.message}');

    _safeAnalytics('request_failed', <String, dynamic>{
      'method': err.requestOptions.method,
      'path': err.requestOptions.path,
      'statusCode': failure.statusCode,
      'durationMs': durationMs,
      'failureType': failure.type.name,
    });

    handler.next(err);
  }

  /// Maps a raw [DioException] into a friendly, student-facing
  /// [NetworkFailure].
  NetworkFailure _mapFailure(DioException error) {
    final int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          type: NetworkFailureType.noInternet,
          message: 'No internet connection. Nova AI will continue working '
              'with offline data.',
        );
      case DioExceptionType.connectionTimeout:
        return const NetworkFailure(
          type: NetworkFailureType.timeout,
          message: 'Unable to reach the server. Please check your '
              'connection and try again.',
        );
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure(
          type: NetworkFailureType.timeout,
          message: 'The server is taking too long to respond. Please try '
              'again in a moment.',
        );
      case DioExceptionType.cancel:
        return const NetworkFailure(
          type: NetworkFailureType.cancelled,
          message: 'Request was cancelled.',
        );
      case DioExceptionType.badResponse:
        return _mapStatusCode(statusCode);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return NetworkFailure(
          type: NetworkFailureType.unknown,
          message: 'Something went wrong while communicating with the '
              'server.',
          statusCode: statusCode,
        );
    }
  }

  NetworkFailure _mapStatusCode(int? statusCode) {
    if (statusCode == 401) {
      return const NetworkFailure(
        type: NetworkFailureType.unauthorized,
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    if (statusCode == 403) {
      return const NetworkFailure(
        type: NetworkFailureType.forbidden,
        message: 'Access denied for this request.',
        statusCode: 403,
      );
    }
    if (statusCode == 404) {
      return const NetworkFailure(
        type: NetworkFailureType.notFound,
        message: 'The requested service could not be found.',
        statusCode: 404,
      );
    }
    if (statusCode == 429) {
      return const NetworkFailure(
        type: NetworkFailureType.rateLimited,
        message: 'Nova AI is receiving too many requests right now. '
            'Please wait a few seconds and try again.',
        statusCode: 429,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return NetworkFailure(
        type: NetworkFailureType.serverError,
        message: 'The server encountered a problem. Please try again '
            'later.',
        statusCode: statusCode,
      );
    }

    return NetworkFailure(
      type: NetworkFailureType.unknown,
      message: 'Something went wrong while communicating with the server.',
      statusCode: statusCode,
    );
  }

  void _safeAnalytics(String event, Map<String, dynamic> data) {
    try {
      onAnalyticsEvent?.call(event, data);
    } catch (error) {
      debugPrint('NetworkInterceptor analytics callback failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Utility Helpers
  // ---------------------------------------------------------------------

  static const List<String> _sensitiveHeaderKeys = <String>[
    'authorization',
    'cookie',
    'set-cookie',
  ];

  /// Converts [data] to a truncated, crash-safe string preview.
  String _safeBodyPreview(dynamic data) {
    try {
      final String stringified = data.toString();
      if (stringified.length <= 300) return stringified;
      return '${stringified.substring(0, 300)}… (truncated)';
    } catch (error) {
      return '<unserializable body: $error>';
    }
  }

  /// Returns a copy of [headers] with sensitive values redacted.
  String _safeHeadersPreview(Map<String, dynamic> headers) {
    final Map<String, dynamic> redacted = <String, dynamic>{};

    headers.forEach((String key, dynamic value) {
      if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
        redacted[key] = '••••••';
      } else {
        redacted[key] = value;
      }
    });

    return redacted.toString();
  }

  /// A stable key identifying a logical request, used to correlate
  /// start times between [onRequest] and [onResponse]/[onError].
  String _requestKey(RequestOptions options) {
    return '${options.method}_${options.path}';
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

class _LogEntry {
  _LogEntry({required this.type, required this.message, required this.time});

  final String type;
  final String message;
  final DateTime time;
}

/// A preview dashboard exercising [NetworkInterceptor] on a dark
/// futuristic background, with live simulated network events.
class NetworkInterceptorDemo extends StatefulWidget {
  const NetworkInterceptorDemo({super.key});

  @override
  State<NetworkInterceptorDemo> createState() =>
      _NetworkInterceptorDemoState();
}

class _NetworkInterceptorDemoState extends State<NetworkInterceptorDemo> {
  late final Dio _dio;
  int _requestsMonitored = 0;
  int _failuresDetected = 0;
  int _lastResponseTimeMs = 0;
  final List<_LogEntry> _logs = <_LogEntry>[];

  @override
  void initState() {
    super.initState();

    _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 6)));
    _dio.interceptors.add(
      NetworkInterceptor(
        hasConnection: () async => true,
        getAccessToken: () async => 'demo_token',
        onUnauthorized: () async =>
            _addLog('warning', 'Session expired — please sign in again.'),
        onFailure: (NetworkFailure failure) {
          _failuresDetected++;
          _addLog('error', failure.message);
        },
        onAnalyticsEvent: (String event, Map<String, dynamic> data) {
          if (event == 'request_started') {
            _requestsMonitored++;
            _addLog('request', 'Request started: ${data['method']} ${data['path']}');
          } else if (event == 'request_completed') {
            _lastResponseTimeMs = (data['durationMs'] as int?) ?? 0;
            _addLog(
              'success',
              'Completed ${data['statusCode']} in ${data['durationMs']}ms',
            );
          }
        },
      ),
    );
  }

  void _addLog(String type, String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, _LogEntry(type: type, message: message, time: DateTime.now()));
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  Future<void> _simulateSuccess() async {
    try {
      await _dio.get<dynamic>('https://jsonplaceholder.typicode.com/todos/1');
    } catch (_) {
      // Failure already logged via the interceptor's onFailure hook.
    }
  }

  Future<void> _simulateUnauthorized() async {
    try {
      await _dio.get<dynamic>('https://httpbin.org/status/401');
    } catch (_) {}
  }

  Future<void> _simulateTimeout() async {
    try {
      await _dio.get<dynamic>(
        'https://httpbin.org/delay/10',
        options: Options(receiveTimeout: const Duration(seconds: 2)),
      );
    } catch (_) {}
  }

  Future<void> _simulateNoInternet() async {
    final NetworkInterceptor offlineInterceptor = NetworkInterceptor(
      hasConnection: () async => false,
      onFailure: (NetworkFailure failure) {
        _failuresDetected++;
        _addLog('error', failure.message);
      },
    );

    final Dio offlineDio = Dio()..interceptors.add(offlineInterceptor);
    try {
      await offlineDio.get<dynamic>('https://example.com');
    } catch (_) {}
  }

  Future<void> _simulateRateLimit() async {
    try {
      await _dio.get<dynamic>('https://httpbin.org/status/429');
    } catch (_) {}
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _requestsMonitored = 0;
      _failuresDetected = 0;
      _lastResponseTimeMs = 0;
    });
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF34D399);
      case 'warning':
        return const Color(0xFFFBBF24);
      case 'error':
        return const Color(0xFFFF6B5B);
      case 'request':
      default:
        return const Color(0xFF00E5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1020), Color(0xFF121A2F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Network Interceptor Demo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "This interceptor acts as Nova AI's secure networking "
                      'shield, providing authentication, offline awareness, '
                      'intelligent error handling, analytics hooks, and '
                      'enterprise-grade request monitoring for every API '
                      'call in the app.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _button('Simulate Successful Request', _simulateSuccess),
                        _button('Simulate Unauthorized Error', _simulateUnauthorized),
                        _button('Simulate Timeout Error', _simulateTimeout),
                        _button('Simulate No Internet Error', _simulateNoInternet),
                        _button('Simulate Rate Limit Error', _simulateRateLimit),
                        OutlinedButton(
                          onPressed: _clearLogs,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Clear Logs', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(child: _buildConsole()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.2),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _stat('Active', const Color(0xFF34D399)),
          _stat('$_requestsMonitored Requests', const Color(0xFF00E5FF)),
          _stat('$_failuresDetected Failures', const Color(0xFFFF6B5B)),
          _stat('${_lastResponseTimeMs}ms', const Color(0xFF7C4DFF)),
        ],
      ),
    );
  }

  Widget _stat(String label, Color color) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: _logs.isEmpty
          ? Center(
              child: Text(
                'No events yet — try one of the simulate buttons above.',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (BuildContext context, int index) {
                final _LogEntry entry = _logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.circle, size: 8, color: _colorForType(entry.type)),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.time.hour.toString().padLeft(2, '0')}:'
                        '${entry.time.minute.toString().padLeft(2, '0')}:'
                        '${entry.time.second.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _button(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: () async {
        await onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

