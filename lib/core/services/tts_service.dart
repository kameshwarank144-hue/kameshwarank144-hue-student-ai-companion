// lib/core/services/tts_service.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// The emotional tone Nova AI's voice should adopt for a given message.
enum TtsMood {
  neutral,
  happy,
  calm,
  excited,
  caring,
  warning,
  sleepy,
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Emotional text-to-speech service for Student AI Companion.
///
/// Gives Nova AI a warm, human voice for morning/night greetings,
/// timetable reminders, attendance warnings, study reminders,
/// motivational messages, and general AI chat responses.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();

  // ---------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String? _currentText;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  String? get currentText => _currentText;

  static const List<String> _motivationalMessages = <String>[
    'Small progress every day becomes big success.',
    'Consistency beats intensity. Keep showing up.',
    'Your future self will thank you for studying today.',
    'Focus on progress, not perfection.',
    "One productive hour is better than ten distracted hours. You've got this.",
  ];

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes the TTS engine with Nova AI's default voice profile and
  /// registers playback lifecycle handlers.
  Future<void> initialize() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.08);
      await _tts.setVolume(1.0);

      await _preferFemaleVoice();

      _tts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        debugPrint('TTS started speaking');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS finished speaking');
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        debugPrint('TTS cancelled');
      });

      _tts.setErrorHandler((dynamic message) {
        _isSpeaking = false;
        debugPrint('TTS error: $message');
      });

      _isInitialized = true;
      debugPrint('TtsService initialized');
    } catch (error) {
      debugPrint('TtsService.initialize failed: $error');
    }
  }

  Future<void> _preferFemaleVoice() async {
    try {
      final List<dynamic> voices = await getAvailableVoices();

      final dynamic femaleVoice = voices.firstWhere(
        (dynamic voice) {
          final String name = (voice is Map ? voice['name'] : '')
              .toString()
              .toLowerCase();
          final String locale = (voice is Map ? voice['locale'] : '')
              .toString()
              .toLowerCase();
          return name.contains('female') && locale.startsWith('en');
        },
        orElse: () => null,
      );

      if (femaleVoice is Map) {
        await setVoice(
          name: femaleVoice['name']?.toString(),
          locale: femaleVoice['locale']?.toString(),
        );
      }
    } catch (error) {
      debugPrint('TtsService._preferFemaleVoice failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Core speech
  // ---------------------------------------------------------------------

  /// Speaks [text] using the tone associated with [mood]. When
  /// [interrupt] is true (the default), any currently playing speech is
  /// stopped first.
  Future<void> speak(
    String text, {
    TtsMood mood = TtsMood.neutral,
    bool interrupt = true,
  }) async {
    try {
      if (interrupt) {
        await stop();
      }

      await _applyMood(mood);
      _currentText = text;
      await _tts.speak(text);
    } catch (error) {
      debugPrint('TtsService.speak failed: $error');
    }
  }

  /// Applies the speech rate and pitch associated with [mood].
  Future<void> _applyMood(TtsMood mood) async {
    try {
      switch (mood) {
        case TtsMood.neutral:
          await _tts.setSpeechRate(0.46);
          await _tts.setPitch(1.05);
          break;
        case TtsMood.happy:
          await _tts.setSpeechRate(0.52);
          await _tts.setPitch(1.18);
          break;
        case TtsMood.calm:
          await _tts.setSpeechRate(0.40);
          await _tts.setPitch(1.00);
          break;
        case TtsMood.excited:
          await _tts.setSpeechRate(0.58);
          await _tts.setPitch(1.22);
          break;
        case TtsMood.caring:
          await _tts.setSpeechRate(0.43);
          await _tts.setPitch(1.12);
          break;
        case TtsMood.warning:
          await _tts.setSpeechRate(0.48);
          await _tts.setPitch(0.96);
          break;
        case TtsMood.sleepy:
          await _tts.setSpeechRate(0.36);
          await _tts.setPitch(0.92);
          break;
      }
    } catch (error) {
      debugPrint('TtsService._applyMood failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Companion messages
  // ---------------------------------------------------------------------

  /// Speaks a time-of-day-appropriate greeting (morning, afternoon, or
  /// evening).
  Future<void> speakGreeting() async {
    final int hour = DateTime.now().hour;
    String message;
    TtsMood mood;

    if (hour < 12) {
      message = 'Good morning â˜€ï¸ Ready to make today productive?';
      mood = TtsMood.happy;
    } else if (hour < 17) {
      message = "Good afternoon! Let's keep today's momentum going.";
      mood = TtsMood.caring;
    } else {
      message = "Good evening! Let's wrap up today with some focused time.";
      mood = TtsMood.calm;
    }

    await speak(message, mood: mood);
  }

  /// Speaks the standard good-night message in a sleepy tone.
  Future<void> speakGoodNight() async {
    const String message =
        'Good night ðŸŒ™ You\'ve done enough for today. Put your phone '
        'down, relax your mind, and get some good sleep. Tomorrow is '
        'another chance to grow, learn, and succeed. I\'m proud of your '
        'effort ðŸ’™';

    await speak(message, mood: TtsMood.sleepy);
  }

  /// Speaks a caring, night-before reminder for tomorrow's class.
  Future<void> speakTimetableReminder({
    required String subject,
    required String time,
    String? room,
  }) async {
    final StringBuffer message = StringBuffer(
      'Tomorrow you have $subject at $time.',
    );

    if (room != null && room.trim().isNotEmpty) {
      message.write(' $room.');
    }

    message.write(' Keep your notebook and ID card ready.');

    await speak(message.toString(), mood: TtsMood.caring);
  }

  /// Speaks an attendance warning in a gentle but attentive tone.
  Future<void> speakAttendanceWarning(double percentage) async {
    final String rounded = percentage.round().toString();
    final String message =
        'Your attendance is $rounded percent. Try not to miss tomorrow\'s '
        'classes so we can stay above the safe limit.';

    await speak(message, mood: TtsMood.warning);
  }

  /// Speaks a randomly chosen motivational message.
  Future<void> speakMotivation() async {
    final int index =
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length;
    await speak(_motivationalMessages[index], mood: TtsMood.excited);
  }

  /// Speaks a caring study session reminder, optionally naming [topic].
  Future<void> speakStudyReminder({String? topic}) async {
    final StringBuffer message = StringBuffer("It's time for your study session.");

    if (topic != null && topic.trim().isNotEmpty) {
      message.write(' Topic: $topic.');
    }

    message.write(' Small focused sessions create big results.');

    await speak(message.toString(), mood: TtsMood.caring);
  }

  // ---------------------------------------------------------------------
  // Playback control
  // ---------------------------------------------------------------------

  /// Stops any currently playing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      _isPaused = false;
    } catch (error) {
      debugPrint('TtsService.stop failed: $error');
    }
  }

  /// Pauses the currently playing speech, where supported by the
  /// platform.
  Future<void> pause() async {
    try {
      await _tts.pause();
      _isPaused = true;
      _isSpeaking = false;
    } catch (error) {
      debugPrint('TtsService.pause failed: $error');
    }
  }

  /// Resumes speech after a [pause]. The underlying TTS engine does not
  /// support true mid-utterance resume on all platforms, so this
  /// re-speaks the last spoken text from the beginning.
  Future<void> resume() async {
    try {
      if (_isPaused && _currentText != null) {
        _isPaused = false;
        await _tts.speak(_currentText!);
      }
    } catch (error) {
      debugPrint('TtsService.resume failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Voice selection
  // ---------------------------------------------------------------------

  /// Returns the list of voices available on the current device.
  Future<List<dynamic>> getAvailableVoices() async {
    try {
      final dynamic voices = await _tts.getVoices;
      if (voices is List) return voices;
      return <dynamic>[];
    } catch (error) {
      debugPrint('TtsService.getAvailableVoices failed: $error');
      return <dynamic>[];
    }
  }

  /// Sets the active voice by [name] and [locale], when supported.
  Future<void> setVoice({String? name, String? locale}) async {
    try {
      await _tts.setVoice(<String, String>{
        'name': name ?? '',
        'locale': locale ?? 'en-US',
      });
    } catch (error) {
      debugPrint('TtsService.setVoice failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Stops any active speech and releases service state.
  Future<void> dispose() async {
    try {
      await _tts.stop();
      _isInitialized = false;
      _isSpeaking = false;
      _isPaused = false;
      _currentText = null;
      debugPrint('TtsService disposed');
    } catch (error) {
      debugPrint('TtsService.dispose failed: $error');
    }
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview dashboard exercising every [TtsService] method and mood on
/// a dark, futuristic background.
class TtsServiceDemo extends StatefulWidget {
  const TtsServiceDemo({super.key});

  @override
  State<TtsServiceDemo> createState() => _TtsServiceDemoState();
}

class _TtsServiceDemoState extends State<TtsServiceDemo> {
  final TtsService _tts = TtsService.instance;

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
                  'Nova AI Voice Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Warm, emotional voice interactions make the AI '
                  'companion feel like a caring friend, mentor, and study '
                  'partner rather than a robotic assistant.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                _buildSection(
                  title: 'Playback',
                  buttons: <Widget>[
                    _button('Initialize', _tts.initialize),
                    _button('Stop', _tts.stop),
                    _button('Pause', _tts.pause),
                    _button('Resume', _tts.resume),
                  ],
                ),
                _buildSection(
                  title: 'Companion Messages',
                  buttons: <Widget>[
                    _button('Speak Greeting', _tts.speakGreeting),
                    _button('Speak Good Night', _tts.speakGoodNight),
                    _button(
                      'Timetable Reminder',
                      () => _tts.speakTimetableReminder(
                        subject: 'Digital Electronics',
                        time: '8:30 AM',
                        room: 'Room 302',
                      ),
                    ),
                    _button(
                      'Attendance Warning',
                      () => _tts.speakAttendanceWarning(78),
                    ),
                    _button('Motivation', _tts.speakMotivation),
                    _button(
                      'Study Reminder',
                      () => _tts.speakStudyReminder(
                        topic: 'Data Structures Revision',
                      ),
                    ),
                  ],
                ),
                _buildSection(
                  title: 'Voice Moods',
                  buttons: <Widget>[
                    _button(
                      'Happy Voice',
                      () => _tts.speak(
                        "You're doing great today!",
                        mood: TtsMood.happy,
                      ),
                    ),
                    _button(
                      'Calm Voice',
                      () => _tts.speak(
                        "Let's take this one step at a time.",
                        mood: TtsMood.calm,
                      ),
                    ),
                    _button(
                      'Excited Voice',
                      () => _tts.speak(
                        "You're so close to your goal!",
                        mood: TtsMood.excited,
                      ),
                    ),
                    _button(
                      'Caring Voice',
                      () => _tts.speak(
                        "I'm here whenever you need me.",
                        mood: TtsMood.caring,
                      ),
                    ),
                    _button(
                      'Warning Voice',
                      () => _tts.speak(
                        'Please pay attention to this one.',
                        mood: TtsMood.warning,
                      ),
                    ),
                    _button(
                      'Sleepy Voice',
                      () => _tts.speak(
                        "It's time to rest now.",
                        mood: TtsMood.sleepy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> buttons}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: buttons),
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

