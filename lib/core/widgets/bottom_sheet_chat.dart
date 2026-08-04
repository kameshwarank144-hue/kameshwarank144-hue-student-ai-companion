// lib/core/widgets/bottom_sheet_chat.dart

import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Internal message model
// ---------------------------------------------------------------------

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

// ---------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------

/// The floating AI assistant chat sheet used throughout Student AI
/// Companion.
///
/// Opened when the floating AI orb is tapped, "Ask AI" is pressed, or a
/// quick assistant action is triggered. Presents a glassmorphism, dark,
/// premium chat surface in the spirit of ChatGPT mobile, the Apple Music
/// bottom sheet, and Nothing OS design language.
class BottomSheetChat extends StatefulWidget {
  const BottomSheetChat({
    super.key,
    this.initialMessage,
    this.onSend,
    this.onVoiceTap,
  });

  /// Text to pre-fill into the input field when the sheet opens, useful
  /// for quick-assistant actions that already know what to ask.
  final String? initialMessage;

  /// Called with the user's message text whenever they send one.
  final ValueChanged<String>? onSend;

  /// Called when the voice input button is tapped.
  final VoidCallback? onVoiceTap;

  /// Opens [BottomSheetChat] as a scroll-controlled, transparent modal
  /// bottom sheet that respects the device safe area.
  static Future<void> show(
    BuildContext context, {
    String? initialMessage,
    ValueChanged<String>? onSend,
    VoidCallback? onVoiceTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (BuildContext context) {
        return BottomSheetChat(
          initialMessage: initialMessage,
          onSend: onSend,
          onVoiceTap: onVoiceTap,
        );
      },
    );
  }

  @override
  State<BottomSheetChat> createState() => _BottomSheetChatState();
}

// ---------------------------------------------------------------------
// State
// ---------------------------------------------------------------------

class _BottomSheetChatState extends State<BottomSheetChat> {
  static const int _maxCharacters = 500;

  static const List<String> _defaultAiMessages = <String>[
    'Hey ðŸ‘‹ How can I help you today?',
    'Need help with attendance, timetable, or study planning?',
    "Don't worry, we'll manage your college life together.",
  ];

  static const List<String> _simulatedResponses = <String>[
    "That sounds important. Let's organize it.",
    "I've noted that for you.",
    "You're doing better than you think ðŸ’™",
    'Want me to help you create a study plan?',
  ];

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isInputFocused = false;
  bool _isAiTyping = false;
  int _responseCursor = 0;

  @override
  void initState() {
    super.initState();

    for (final String message in _defaultAiMessages) {
      _messages.add(_ChatMessage(text: message, isUser: false));
    }

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _controller.text = widget.initialMessage!;
    }

    _focusNode.addListener(() {
      setState(() => _isInputFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Send behavior
  // ---------------------------------------------------------------------

  Future<void> _handleSend() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isAiTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    widget.onSend?.call(text);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final String response =
        _simulatedResponses[_responseCursor % _simulatedResponses.length];
    _responseCursor++;

    setState(() {
      _isAiTyping = false;
      _messages.add(_ChatMessage(text: response, isUser: false));
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

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final double sheetHeight = MediaQuery.of(context).size.height * 0.82;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      height: sheetHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1020).withOpacity(0.88),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _AnimatedMessageEntry(
                        child: _buildMessageBubble(_messages[index]),
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isAiTyping
                      ? const _TypingIndicator(key: ValueKey<String>('typing'))
                      : const SizedBox.shrink(key: ValueKey<String>('idle')),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Column(
        children: <Widget>[
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF7C4DFF),
                      Color(0xFF00E5FF),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
                      'Your emotional study companion',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                splashRadius: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Message bubble
  // ---------------------------------------------------------------------

  Widget _buildMessageBubble(_ChatMessage message) {
    final Alignment alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    final BoxDecoration decoration = message.isUser
        ? BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: const Radius.circular(20),
              bottomRight: const Radius.circular(6),
            ),
          )
        : BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 1,
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: const Radius.circular(6),
              bottomRight: const Radius.circular(20),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: decoration,
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Input area
  // ---------------------------------------------------------------------

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withOpacity(_isInputFocused ? 0.35 : 0.14),
            width: 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: widget.onVoiceTap,
              icon: const Icon(Icons.mic_none_rounded, color: Colors.white70),
              splashRadius: 22,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxCharacters,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask Nova anything...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  counterText: '',
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
                onPressed: _handleSend,
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white),
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Message entrance animation
// ---------------------------------------------------------------------

/// Fades and slides a chat bubble in when it first appears, using purely
/// implicit animations.
class _AnimatedMessageEntry extends StatefulWidget {
  const _AnimatedMessageEntry({required this.child});

  final Widget child;

  @override
  State<_AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<_AnimatedMessageEntry> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: const Text(
          'Nova is typingâ€¦',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview screen showcasing [BottomSheetChat] on a dark futuristic
/// background, with a button that opens the sheet via [BottomSheetChat.show].
class BottomSheetChatDemo extends StatelessWidget {
  const BottomSheetChatDemo({super.key});

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
        child: Center(
          child: ElevatedButton(
            onPressed: () => BottomSheetChat.show(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Open AI Assistant'),
          ),
        ),
      ),
    );
  }
}

