// lib/core/utils/debouncer.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// 2. Debouncer
// ---------------------------------------------------------------------

/// A lightweight, memory-safe debouncer for Student AI Companion.
///
/// Used for AI chat typing, search bars, notes/timetable/attendance/
/// reminder filtering, quick-add task input, auto-save, network request
/// throttling, and voice transcription stabilization.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  /// How long to wait after the last call before running the action.
  final Duration delay;

  Timer? _timer;
  bool _disposed = false;

  /// Whether a debounced action is currently scheduled.
  bool get isActive => _timer?.isActive ?? false;

  /// Cancels any pending call and schedules [action] to run after
  /// [delay]. Does nothing if this debouncer has been disposed.
  void run(void Function() action) {
    if (_disposed) return;

    _timer?.cancel();
    _timer = Timer(delay, () {
      if (_disposed) return;
      action();
    });
  }

  /// Async version of [run]. Cancels any pending call, waits for
  /// [delay], then safely runs [action] — errors thrown by [action] are
  /// caught so they never crash the app.
  Future<void> runAsync(Future<void> Function() action) async {
    if (_disposed) return;

    _timer?.cancel();

    final Completer<void> completer = Completer<void>();

    _timer = Timer(delay, () async {
      if (_disposed) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      try {
        await action();
      } catch (_) {
        // Swallow errors from the debounced action; callers that need
        // to react to failures should handle them inside [action].
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  /// Cancels the currently pending call, if any.
  void cancel() {
    _timer?.cancel();
  }

  /// Cancels any pending call and runs [action] immediately — useful
  /// for "submit now" actions like a search button or explicit save.
  void flush(void Function() action) {
    if (_disposed) return;
    _timer?.cancel();
    action();
  }

  /// Cancels any pending timer and marks this debouncer as disposed.
  /// Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _timer?.cancel();
    _disposed = true;
  }

  // ---------------------------------------------------------------------
  // 3. Static Helpers
  // ---------------------------------------------------------------------

  /// Creates a [Debouncer] with a delay of [milliseconds] (default 400ms).
  static Debouncer debounce({int milliseconds = 400}) {
    return Debouncer(delay: Duration(milliseconds: milliseconds));
  }

  /// A debouncer tuned for search inputs (350ms).
  static Debouncer search() {
    return Debouncer(delay: const Duration(milliseconds: 350));
  }

  /// A debouncer tuned for AI chat typing detection (600ms).
  static Debouncer aiTyping() {
    return Debouncer(delay: const Duration(milliseconds: 600));
  }

  /// A debouncer tuned for auto-save operations (1200ms).
  static Debouncer autoSave() {
    return Debouncer(delay: const Duration(milliseconds: 1200));
  }
}

// ---------------------------------------------------------------------
// 4. MultiDebouncer
// ---------------------------------------------------------------------

/// Manages multiple named [Debouncer] instances by key — useful when a
/// screen has several independently-debounced inputs (e.g. a search
/// field and an auto-save field on the same page).
class MultiDebouncer {
  final Map<String, Debouncer> _debouncers = <String, Debouncer>{};

  Debouncer _debouncerFor(String key, Duration delay) {
    return _debouncers.putIfAbsent(key, () => Debouncer(delay: delay));
  }

  /// Runs [action] debounced under [key], reusing the existing
  /// debouncer for that key if one has already been created.
  void run(
    String key,
    void Function() action, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    _debouncerFor(key, delay).run(action);
  }

  /// Async version of [run].
  Future<void> runAsync(
    String key,
    Future<void> Function() action, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    return _debouncerFor(key, delay).runAsync(action);
  }

  /// Cancels the pending call for [key], if any.
  void cancel(String key) {
    _debouncers[key]?.cancel();
  }

  /// Cancels every pending call across all keys.
  void cancelAll() {
    for (final Debouncer debouncer in _debouncers.values) {
      debouncer.cancel();
    }
  }

  /// Disposes every managed debouncer and clears the registry.
  void dispose() {
    for (final Debouncer debouncer in _debouncers.values) {
      debouncer.dispose();
    }
    _debouncers.clear();
  }
}

// ---------------------------------------------------------------------
// 5. Demo Screen
// ---------------------------------------------------------------------

/// A preview screen showcasing [Debouncer] and [MultiDebouncer] across a
/// search field, an AI typing indicator, and an auto-save field.
class DebouncerDemoScreen extends StatefulWidget {
  const DebouncerDemoScreen({super.key});

  @override
  State<DebouncerDemoScreen> createState() => _DebouncerDemoScreenState();
}

class _DebouncerDemoScreenState extends State<DebouncerDemoScreen> {
  final Debouncer _searchDebouncer = Debouncer.search();
  final Debouncer _aiTypingDebouncer = Debouncer.aiTyping();
  final Debouncer _autoSaveDebouncer = Debouncer.autoSave();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _aiController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _searchResult = '';
  bool _isAiThinking = false;
  bool _isSaved = true;

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _aiTypingDebouncer.dispose();
    _autoSaveDebouncer.dispose();
    _searchController.dispose();
    _aiController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebouncer.run(() {
      if (!mounted) return;
      setState(() => _searchResult = value);
    });
  }

  void _onAiTyping(String value) {
    setState(() => _isAiThinking = false);
    _aiTypingDebouncer.run(() {
      if (!mounted) return;
      setState(() => _isAiThinking = value.trim().isNotEmpty);
    });
  }

  void _onNoteChanged(String value) {
    setState(() => _isSaved = false);
    _autoSaveDebouncer.run(() {
      if (!mounted) return;
      setState(() => _isSaved = true);
    });
  }

  void _saveNow() {
    _autoSaveDebouncer.flush(() {
      if (!mounted) return;
      setState(() => _isSaved = true);
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
                  'Debouncer Playground',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Premium typing, search, AI thinking, and auto-save '
                  'debouncing for Student AI Companion.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                _buildCard(
                  title: 'Search Field',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTextField(
                        controller: _searchController,
                        hint: 'Search tasks, notes, classes...',
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _searchResult.isEmpty
                              ? 'Start typing to search…'
                              : 'Searching for: $_searchResult',
                          key: ValueKey<String>(_searchResult),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'AI Typing Field',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTextField(
                        controller: _aiController,
                        hint: 'Ask Nova AI anything...',
                        onChanged: _onAiTyping,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isAiThinking
                            ? const Text(
                                'Nova AI is thinking...',
                                key: ValueKey<String>('thinking'),
                                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                              )
                            : Text(
                                'Waiting for input…',
                                key: const ValueKey<String>('idle'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Auto Save Field',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTextField(
                        controller: _noteController,
                        hint: 'Edit your note...',
                        maxLines: 3,
                        onChanged: _onNoteChanged,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isSaved ? 'All changes saved ✓' : 'Saving…',
                              key: ValueKey<bool>(_isSaved),
                              style: TextStyle(
                                color: _isSaved
                                    ? const Color(0xFF34D399)
                                    : Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _saveNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Save Now', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

