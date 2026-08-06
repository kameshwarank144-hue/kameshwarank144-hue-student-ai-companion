// lib/core/services/stt_service.dart

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// The current phase of Nova AI's speech recognition pipeline.
enum SttState {
  idle,
  initializing,
  listening,
  processing,
  error,
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Real-time voice recognition service for Nova AI.
///
/// Powers tap-to-talk and long-press voice input on the floating AI orb:
/// live transcription, automatic stop, and voice commands for reminders,
/// tasks, and AI chat.
class SttService {
  SttService._();

  static final SttService instance = SttService._();

  final SpeechToText _speech = SpeechToText();

  // ---------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;
  SttState _state = SttState.idle;

  ValueChanged<String>? _onResultCallback;
  Timer? _transientStateTimer;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  SttState get state => _state;

  // ---------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------

  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();
  final StreamController<SttState> _stateController =
      StreamController<SttState>.broadcast();
  final StreamController<double> _confidenceController =
      StreamController<double>.broadcast();

  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<SttState> get stateStream => _stateController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;

  void _updateState(SttState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes the speech recognition engine. Returns true if the
  /// device supports speech recognition and permission was granted.
  Future<bool> initialize() async {
    try {
      _updateState(SttState.initializing);

      final bool available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      _isInitialized = available;
      _updateState(SttState.idle);

      debugPrint('SttService initialized: $available');
      return available;
    } catch (error) {
      debugPrint('SttService.initialize failed: $error');
      _isInitialized = false;
      _updateState(SttState.error);
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Listening Control
  // ---------------------------------------------------------------------

  /// Starts listening for speech. Auto-initializes if needed, stops any
  /// previous session, and resets the previous transcript.
  Future<void> startListening({
    String localeId = 'en_US',
    Duration listenFor = const Duration(minutes: 2),
    Duration pauseFor = const Duration(seconds: 3),
    ValueChanged<String>? onResult,
  }) async {
    try {
      if (!_isInitialized) {
        final bool ready = await initialize();
        if (!ready) {
          debugPrint('SttService.startListening aborted: not available');
          return;
        }
      }

      if (_isListening) {
        await stopListening();
      }

      _onResultCallback = onResult;
      _lastWords = '';
      _confidence = 0.0;
      _transcriptController.add(_lastWords);
      _isListening = true;
      _updateState(SttState.listening);

      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      debugPrint('SttService started listening (locale: $localeId)');
    } catch (error) {
      debugPrint('SttService.startListening failed: $error');
      _isListening = false;
      _updateState(SttState.error);
      _scheduleReturnToIdle();
    }
  }

  /// Stops listening, keeping whatever was transcribed so far.
  Future<void> stopListening() async {
    try {
      await _speech.stop();
      _isListening = false;
      _updateState(SttState.idle);
      debugPrint('SttService stopped listening');
    } catch (error) {
      debugPrint('SttService.stopListening failed: $error');
    }
  }

  /// Cancels listening and discards the current session entirely.
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      _confidence = 0.0;
      _transcriptController.add(_lastWords);
      _updateState(SttState.idle);
      debugPrint('SttService listening cancelled');
    } catch (error) {
      debugPrint('SttService.cancelListening failed: $error');
    }
  }

  /// Returns the locales available for speech recognition on this
  /// device.
  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _speech.locales();
    } catch (error) {
      debugPrint('SttService.getAvailableLocales failed: $error');
      return <LocaleName>[];
    }
  }

  // ---------------------------------------------------------------------
  // Speech Result Handling
  // ---------------------------------------------------------------------

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;

    _transcriptController.add(_lastWords);
    _confidenceController.add(_confidence);
    _onResultCallback?.call(_lastWords);

    if (result.finalResult) {
      _isListening = false;
      _updateState(SttState.processing);
      _scheduleReturnToIdle();
    }
  }

  void _onStatus(String status) {
    debugPrint('SttService status: $status');

    switch (status) {
      case 'listening':
        _isListening = true;
        _updateState(SttState.listening);
        break;
      case 'notListening':
      case 'done':
        _isListening = false;
        if (_state == SttState.listening) {
          _updateState(SttState.idle);
        }
        break;
      default:
        break;
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('SttService error: $error');
    _isListening = false;
    _updateState(SttState.error);
    _scheduleReturnToIdle();
  }

  void _scheduleReturnToIdle() {
    _transientStateTimer?.cancel();
    _transientStateTimer = Timer(const Duration(seconds: 2), () {
      if (_state == SttState.processing || _state == SttState.error) {
        _updateState(SttState.idle);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Convenience Helpers
  // ---------------------------------------------------------------------

  /// Starts a short listening session tuned for quick voice tasks.
  Future<void> listenForQuickTask({ValueChanged<String>? onResult}) async {
    debugPrint('SttService: listening for quick task');
    await startListening(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 2),
      onResult: onResult,
    );
  }

  /// Starts a longer listening session tuned for conversational AI chat.
  Future<void> listenForAiChat({ValueChanged<String>? onResult}) async {
    debugPrint('SttService: listening for AI chat');
    await startListening(
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 4),
      onResult: onResult,
    );
  }

  /// Starts a short listening session tuned for creating a reminder.
  Future<void> listenForReminder({ValueChanged<String>? onResult}) async {
    debugPrint('SttService: listening for reminder');
    await startListening(
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 2),
      onResult: onResult,
    );
  }

  // ---------------------------------------------------------------------
  // Intent Helpers
  // ---------------------------------------------------------------------

  static const List<String> _reminderKeywords = <String>[
    'remind',
    'reminder',
    'tomorrow',
    'wake me',
    'don\'t forget',
  ];

  static const List<String> _taskKeywords = <String>[
    'task',
    'assignment',
    'todo',
    'to do',
    'homework',
  ];

  static const List<String> _timetableKeywords = <String>[
    'timetable',
    'class',
    'lab',
    'exam',
    'schedule',
  ];

  /// Whether [text] appears to express intent to set a reminder.
  bool containsReminderIntent(String text) {
    return _containsAny(text, _reminderKeywords);
  }

  /// Whether [text] appears to express intent to create a task.
  bool containsTaskIntent(String text) {
    return _containsAny(text, _taskKeywords);
  }

  /// Whether [text] appears to reference the timetable, classes, labs,
  /// or exams.
  bool containsTimetableIntent(String text) {
    return _containsAny(text, _timetableKeywords);
  }

  bool _containsAny(String text, List<String> keywords) {
    final String lower = text.toLowerCase();
    return keywords.any((String keyword) => lower.contains(keyword));
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Cancels any active listening session and closes all streams.
  Future<void> dispose() async {
    try {
      _transientStateTimer?.cancel();
      await _speech.cancel();
      await _transcriptController.close();
      await _stateController.close();
      await _confidenceController.close();
      debugPrint('SttService disposed');
    } catch (error) {
      debugPrint('SttService.dispose failed: $error');
    }
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen exercising every [SttService] method with live
/// status, confidence, and transcript display.
class SttServiceDemo extends StatefulWidget {
  const SttServiceDemo({super.key});

  @override
  State<SttServiceDemo> createState() => _SttServiceDemoState();
}

class _SttServiceDemoState extends State<SttServiceDemo> {
  final SttService _stt = SttService.instance;
  List<LocaleName> _locales = <LocaleName>[];

  Future<void> _showLocales() async {
    final List<LocaleName> locales = await _stt.getAvailableLocales();
    if (!mounted) return;
    setState(() => _locales = locales);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF050816),
              Color(0xFF10102A),
              Color(0xFF1B1040),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Nova AI Voice Listener',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Speak naturally. Nova AI listens in real time, '
                  "understands your study routine, reminders, tasks, and "
                  'conversations just like a caring personal assistant.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildTranscriptArea(),
                const SizedBox(height: 28),
                _buildButtons(),
                if (_locales.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 24),
                  _buildLocaleList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return StreamBuilder<SttState>(
      stream: _stt.stateStream,
      initialData: _stt.state,
      builder: (BuildContext context, AsyncSnapshot<SttState> stateSnap) {
        final SttState state = stateSnap.data ?? SttState.idle;
        final bool listening = state == SttState.listening;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: <Widget>[
                  _buildMic(listening),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          listening ? 'Listening…' : 'Idle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'State: ${state.name}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        StreamBuilder<double>(
                          stream: _stt.confidenceStream,
                          initialData: _stt.confidence,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<double> confidenceSnap,
                          ) {
                            final double confidence =
                                confidenceSnap.data ?? 0.0;
                            return Text(
                              'Confidence: ${(confidence * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMic(bool listening) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: listening ? 52 : 44,
      height: listening ? 52 : 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(listening ? 0.55 : 0.25),
            blurRadius: listening ? 26 : 12,
            spreadRadius: listening ? 3 : 1,
          ),
        ],
      ),
      child: Icon(
        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildTranscriptArea() {
    return StreamBuilder<String>(
      stream: _stt.transcriptStream,
      initialData: _stt.lastWords,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String text = snapshot.data ?? '';

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(
                text.isEmpty ? 'Your recognized speech will appear here…' : text,
                style: TextStyle(
                  color: text.isEmpty
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        _button('Initialize STT', _stt.initialize),
        _button('Start Listening', _stt.startListening),
        _button('Stop Listening', _stt.stopListening),
        _button('Cancel Listening', _stt.cancelListening),
        _button('Quick Task Mode', _stt.listenForQuickTask),
        _button('AI Chat Mode', _stt.listenForAiChat),
        _button('Reminder Mode', _stt.listenForReminder),
        _button('Show Available Locales', _showLocales),
      ],
    );
  }

  Widget _buildLocaleList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Available Locales',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._locales.take(8).map(
                (LocaleName locale) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${locale.name} (${locale.localeId})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _button(String label, Future<void> Function() onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {
        await onPressed();
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

