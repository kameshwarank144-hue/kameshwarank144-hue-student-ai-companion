// lib/core/network/dio_client.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Central HTTP networking layer for Student AI Companion.
///
/// Powers OpenAI and Gemini requests, is Firebase-callable-ready, and
/// provides a generic REST client with automatic JSON handling,
/// authorization support, request/response/error logging, timeout
/// handling, a retry mechanism with exponential backoff, and friendly
/// error messages.
class DioClient {
  DioClient._() {
    _dio = Dio();
    _initialize();
  }

  static final DioClient instance = DioClient._();

  late final Dio _dio;

  Dio get dio => _dio;

  // ---------------------------------------------------------------------
  // Configuration Constants
  // ---------------------------------------------------------------------

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const int _maxRetries = 2;
  static const List<Duration> _retryDelays = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  void _initialize() {
    _dio.options = BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      responseType: ResponseType.json,
      contentType: 'application/json',
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(_buildLoggingInterceptor());
  }

  // ---------------------------------------------------------------------
  // Interceptors
  // ---------------------------------------------------------------------

  Interceptor _buildLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        options.extra['start_time'] = DateTime.now();

        if (kDebugMode) {
          debugPrint('➡️ ${options.method} ${options.uri}');
          debugPrint('   Headers: ${options.headers}');
          if (options.queryParameters.isNotEmpty) {
            debugPrint('   Query: ${options.queryParameters}');
          }
          if (options.data != null) {
            debugPrint('   Body: ${_truncate(options.data.toString())}');
          }
        }

        handler.next(options);
      },
      onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
        if (kDebugMode) {
          final DateTime? start =
              response.requestOptions.extra['start_time'] as DateTime?;
          final int elapsedMs = start == null
              ? -1
              : DateTime.now().difference(start).inMilliseconds;

          debugPrint(
            '✅ ${response.statusCode} ${response.requestOptions.uri} '
            '(${elapsedMs}ms)',
          );
          debugPrint('   Response: ${_truncate(response.data.toString())}');
        }

        handler.next(response);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        debugPrint(
          '❌ ${error.response?.statusCode ?? '-'} '
          '${error.requestOptions.uri} — ${error.type}',
        );
        debugPrint('   ${getFriendlyError(error)}');

        handler.next(error);
      },
    );
  }

  String _truncate(String value, {int max = 500}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}… (truncated)';
  }

  // ---------------------------------------------------------------------
  // Retry Logic
  // ---------------------------------------------------------------------

  bool _isRetryable(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Retries [requestOptions] up to [_maxRetries] times with exponential
  /// backoff (1s, then 2s), but only for connection timeouts, receive
  /// timeouts, and general network errors.
  Future<Response<T>> _retryRequest<T>(RequestOptions requestOptions) async {
    DioException? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      await Future<void>.delayed(_retryDelays[attempt]);

      try {
        debugPrint(
          'Retrying request (attempt ${attempt + 1}/$_maxRetries): '
          '${requestOptions.path}',
        );
        return await _dio.fetch<T>(requestOptions);
      } on DioException catch (error) {
        lastError = error;
        if (!_isRetryable(error)) {
          throw error;
        }
      }
    }

    throw lastError!;
  }

  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (_isRetryable(error)) {
        return _retryRequest<T>(error.requestOptions);
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Generic HTTP Methods
  // ---------------------------------------------------------------------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _executeWithRetry<T>(
        () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
      );
    } on DioException catch (error) {
      debugPrint('DioClient.get failed: ${getFriendlyError(error)}');
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _executeWithRetry<T>(
        () => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );
    } on DioException catch (error) {
      debugPrint('DioClient.post failed: ${getFriendlyError(error)}');
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _executeWithRetry<T>(
        () => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );
    } on DioException catch (error) {
      debugPrint('DioClient.put failed: ${getFriendlyError(error)}');
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _executeWithRetry<T>(
        () => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ),
      );
    } on DioException catch (error) {
      debugPrint('DioClient.delete failed: ${getFriendlyError(error)}');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // OpenAI Integration
  // ---------------------------------------------------------------------

  /// Sends a chat completion request to OpenAI and returns the
  /// assistant's reply as plain text. Returns a safe fallback string if
  /// the response is malformed.
  Future<String> sendOpenAiChat({
    required String apiKey,
    required List<Map<String, String>> messages,
    String model = 'gpt-4o-mini',
  }) async {
    try {
      final Response<dynamic> response = await post<dynamic>(
        '$openAiBaseUrl/chat/completions',
        options: Options(
          headers: <String, String>{'Authorization': 'Bearer $apiKey'},
        ),
        data: <String, dynamic>{
          'model': model,
          'messages': messages,
        },
      );

      final dynamic choices = response.data is Map ? response.data['choices'] : null;
      if (choices is List && choices.isNotEmpty) {
        final dynamic message = choices.first['message'];
        final dynamic content = message is Map ? message['content'] : null;
        if (content is String) return content.trim();
      }

      debugPrint('DioClient.sendOpenAiChat: unexpected response shape');
      return "Nova AI couldn't read that response. Please try again.";
    } on DioException catch (error) {
      debugPrint('DioClient.sendOpenAiChat failed: ${getFriendlyError(error)}');
      return getFriendlyError(error);
    } catch (error) {
      debugPrint('DioClient.sendOpenAiChat unexpected error: $error');
      return 'Something went wrong. Please try again.';
    }
  }

  // ---------------------------------------------------------------------
  // Gemini Integration
  // ---------------------------------------------------------------------

  /// Sends a text prompt to Gemini and returns the generated text.
  /// Returns a safe fallback string if the response is malformed.
  Future<String> sendGeminiPrompt({
    required String apiKey,
    required String prompt,
    String model = 'gemini-1.5-flash',
  }) async {
    try {
      final Response<dynamic> response = await post<dynamic>(
        '$geminiBaseUrl/models/$model:generateContent',
        queryParameters: <String, dynamic>{'key': apiKey},
        data: <String, dynamic>{
          'contents': <Map<String, dynamic>>[
            <String, dynamic>{
              'parts': <Map<String, String>>[
                <String, String>{'text': prompt},
              ],
            },
          ],
        },
      );

      final dynamic candidates =
          response.data is Map ? response.data['candidates'] : null;
      if (candidates is List && candidates.isNotEmpty) {
        final dynamic content = candidates.first['content'];
        final dynamic parts = content is Map ? content['parts'] : null;
        if (parts is List && parts.isNotEmpty) {
          final dynamic text = parts.first['text'];
          if (text is String) return text.trim();
        }
      }

      debugPrint('DioClient.sendGeminiPrompt: unexpected response shape');
      return "Nova AI couldn't read that response. Please try again.";
    } on DioException catch (error) {
      debugPrint('DioClient.sendGeminiPrompt failed: ${getFriendlyError(error)}');
      return getFriendlyError(error);
    } catch (error) {
      debugPrint('DioClient.sendGeminiPrompt unexpected error: $error');
      return 'Something went wrong. Please try again.';
    }
  }

  // ---------------------------------------------------------------------
  // Error Mapping
  // ---------------------------------------------------------------------

  /// Converts a [DioException] into a short, student-friendly message
  /// suitable for direct display in the UI.
  String getFriendlyError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Unable to reach the server. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return _messageForStatusCode(error.response?.statusCode);
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  String _messageForStatusCode(int? statusCode) {
    if (statusCode == null) return 'Something went wrong. Please try again.';

    if (statusCode == 400) return 'Invalid request.';
    if (statusCode == 401) return 'Authentication failed.';
    if (statusCode == 403) return 'Access denied.';
    if (statusCode == 404) return 'Service not found.';
    if (statusCode == 429) return 'Too many requests. Please wait a moment.';
    if (statusCode >= 500) return 'Server error. Please try again later.';

    return 'Something went wrong. Please try again.';
  }

  // ---------------------------------------------------------------------
  // API Availability Helpers
  // ---------------------------------------------------------------------

  bool isOpenAiConfigured(String? apiKey) {
    return apiKey != null && apiKey.trim().isNotEmpty;
  }

  bool isGeminiConfigured(String? apiKey) {
    return apiKey != null && apiKey.trim().isNotEmpty;
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

/// A preview dashboard exercising [DioClient] on a dark futuristic
/// background.
class DioClientDemo extends StatefulWidget {
  const DioClientDemo({super.key});

  @override
  State<DioClientDemo> createState() => _DioClientDemoState();
}

class _DioClientDemoState extends State<DioClientDemo> {
  final DioClient _client = DioClient.instance;

  String _lastUrl = '—';
  String _lastStatus = '—';
  String _lastError = '—';
  String _lastPreview = '—';

  Future<void> _testGet() async {
    try {
      final Response<dynamic> response = await _client.get<dynamic>(
        'https://jsonplaceholder.typicode.com/todos/1',
      );
      setState(() {
        _lastUrl = response.requestOptions.uri.toString();
        _lastStatus = '${response.statusCode}';
        _lastError = '—';
        _lastPreview = response.data.toString();
      });
    } on DioException catch (error) {
      _showError(error);
    }
  }

  Future<void> _testPost() async {
    try {
      final Response<dynamic> response = await _client.post<dynamic>(
        'https://jsonplaceholder.typicode.com/posts',
        data: <String, dynamic>{'title': 'Nova AI test', 'body': 'Hello'},
      );
      setState(() {
        _lastUrl = response.requestOptions.uri.toString();
        _lastStatus = '${response.statusCode}';
        _lastError = '—';
        _lastPreview = response.data.toString();
      });
    } on DioException catch (error) {
      _showError(error);
    }
  }

  Future<void> _testTimeout() async {
    try {
      await _client.get<dynamic>(
        'https://httpbin.org/delay/30',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
    } on DioException catch (error) {
      _showError(error);
    }
  }

  Future<void> _testOpenAiMock() async {
    const String apiKey = '';
    if (!_client.isOpenAiConfigured(apiKey)) {
      setState(() {
        _lastUrl = DioClient.openAiBaseUrl;
        _lastStatus = 'Not configured';
        _lastError = '—';
        _lastPreview = 'No OpenAI API key configured. Add one in Settings '
            'to enable live responses.';
      });
      return;
    }
    final String reply = await _client.sendOpenAiChat(
      apiKey: apiKey,
      messages: <Map<String, String>>[
        <String, String>{'role': 'user', 'content': 'Hello Nova'},
      ],
    );
    setState(() => _lastPreview = reply);
  }

  Future<void> _testGeminiMock() async {
    const String apiKey = '';
    if (!_client.isGeminiConfigured(apiKey)) {
      setState(() {
        _lastUrl = DioClient.geminiBaseUrl;
        _lastStatus = 'Not configured';
        _lastError = '—';
        _lastPreview = 'No Gemini API key configured. Add one in Settings '
            'to enable live responses.';
      });
      return;
    }
    final String reply = await _client.sendGeminiPrompt(
      apiKey: apiKey,
      prompt: 'Hello Nova',
    );
    setState(() => _lastPreview = reply);
  }

  void _showFriendlyErrorExamples() {
    setState(() {
      _lastUrl = '—';
      _lastStatus = '—';
      _lastError = '—';
      _lastPreview = <String>[
        '400 → Invalid request.',
        '401 → Authentication failed.',
        '403 → Access denied.',
        '404 → Service not found.',
        '429 → Too many requests. Please wait a moment.',
        '500+ → Server error. Please try again later.',
      ].join('\n');
    });
  }

  void _showError(DioException error) {
    setState(() {
      _lastUrl = error.requestOptions.uri.toString();
      _lastStatus = '${error.response?.statusCode ?? error.type}';
      _lastError = _client.getFriendlyError(error);
      _lastPreview = '—';
    });
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Dio Networking Layer Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This networking layer powers Nova AI conversations, '
                  'cloud synchronization, timetable APIs, attendance '
                  'services, and future intelligent features with secure, '
                  'scalable, and reliable HTTP communication.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildConsole(),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _button('Test GET Request', _testGet),
                    _button('Test POST Request', _testPost),
                    _button('Test Timeout Handling', _testTimeout),
                    _button('Test OpenAI Request (mock)', _testOpenAiMock),
                    _button('Test Gemini Request (mock)', _testGeminiMock),
                    _button('Show Friendly Error Examples', () async {
                      _showFriendlyErrorExamples();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Dio initialized — base networking layer ready',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Connect ${DioClient.connectTimeout.inSeconds}s · '
            'Receive ${DioClient.receiveTimeout.inSeconds}s · '
            'Send ${DioClient.sendTimeout.inSeconds}s',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _consoleRow('URL', _lastUrl),
          _consoleRow('Status', _lastStatus),
          _consoleRow('Error', _lastError),
          const SizedBox(height: 8),
          Text(
            'Preview',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            _lastPreview,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _consoleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            TextSpan(text: value, style: const TextStyle(color: Colors.white70)),
          ],
        ),
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

