// lib/core/services/overlay_service.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------

/// The emotional/behavioral state of the floating AI orb overlay.
enum OverlayOrbState {
  idle,
  happy,
  listening,
  thinking,
  speaking,
  sleeping,
  hidden,
}

/// Quick actions the floating orb can trigger.
enum OverlayAction {
  openChat,
  startVoice,
  quickNote,
  openDashboard,
  closeOverlay,
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Manages the floating AI orb overlay assistant for Student AI
/// Companion — a system-alert-window bubble that stays above other apps,
/// similar to Messenger chat heads, Nothing OS's floating assistant, or
/// an OpenAI-style voice bubble.
class OverlayService {
  OverlayService._();

  static final OverlayService instance = OverlayService._();

  // ---------------------------------------------------------------------
  // State Management
  // ---------------------------------------------------------------------

  OverlayOrbState _currentState = OverlayOrbState.hidden;

  final StreamController<OverlayOrbState> _stateController =
      StreamController<OverlayOrbState>.broadcast();

  Timer? _sleepTimer;

  /// Broadcast stream of orb state changes.
  Stream<OverlayOrbState> get stateStream => _stateController.stream;

  /// The orb's current state.
  OverlayOrbState get currentState => _currentState;

  // ---------------------------------------------------------------------
  // Permission Handling
  // ---------------------------------------------------------------------

  /// Checks whether the "draw over other apps" permission is currently
  /// granted, without prompting the user.
  Future<bool> checkPermission() async {
    try {
      final PermissionStatus status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (error) {
      debugPrint('OverlayService.checkPermission failed: $error');
      return false;
    }
  }

  /// Requests the "draw over other apps" permission. If the permission
  /// has been permanently denied, opens the app's system settings page
  /// so the user can grant it manually.
  Future<bool> requestPermission() async {
    try {
      final PermissionStatus current = await Permission.systemAlertWindow.status;
      if (current.isGranted) {
        debugPrint('Overlay permission granted');
        return true;
      }

      final PermissionStatus result =
          await Permission.systemAlertWindow.request();

      if (result.isGranted) {
        debugPrint('Overlay permission granted');
        return true;
      }

      if (result.isPermanentlyDenied) {
        debugPrint('Overlay permission permanently denied — opening settings');
        await openAppSettings();
      } else {
        debugPrint('Overlay permission denied');
      }

      return false;
    } catch (error) {
      debugPrint('OverlayService.requestPermission failed: $error');
      return false;
    }
  }

  /// Checks whether the app is currently allowed to draw overlays,
  /// using the native overlay plugin's own permission check.
  Future<bool> canDrawOverlays() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (error) {
      debugPrint('OverlayService.canDrawOverlays failed: $error');
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Overlay Control
  // ---------------------------------------------------------------------

  /// Shows the floating AI orb overlay, requesting permission first if
  /// needed, and sets it to [initialState].
  Future<void> showOverlay({
    OverlayOrbState initialState = OverlayOrbState.idle,
  }) async {
    try {
      final bool granted = await canDrawOverlays();

      if (!granted) {
        final bool requested = await requestPermission();
        if (!requested) {
          debugPrint('Cannot show overlay — permission not granted');
          return;
        }
      }

      await FlutterOverlayWindow.showOverlay(
        height: 120,
        width: 120,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        enableDrag: true,
        positionGravity: PositionGravity.auto,
      );

      await updateState(initialState);
      debugPrint('Floating AI orb shown');
    } catch (error) {
      debugPrint('Failed to show overlay: $error');
    }
  }

  /// Hides the floating AI orb overlay.
  Future<void> hideOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      _currentState = OverlayOrbState.hidden;
      _stateController.add(_currentState);
      debugPrint('Overlay hidden');
    } catch (error) {
      debugPrint('OverlayService.hideOverlay failed: $error');
    }
  }

  /// Shows the overlay if it's currently hidden/inactive, or hides it if
  /// it's currently active.
  Future<void> toggleOverlay() async {
    try {
      final bool active = await isOverlayActive();
      if (active) {
        await hideOverlay();
      } else {
        await showOverlay();
      }
    } catch (error) {
      debugPrint('OverlayService.toggleOverlay failed: $error');
    }
  }

  /// Whether the overlay window is currently active on screen.
  Future<bool> isOverlayActive() async {
    try {
      return await FlutterOverlayWindow.isActive();
    } catch (error) {
      debugPrint('OverlayService.isOverlayActive failed: $error');
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // State Updates
  // ---------------------------------------------------------------------

  /// Updates the orb's state, notifying local listeners and sharing the
  /// new state with the native overlay window. Duplicate updates (the
  /// same state as the current one) are ignored.
  Future<void> updateState(OverlayOrbState state) async {
    if (state == _currentState) return;

    _currentState = state;
    _stateController.add(state);
    debugPrint('Overlay state changed: ${state.name}');

    try {
      await FlutterOverlayWindow.shareData(state.name);
    } catch (error) {
      debugPrint('OverlayService.updateState share failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Action Helpers
  // ---------------------------------------------------------------------

  /// Opens the AI chat sheet from the overlay: sets the orb to
  /// "thinking" and shares the `action:openChat` event, ready for future
  /// integration with the AI chat screen.
  Future<void> openChat() async {
    await updateState(OverlayOrbState.thinking);
    try {
      await FlutterOverlayWindow.shareData('action:openChat');
    } catch (error) {
      debugPrint('OverlayService.openChat failed: $error');
    }
  }

  /// Starts voice mode from the overlay: sets the orb to "listening" and
  /// shares the `action:startVoice` event.
  Future<void> startVoiceMode() async {
    await updateState(OverlayOrbState.listening);
    try {
      await FlutterOverlayWindow.shareData('action:startVoice');
    } catch (error) {
      debugPrint('OverlayService.startVoiceMode failed: $error');
    }
  }

  /// Opens a quick-note capture from the overlay by sharing the
  /// `action:quickNote` event.
  Future<void> showQuickNote() async {
    try {
      await FlutterOverlayWindow.shareData('action:quickNote');
    } catch (error) {
      debugPrint('OverlayService.showQuickNote failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------

  /// Placeholder helper that asks the native overlay to snap to the
  /// nearest screen edge, by sharing the `action:snapEdge` event.
  Future<void> moveToEdge() async {
    try {
      await FlutterOverlayWindow.shareData('action:snapEdge');
    } catch (error) {
      debugPrint('OverlayService.moveToEdge failed: $error');
    }
  }

  /// Schedules an automatic transition to [OverlayOrbState.sleeping]
  /// after [delay] of inactivity, but only if the orb is still
  /// [OverlayOrbState.idle] when the timer fires. Cancels any
  /// previously scheduled sleep timer first.
  Future<void> scheduleSleepState({
    Duration delay = const Duration(minutes: 5),
  }) async {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(delay, () {
      if (_currentState == OverlayOrbState.idle) {
        updateState(OverlayOrbState.sleeping);
      }
    });
  }

  /// A readable stream of events coming from the native overlay window
  /// (e.g. user interactions inside the overlay isolate).
  Stream<dynamic> overlayListener() {
    return FlutterOverlayWindow.overlayListener.map((dynamic event) {
      debugPrint('Overlay event received: $event');
      return event;
    });
  }

  /// Releases resources held by this service. Call when the service is
  /// no longer needed (rarely necessary for an app-lifetime singleton).
  Future<void> dispose() async {
    _sleepTimer?.cancel();
    await _stateController.close();
    debugPrint('OverlayService disposed');
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A preview dashboard exercising every [OverlayService] method on a
/// dark, futuristic background with cyan and purple accents.
class OverlayServiceDemo extends StatefulWidget {
  const OverlayServiceDemo({super.key});

  @override
  State<OverlayServiceDemo> createState() => _OverlayServiceDemoState();
}

class _OverlayServiceDemoState extends State<OverlayServiceDemo> {
  final OverlayService _service = OverlayService.instance;

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
                  'Floating AI Overlay Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nova AI can stay with the student even outside the app, '
                  'providing a true emotional assistant experience across '
                  'the entire phone.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusCard(),
                const SizedBox(height: 28),
                _buildSection(
                  title: 'Permission',
                  buttons: <Widget>[
                    _actionButton('Check Permission', () async {
                      final bool granted = await _service.checkPermission();
                      _notify('Permission granted: $granted');
                    }),
                    _actionButton('Request Permission', () async {
                      final bool granted = await _service.requestPermission();
                      _notify('Permission request result: $granted');
                    }),
                  ],
                ),
                _buildSection(
                  title: 'Overlay Control',
                  buttons: <Widget>[
                    _actionButton('Show Overlay', _service.showOverlay),
                    _actionButton('Hide Overlay', _service.hideOverlay),
                    _actionButton('Toggle Overlay', _service.toggleOverlay),
                  ],
                ),
                _buildSection(
                  title: 'Mood States',
                  buttons: <Widget>[
                    _actionButton('Idle', () => _service.updateState(OverlayOrbState.idle)),
                    _actionButton('Happy', () => _service.updateState(OverlayOrbState.happy)),
                    _actionButton('Listening', () => _service.updateState(OverlayOrbState.listening)),
                    _actionButton('Thinking', () => _service.updateState(OverlayOrbState.thinking)),
                    _actionButton('Speaking', () => _service.updateState(OverlayOrbState.speaking)),
                    _actionButton('Sleeping', () => _service.updateState(OverlayOrbState.sleeping)),
                  ],
                ),
                _buildSection(
                  title: 'Actions',
                  buttons: <Widget>[
                    _actionButton('Open Chat', _service.openChat),
                    _actionButton('Start Voice', _service.startVoiceMode),
                    _actionButton('Quick Note', _service.showQuickNote),
                  ],
                ),
                _buildSection(
                  title: 'Utility',
                  buttons: <Widget>[
                    _actionButton('Snap To Edge', _service.moveToEdge),
                    _actionButton(
                      'Auto Sleep In 10 Seconds',
                      () => _service.scheduleSleepState(
                        delay: const Duration(seconds: 10),
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

  Widget _buildStatusCard() {
    return StreamBuilder<OverlayOrbState>(
      stream: _service.stateStream,
      initialData: _service.currentState,
      builder: (BuildContext context, AsyncSnapshot<OverlayOrbState> snapshot) {
        final OverlayOrbState state = snapshot.data ?? OverlayOrbState.hidden;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Current Orb State',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _actionButton(String label, Future<void> Function() onPressed) {
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

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

