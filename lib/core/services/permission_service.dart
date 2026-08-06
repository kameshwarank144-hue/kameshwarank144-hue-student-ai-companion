// lib/core/services/permission_service.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------

/// Every permission Student AI Companion may need, mapped internally to
/// the underlying platform [Permission].
enum AppPermission {
  microphone,
  notifications,
  overlay,
  storage,
  photos,
  camera,
  usageStats,
  batteryOptimization,
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Central permission manager for Student AI Companion.
///
/// Handles microphone, notifications, overlay ("draw over other apps"),
/// storage/media, camera, photo access, screen-time usage stats
/// (placeholder), and battery optimization exemption, with
/// platform-aware behavior, friendly explanations, and graceful failure
/// handling so a denied or unsupported permission never crashes the app.
class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  // ---------------------------------------------------------------------
  // Permission Requests
  // ---------------------------------------------------------------------

  /// Requests microphone access, used for voice chat and voice
  /// reminders.
  Future<bool> requestMicrophone() {
    return _requestPermission(Permission.microphone, debugName: 'Microphone');
  }

  /// Requests notification access. On Android versions below 13 this
  /// permission is not a runtime permission, and permission_handler
  /// automatically reports it as granted; the same call site correctly
  /// handles both Android 13+ and older Android without extra branching.
  Future<bool> requestNotifications() {
    return _requestPermission(Permission.notification, debugName: 'Notifications');
  }

  /// Requests the "draw over other apps" permission used by the
  /// floating AI orb. Always returns false on iOS, which does not
  /// support system-level overlays.
  Future<bool> requestOverlay() async {
    if (Platform.isIOS) {
      debugPrint('Overlay permission is not supported on iOS');
      return false;
    }
    return _requestPermission(Permission.systemAlertWindow, debugName: 'Overlay');
  }

  /// Requests storage/media access. Prefers the granular photo-library
  /// permission (Android 13+ and iOS) and falls back to the legacy
  /// storage permission on Android 12 and below.
  Future<bool> requestStorage() async {
    if (Platform.isIOS) {
      return _requestPermission(Permission.photos, debugName: 'Photos (iOS storage)');
    }

    final bool granularGranted = await _requestPermission(
      Permission.photos,
      debugName: 'Photos (Android 13+)',
    );
    if (granularGranted) return true;

    return _requestPermission(
      Permission.storage,
      debugName: 'Storage (Android 12 and below)',
    );
  }

  /// Requests photo library access, used for uploading notes and study
  /// material images.
  Future<bool> requestPhotos() {
    return _requestPermission(Permission.photos, debugName: 'Photos');
  }

  /// Requests camera access, used for scanning notes and documents.
  Future<bool> requestCamera() {
    return _requestPermission(Permission.camera, debugName: 'Camera');
  }

  /// Placeholder for Android usage-access permission, which powers the
  /// Screen Time feature. Android's usage access setting cannot be
  /// requested through a standard runtime permission dialog — it
  /// requires sending the user to a dedicated system settings screen via
  /// native platform integration, which is not wired up yet.
  Future<bool> requestUsageStats() async {
    debugPrint(
      'Usage stats access requires native settings integration '
      '(Android Settings.ACTION_USAGE_ACCESS_SETTINGS) — not yet implemented.',
    );
    return false;
  }

  /// Requests exemption from battery optimization so background
  /// reminders and the AI companion stay reliable. No-op (returns true)
  /// on iOS, which has no equivalent setting.
  Future<bool> requestBatteryOptimization() async {
    if (Platform.isIOS) return true;
    return _requestPermission(
      Permission.ignoreBatteryOptimizations,
      debugName: 'Battery Optimization',
    );
  }

  /// Requests a single permission by [AppPermission] type.
  Future<bool> request(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return requestMicrophone();
      case AppPermission.notifications:
        return requestNotifications();
      case AppPermission.overlay:
        return requestOverlay();
      case AppPermission.storage:
        return requestStorage();
      case AppPermission.photos:
        return requestPhotos();
      case AppPermission.camera:
        return requestCamera();
      case AppPermission.usageStats:
        return requestUsageStats();
      case AppPermission.batteryOptimization:
        return requestBatteryOptimization();
    }
  }

  /// Requests the core permissions Nova AI needs to function day-to-day:
  /// notifications, microphone, and the floating overlay.
  Future<Map<AppPermission, bool>> requestEssentialPermissions() async {
    final Map<AppPermission, bool> results = <AppPermission, bool>{
      AppPermission.notifications: await requestNotifications(),
      AppPermission.microphone: await requestMicrophone(),
      AppPermission.overlay: await requestOverlay(),
    };

    debugPrint('Essential permissions result: $results');
    return results;
  }

  // ---------------------------------------------------------------------
  // Status Helpers
  // ---------------------------------------------------------------------

  /// Whether [permission] is currently granted.
  Future<bool> isGranted(AppPermission permission) async {
    try {
      if (permission == AppPermission.usageStats) {
        // No standard runtime check exists for usage access; treated as
        // never granted until native settings integration is added.
        return false;
      }

      final Permission mapped = _mapPermission(permission);
      final PermissionStatus status = await mapped.status;
      return status.isGranted;
    } catch (error) {
      debugPrint('PermissionService.isGranted failed for $permission: $error');
      return false;
    }
  }

  /// Whether [permission] has been permanently denied (and therefore
  /// must be granted from system settings rather than a request dialog).
  Future<bool> isPermanentlyDenied(AppPermission permission) async {
    try {
      if (permission == AppPermission.usageStats) return false;

      final Permission mapped = _mapPermission(permission);
      final PermissionStatus status = await mapped.status;
      return status.isPermanentlyDenied;
    } catch (error) {
      debugPrint(
        'PermissionService.isPermanentlyDenied failed for $permission: $error',
      );
      return false;
    }
  }

  /// Opens the app's system settings page, for permissions that were
  /// permanently denied.
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (error) {
      debugPrint('PermissionService.openSettings failed: $error');
    }
  }

  /// Returns the raw [PermissionStatus] for every [AppPermission].
  Future<Map<AppPermission, PermissionStatus>> getAllStatuses() async {
    final Map<AppPermission, PermissionStatus> statuses =
        <AppPermission, PermissionStatus>{};

    for (final AppPermission permission in AppPermission.values) {
      try {
        if (permission == AppPermission.usageStats) {
          statuses[permission] = PermissionStatus.denied;
          continue;
        }
        statuses[permission] = await _mapPermission(permission).status;
      } catch (error) {
        debugPrint('PermissionService.getAllStatuses failed for $permission: $error');
        statuses[permission] = PermissionStatus.denied;
      }
    }

    return statuses;
  }

  Permission _mapPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return Permission.microphone;
      case AppPermission.notifications:
        return Permission.notification;
      case AppPermission.overlay:
        return Permission.systemAlertWindow;
      case AppPermission.storage:
        return Permission.storage;
      case AppPermission.photos:
        return Permission.photos;
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.batteryOptimization:
        return Permission.ignoreBatteryOptimizations;
      case AppPermission.usageStats:
        // No dedicated Permission entry exists; callers should special-case
        // this before reaching here (see isGranted/getAllStatuses above).
        return Permission.unknown;
    }
  }

  // ---------------------------------------------------------------------
  // Internal helper
  // ---------------------------------------------------------------------

  /// Checks [permission]'s current status and requests it if not already
  /// granted, logging every step. Never throws — returns false on any
  /// failure.
  Future<bool> _requestPermission(
    Permission permission, {
    required String debugName,
  }) async {
    try {
      final PermissionStatus current = await permission.status;

      if (current.isGranted) {
        debugPrint('$debugName permission already granted');
        return true;
      }

      final PermissionStatus result = await permission.request();

      if (result.isGranted) {
        debugPrint('$debugName permission granted');
        return true;
      }

      if (result.isPermanentlyDenied) {
        debugPrint(
          '$debugName permission permanently denied — open settings to enable it',
        );
      } else {
        debugPrint('$debugName permission denied');
      }

      return false;
    } catch (error) {
      debugPrint('PermissionService request failed for $debugName: $error');
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Friendly Metadata
  // ---------------------------------------------------------------------

  /// A short, human-readable title for [permission].
  String getTitle(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return 'Microphone Access';
      case AppPermission.notifications:
        return 'Notifications';
      case AppPermission.overlay:
        return 'Floating Assistant';
      case AppPermission.storage:
        return 'Storage Access';
      case AppPermission.photos:
        return 'Photo Access';
      case AppPermission.camera:
        return 'Camera Access';
      case AppPermission.usageStats:
        return 'Screen Time Access';
      case AppPermission.batteryOptimization:
        return 'Background Reliability';
    }
  }

  /// A warm, explanatory description for [permission], suitable for
  /// display before a system permission dialog.
  String getDescription(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return 'Nova AI needs microphone access so you can talk naturally '
            'with your assistant, create voice reminders, and use '
            'hands-free study support.';
      case AppPermission.notifications:
        return "Allow notifications so Nova AI can remind you about "
            "classes, assignments, exams, and gentle wellness check-ins "
            "throughout the day.";
      case AppPermission.overlay:
        return 'Allow Nova AI to stay above other apps as a floating '
            'assistant bubble that can open chat, listen to voice '
            'commands, and provide reminders anywhere on your phone.';
      case AppPermission.storage:
        return 'Nova AI needs storage access to save and open PDFs, notes, '
            'and study material you upload.';
      case AppPermission.photos:
        return 'Allow photo access so you can upload class notes, '
            'whiteboard photos, and documents for Nova AI to summarize.';
      case AppPermission.camera:
        return 'Allow camera access to quickly scan notes, textbook pages, '
            'and assignments directly into the app.';
      case AppPermission.usageStats:
        return "Screen time access helps Nova AI understand your daily "
            "phone habits and gently encourage healthier focus.";
      case AppPermission.batteryOptimization:
        return 'Excluding Nova AI from battery optimization helps make '
            'sure reminders and background check-ins arrive on time.';
    }
  }

  /// An icon representative of [permission], for use in UI cards.
  IconData getIcon(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return Icons.mic_rounded;
      case AppPermission.notifications:
        return Icons.notifications_active_rounded;
      case AppPermission.overlay:
        return Icons.blur_circular_rounded;
      case AppPermission.storage:
        return Icons.folder_rounded;
      case AppPermission.photos:
        return Icons.photo_library_rounded;
      case AppPermission.camera:
        return Icons.camera_alt_rounded;
      case AppPermission.usageStats:
        return Icons.phone_android_rounded;
      case AppPermission.batteryOptimization:
        return Icons.battery_charging_full_rounded;
    }
  }
}

// ---------------------------------------------------------------------
// Permission Card Widget
// ---------------------------------------------------------------------

/// A premium, glassmorphism card describing a single permission, its
/// current status, and a request action.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.permission,
    required this.granted,
    required this.onRequest,
  });

  final AppPermission permission;
  final bool granted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final PermissionService service = PermissionService.instance;
    final Color accent = granted ? const Color(0xFF34D399) : const Color(0xFF7C4DFF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: granted
              ? const Color(0xFF34D399).withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Icon(
              service.getIcon(permission),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        service.getTitle(permission),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  service.getDescription(permission),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                if (!granted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Grant Access',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final Color color = granted ? const Color(0xFF34D399) : const Color(0xFFFBBF24);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        granted ? 'Granted' : 'Not Granted',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

/// A preview dashboard showing every permission's status with request
/// controls, on a dark futuristic background.
class PermissionServiceDemo extends StatefulWidget {
  const PermissionServiceDemo({super.key});

  @override
  State<PermissionServiceDemo> createState() => _PermissionServiceDemoState();
}

class _PermissionServiceDemoState extends State<PermissionServiceDemo> {
  final PermissionService _service = PermissionService.instance;

  static const List<AppPermission> _cardPermissions = <AppPermission>[
    AppPermission.notifications,
    AppPermission.microphone,
    AppPermission.overlay,
    AppPermission.storage,
    AppPermission.photos,
    AppPermission.camera,
  ];

  Map<AppPermission, bool> _grantedMap = <AppPermission, bool>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);

    final Map<AppPermission, bool> results = <AppPermission, bool>{};
    for (final AppPermission permission in AppPermission.values) {
      results[permission] = await _service.isGranted(permission);
    }

    if (!mounted) return;
    setState(() {
      _grantedMap = results;
      _loading = false;
    });
  }

  Future<void> _requestEssential() async {
    await _service.requestEssentialPermissions();
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final int grantedCount =
        _grantedMap.values.where((bool granted) => granted).length;
    final int totalCount = AppPermission.values.length;
    final int pendingCount = totalCount - grantedCount;

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
                  'Permission Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nova AI needs a few permissions to provide voice '
                  'conversations, floating assistant support, reminders, '
                  'study tools, and a seamless student productivity '
                  'experience.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildHeaderCard(grantedCount, pendingCount, totalCount),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _requestEssential,
                      child: const Text('Request Essential Permissions'),
                    ),
                    ElevatedButton(
                      onPressed: _refreshStatus,
                      child: const Text('Refresh Status'),
                    ),
                    ElevatedButton(
                      onPressed: _service.openSettings,
                      child: const Text('Open App Settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  )
                else
                  Column(
                    children: _cardPermissions.map((AppPermission permission) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: PermissionCard(
                          permission: permission,
                          granted: _grantedMap[permission] ?? false,
                          onRequest: () async {
                            await _service.request(permission);
                            await _refreshStatus();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                _buildStatusPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int granted, int pending, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _headerStat('Total', total.toString(), Colors.white),
          _headerStat('Granted', granted.toString(), const Color(0xFF34D399)),
          _headerStat('Pending', pending.toString(), const Color(0xFFFBBF24)),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Live Status',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...AppPermission.values.map((AppPermission permission) {
            final bool granted = _grantedMap[permission] ?? false;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    granted ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14,
                    color: granted
                        ? const Color(0xFF34D399)
                        : Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _service.getTitle(permission),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

