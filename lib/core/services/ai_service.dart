// lib/core/services/ai_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------

/// The emotional tone Nova AI should adopt for a given reply.
enum AiMood {
  caring,
  happy,
  motivating,
  focused,
  warning,
  sleepy,
}

// ---------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------

/// A single message in a Nova AI conversation.
class AiChatMessage {
  AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Either `'user'` or `'assistant'` (matching OpenAI-style chat roles).
  final String role;

  final String content;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// The result of parsing free-form text for a reminder request.
class AiReminderIntent {
  const AiReminderIntent({
    required this.detected,
    this.title,
    this.scheduledTime,
  });

  final bool detected;
  final String? title;
  final DateTime? scheduledTime;

  /// A "nothing detected" result.
  factory AiReminderIntent.empty() {
    return const AiReminderIntent(detected: false);
  }
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// The central "brain" behind Nova AI â€” Student AI Companion's emotional
/// assistant.
///
/// Provides friendly chat, attendance advice, timetable understanding,
/// study planning, motivational and bedtime messages, and simple
/// reminder-intent extraction. Works fully offline via local fallback
/// replies, and upgrades to an OpenAI-compatible remote model when an
/// API key is configured.
///
/// Personality: 40% caring mother, 30% supportive best friend, 20%
/// mentor, 10% light humor â€” always encouraging, never robotic, never
/// guilt-inducing.
class AiService {
  AiService._();

  static final AiService instance = AiService._();

  final List<AiChatMessage> _memory = <AiChatMessage>[];
  String? _apiKey;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<AiChatMessage> get memory => List<AiChatMessage>.unmodifiable(_memory);

  static const int _maxMemoryLength = 20;

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  static const String _systemPrompt =
      'The AI is Nova, a caring AI companion for college students. '
      'Personality: 40% caring mother, 30% supportive best friend, 20% '
      'mentor, 10% light humor. Encourage healthy habits, remind gently, '
      'never shame the user, keep responses concise (2-5 sentences), use '
      'friendly emojis occasionally, and sound emotionally intelligent. '
      "Example style: \"Don't skip breakfast today ðŸ’™\", \"You've been "
      "consistent lately, and I'm proud of that âœ¨\", \"Tomorrow's lab "
      'might feel stressful, but we\'ll handle it step by step ðŸ“š".';

  /// Initializes the service. Works fully offline via local fallback
  /// replies even when no [apiKey] is provided.
  Future<void> initialize({String? apiKey}) async {
    _apiKey = apiKey;
    _isInitialized = true;
    debugPrint('AiService initialized (remote API: ${apiKey != null})');
  }

  // ---------------------------------------------------------------------
  // Chat API
  // ---------------------------------------------------------------------

  /// Sends [message] to Nova AI and returns her reply, updating
  /// conversation memory along the way.
  Future<String> sendMessage(String message, {String? userName}) async {
    _memory.add(
      AiChatMessage(role: 'user', content: message, timestamp: DateTime.now()),
    );

    String reply;
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      reply = await _callRemoteApi(message);
    } else {
      reply = await _generateLocalReply(message);
    }

    _memory.add(
      AiChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()),
    );

    if (_memory.length > _maxMemoryLength) {
      _memory.removeRange(0, _memory.length - _maxMemoryLength);
    }

    return reply;
  }

  /// Sends a voice-transcribed [transcript] through the same chat
  /// pipeline as [sendMessage], ready for voice + text integration.
  Future<String> sendVoiceMessage(String transcript) {
    return sendMessage(transcript);
  }

  /// Calls the OpenAI-compatible chat completions API with the system
  /// prompt, recent memory, and the current message. Falls back to a
  /// local reply on any network error, timeout, or invalid API key.
  Future<String> _callRemoteApi(String message) async {
    try {
      final List<Map<String, String>> history = _memory
          .take(_maxMemoryLength)
          .map(
            (AiChatMessage msg) => <String, String>{
              'role': msg.role,
              'content': msg.content,
            },
          )
          .toList();

      final Uri uri = Uri.parse('https://api.openai.com/v1/chat/completions');

      final http.Response response = await http
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(<String, dynamic>{
              'model': 'gpt-4o-mini',
              'messages': <Map<String, String>>[
                <String, String>{'role': 'system', 'content': _systemPrompt},
                ...history,
                <String, String>{'role': 'user', 'content': message},
              ],
              'temperature': 0.8,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('AiService remote API error: ${response.statusCode}');
        return _generateLocalReply(message);
      }

      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> choices = decoded['choices'] as List<dynamic>;
      final Map<String, dynamic> firstChoice =
          choices.first as Map<String, dynamic>;
      final Map<String, dynamic> messageJson =
          firstChoice['message'] as Map<String, dynamic>;

      return (messageJson['content'] as String).trim();
    } on TimeoutException {
      debugPrint('AiService remote API timed out');
      return _generateLocalReply(message);
    } catch (error) {
      debugPrint('AiService remote API failed: $error');
      return _generateLocalReply(message);
    }
  }

  // ---------------------------------------------------------------------
  // Local Intelligence
  // ---------------------------------------------------------------------

  /// Generates a warm, keyword-aware reply without needing a remote API.
  Future<String> _generateLocalReply(String message) async {
    final String lower = message.toLowerCase();

    if (lower.contains('attendance')) {
      return "Let's take a look at your attendance together â€” staying "
          'consistent with classes makes the biggest difference. Want me '
          'to check your current percentage? ðŸ“Š';
    }

    if (lower.contains('timetable') ||
        lower.contains('class') ||
        lower.contains('lab')) {
      return 'A little prep goes a long way â€” keep your notes and charger '
          'ready tonight, and tomorrow will feel much smoother ðŸ“š';
    }

    if (lower.contains('exam') || lower.contains('test')) {
      return "Exams feel lighter with small, steady revision. Let's break "
          "it into short focused sessions instead of cramming â€” you've "
          'got this ðŸ’ª';
    }

    if (lower.contains('sad') ||
        lower.contains('tired') ||
        lower.contains('stressed') ||
        lower.contains('anxious')) {
      return "I hear you, and it's okay to feel this way sometimes. Take "
          "a slow breath â€” you don't have to carry everything at once. "
          "I'm right here with you ðŸ’™";
    }

    return "I'm here for you ðŸ˜Š Tell me more, and we'll figure it out "
        'together â€” one step at a time.';
  }

  // ---------------------------------------------------------------------
  // Study Helpers
  // ---------------------------------------------------------------------

  /// Builds a readable, multi-day study plan distributing [subjects]
  /// evenly across [daysLeft] days.
  Future<String> generateStudyPlan({
    required List<String> subjects,
    required int daysLeft,
  }) async {
    if (subjects.isEmpty || daysLeft <= 0) {
      return "Let's add a few subjects and available days first, and "
          "I'll build your study plan ðŸ“š";
    }

    final StringBuffer plan = StringBuffer('ðŸ“š $daysLeft-Day Study Plan\n');
    const List<double> hourOptions = <double>[2.0, 1.5, 1.0];

    for (int day = 1; day <= daysLeft; day++) {
      plan.write('\nDay $day\n');

      final int subjectsPerDay = subjects.length >= 2 ? 2 : 1;
      for (int slot = 0; slot < subjectsPerDay; slot++) {
        final int subjectIndex = (day - 1 + slot) % subjects.length;
        final String subject = subjects[subjectIndex];
        final double hours = hourOptions[slot % hourOptions.length];
        final String hoursLabel =
            hours == hours.roundToDouble() ? '${hours.toInt()}' : '$hours';
        plan.write('â€¢ $subject â€“ $hoursLabel hours\n');
      }
    }

    plan.write(
      "\nSmall, steady sessions beat cramming every time â€” you've got "
      'this ðŸ’™',
    );

    return plan.toString();
  }

  // ---------------------------------------------------------------------
  // Attendance Helpers
  // ---------------------------------------------------------------------

  /// Returns encouraging, never guilt-inducing advice based on [percentage].
  Future<String> analyzeAttendance({required double percentage}) async {
    if (percentage >= 90) {
      return "Your attendance is excellent at ${percentage.round()}%! "
          "You're building a habit that will pay off all semester ðŸŒŸ";
    }

    if (percentage >= 80) {
      return "You're doing well at ${percentage.round()}% â€” safely above "
          'the limit. Keep this rhythm going and you\'ll stay comfortable '
          'all term ðŸ’™';
    }

    if (percentage >= 75) {
      return "You're at ${percentage.round()}%, right around the safe "
          "line. Let's aim to attend the next few classes so you build a "
          'bit more of a buffer ðŸ“ˆ';
    }

    return "Your attendance is ${percentage.round()}%, a little below the "
        "safe limit â€” but this is completely fixable. Let's plan to "
        "attend consistently for the next couple of weeks, and we'll get "
        'you back on track together ðŸ’ª';
  }

  // ---------------------------------------------------------------------
  // Timetable Advice
  // ---------------------------------------------------------------------

  /// Generates warm, preparation-focused advice for an upcoming class.
  Future<String> generateTimetableAdvice({
    required String subject,
    required DateTime classTime,
  }) async {
    final String formattedTime = _formatTime(classTime);

    return 'Tomorrow you have $subject at $formattedTime ðŸ“š\n\n'
        'Keep your laptop charged, revise the previous lab experiment for '
        '15 minutes tonight, and sleep early so the morning feels easier. '
        "You've got this ðŸ’™";
  }

  String _formatTime(DateTime time) {
    final int hour24 = time.hour;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = hour24 >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  // ---------------------------------------------------------------------
  // Motivation & Bedtime
  // ---------------------------------------------------------------------

  static const List<String> _motivationalMessages = <String>[
    'Small progress every day becomes big success âœ¨',
    'One focused hour today is better than five distracted hours ðŸ“–',
    'Your future self will thank you for the effort you make tonight ðŸ’™',
    "You don't have to be perfect, just consistent ðŸŒ±",
    "Every page you read is a step closer to your goal ðŸ“š",
    "I'm proud of how far you've come already ðŸ’«",
    'Rest is productive too â€” balance is strength âš–ï¸',
    'You are capable of more than you think ðŸ’ª',
    'Progress, not perfection â€” keep going ðŸš€',
    "Today's effort is tomorrow's confidence ðŸŒŸ",
    'You showed up today, and that matters more than you know ðŸ’›',
  ];

  /// Returns a randomly chosen motivational message.
  Future<String> motivateUser() async {
    final int index =
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length;
    return _motivationalMessages[index];
  }

  /// Returns a warm, calming bedtime message.
  Future<String> bedtimeAdvice() async {
    return 'Good night ðŸŒ™ Put your phone down for tonight â€” you\'ve done '
        'enough today. Lay out what you need for tomorrow, take a few '
        'slow breaths, and let yourself rest. I\'m proud of the effort '
        "you made today, and tomorrow is another chance to grow ðŸ’™";
  }

  // ---------------------------------------------------------------------
  // Reminder Extraction
  // ---------------------------------------------------------------------

  /// Parses [text] for a simple reminder intent, such as "remind me
  /// tomorrow at 7", "remind me at 5 pm", "tonight at 9", or "wake me at
  /// 6". Returns [AiReminderIntent.empty] if nothing is recognized.
  Future<AiReminderIntent> extractReminderIntent(String text) async {
    final String lower = text.toLowerCase();

    final bool mentionsReminder = lower.contains('remind') ||
        lower.contains('wake me') ||
        lower.contains('reminder');

    if (!mentionsReminder) {
      return AiReminderIntent.empty();
    }

    final DateTime now = DateTime.now();
    DateTime baseDate = now;

    if (lower.contains('tomorrow')) {
      baseDate = now.add(const Duration(days: 1));
    } else if (lower.contains('tonight')) {
      baseDate = DateTime(now.year, now.month, now.day);
    }

    final RegExp timePattern = RegExp(
      r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
    );

    int? hour;
    int minute = 0;
    bool isPm = false;

    for (final RegExpMatch match in timePattern.allMatches(lower)) {
      final String? hourGroup = match.group(1);
      if (hourGroup == null) continue;

      final int parsedHour = int.tryParse(hourGroup) ?? -1;
      if (parsedHour < 1 || parsedHour > 12) continue;

      hour = parsedHour;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final String? meridiem = match.group(3);
      isPm = meridiem == 'pm';
      break;
    }

    if (hour == null) {
      if (lower.contains('morning')) {
        hour = 8;
      } else if (lower.contains('night')) {
        hour = 21;
        isPm = true;
      } else {
        return AiReminderIntent.empty();
      }
    }

    int hour24 = hour;
    if (isPm && hour24 != 12) hour24 += 12;
    if (!isPm && hour24 == 12) hour24 = 0;

    DateTime scheduled = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour24,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return AiReminderIntent(
      detected: true,
      title: 'Reminder from Nova AI',
      scheduledTime: scheduled,
    );
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Clears the entire conversation memory.
  Future<void> clearMemory() async {
    _memory.clear();
    debugPrint('AiService memory cleared');
  }

  /// Resets the service to an uninitialized state.
  Future<void> dispose() async {
    _memory.clear();
    _apiKey = null;
    _isInitialized = false;
    debugPrint('AiService disposed');
  }
}

// ---------------------------------------------------------------------
// Demo UI
// ---------------------------------------------------------------------

/// A preview Nova AI chat screen exercising every [AiService] method on
/// a premium dark, glassmorphism background.
class AiServiceDemo extends StatefulWidget {
  const AiServiceDemo({super.key});

  @override
  State<AiServiceDemo> createState() => _AiServiceDemoState();
}

class _AiServiceDemoState extends State<AiServiceDemo> {
  final AiService _ai = AiService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AiChatMessage> _messages = <AiChatMessage>[];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _ai.initialize();
    _messages.add(
      AiChatMessage(
        role: 'assistant',
        content: "Hey ðŸ‘‹ I'm Nova. How can I help you today?",
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        AiChatMessage(role: 'user', content: text, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final String reply = await _ai.sendMessage(text);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        AiChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  Future<void> _runAction(Future<String> Function() action) async {
    setState(() => _isTyping = true);
    final String reply = await action();
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        AiChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
            colors: <Color>[
              Color(0xFF050816),
              Color(0xFF10102A),
              Color(0xFF1B1040),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeader(),
              _buildQuickActions(),
              Expanded(child: _buildChatArea()),
              if (_isTyping) _buildTypingIndicator(),
              _buildSpecialButtons(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF050816), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Nova AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your caring study companion',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, Object>> chips = <Map<String, Object>>[
      <String, Object>{
        'label': 'Attendance advice',
        'action': () => _ai.analyzeAttendance(percentage: 78),
      },
      <String, Object>{
        'label': "Tomorrow's class",
        'action': () => _ai.generateTimetableAdvice(
              subject: 'Digital Electronics',
              classTime: DateTime.now().add(const Duration(days: 1, hours: 8)),
            ),
      },
      <String, Object>{
        'label': 'Study plan',
        'action': () => _ai.generateStudyPlan(
              subjects: <String>['DBMS', 'CN', 'Maths', 'OS'],
              daysLeft: 5,
            ),
      },
      <String, Object>{'label': 'Motivation', 'action': _ai.motivateUser},
      <String, Object>{'label': 'Bedtime help', 'action': _ai.bedtimeAdvice},
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, Object> chip = chips[index];
          return ActionChip(
            backgroundColor: Colors.white.withOpacity(0.08),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
            label: Text(
              chip['label']! as String,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            onPressed: () => _runAction(chip['action']! as Future<String> Function()),
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildBubble(_messages[index]);
      },
    );
  }

  Widget _buildBubble(AiChatMessage message) {
    final bool isUser = message.role == 'user';

    return TweenAnimationBuilder<double>(
      key: ValueKey<DateTime>(message.timestamp),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                  )
                : null,
            color: isUser ? null : Colors.white.withOpacity(0.08),
            border: isUser
                ? null
                : Border.all(color: Colors.white.withOpacity(0.14)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 20),
            ),
          ),
          child: Text(
            message.content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(left: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nova is typingâ€¦',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSpecialButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _smallButton('Generate Study Plan', () => _ai.generateStudyPlan(
                subjects: <String>['DBMS', 'CN', 'Maths'],
                daysLeft: 3,
              )),
          _smallButton('Check Attendance', () => _ai.analyzeAttendance(percentage: 82)),
          _smallButton('Get Motivation', _ai.motivateUser),
          _smallButton('Bedtime Advice', _ai.bedtimeAdvice),
          OutlinedButton(
            onPressed: () async {
              await _ai.clearMemory();
              setState(() => _messages.clear());
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear Memory', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _smallButton(String label, Future<String> Function() action) {
    return ElevatedButton(
      onPressed: () => _runAction(action),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.mic_none_rounded, color: Colors.white70),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: _send,
                decoration: const InputDecoration(
                  hintText: 'Ask Nova anything...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                ),
              ),
              child: IconButton(
                onPressed: () => _send(_controller.text),
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

