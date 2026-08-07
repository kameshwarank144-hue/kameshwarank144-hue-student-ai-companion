// lib/core/network/connectivity_service.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------

/// The overall network connectivity state.
enum ConnectionStatus {
  connected,
  disconnected,
  connecting,
}

/// The kind of active network connection.
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  none,
  unknown,
}

// ---------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------

/// Central internet and network status manager for Student AI
/// Companion.
///
/// Detects connectivity, monitors Wi-Fi/mobile data/ethernet/VPN/
/// Bluetooth, exposes reactive streams for the UI, and provides
/// auto-sync hooks and a lightweight offline operation queue —
/// supporting offline-first behavior throughout the app.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  ConnectionStatus _status = ConnectionStatus.connecting;
  ConnectionType _type = ConnectionType.unknown;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isInitialized = false;
  DateTime? _lastConnectedAt;

  bool get isInitialized => _isInitialized;
  ConnectionStatus get status => _status;
  ConnectionType get connectionType => _type;
  bool get isConnected => _status == ConnectionStatus.connected;
  DateTime? get lastConnectedAt => _lastConnectedAt;

  /// Called when connectivity transitions from disconnected to
  /// connected — a good hook for triggering a sync service later.
  VoidCallback? onConnectionRestored;

  /// Called when connectivity transitions from connected to
  /// disconnected.
  VoidCallback? onConnectionLost;

  // ---------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<ConnectionType> _typeController =
      StreamController<ConnectionType>.broadcast();
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<ConnectionType> get typeStream => _typeController.stream;
  Stream<bool> get onlineStream => _onlineController.stream;

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Initializes the service: checks the current connectivity state and
  /// starts listening for changes. Safe to call more than once —
  /// subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Connectivity service already initialized');
      return;
    }

    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();

      await _updateConnection(results);

      _subscription = _connectivity.onConnectivityChanged.listen(
        _updateConnection,
        onError: (Object error) {
          debugPrint('Connectivity stream error: $error');
        },
      );

      _isInitialized = true;
      debugPrint('Connectivity service initialized');
    } catch (error) {
      debugPrint('Connectivity service initialization failed: $error');
      _status = ConnectionStatus.disconnected;
      _type = ConnectionType.none;
    }
  }

  /// Performs a one-off connectivity check. Returns false on any
  /// failure rather than throwing.
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      await _updateConnection(results);
      return isConnected;
    } catch (error) {
      debugPrint('checkConnection failed: $error');
      return false;
    }
  }

  /// Returns the current primary connection type. Returns
  /// [ConnectionType.none] on any failure.
  Future<ConnectionType> getCurrentConnectionType() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      return _primaryType(results);
    } catch (error) {
      debugPrint('getCurrentConnectionType failed: $error');
      return ConnectionType.none;
    }
  }

  /// Forces a fresh connectivity check and re-emits current state.
  Future<void> refresh() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      await _updateConnection(results);
      debugPrint('Connectivity status refreshed');
    } catch (error) {
      debugPrint('refresh failed: $error');
    }
  }

  /// Cancels the connectivity subscription and closes all streams.
  Future<void> dispose() async {
    try {
      await _subscription?.cancel();
      await _statusController.close();
      await _typeController.close();
      await _onlineController.close();
      _isInitialized = false;
      debugPrint('Connectivity service disposed');
    } catch (error) {
      debugPrint('Connectivity service dispose failed: $error');
    }
  }

  // ---------------------------------------------------------------------
  // Connectivity Updates
  // ---------------------------------------------------------------------

  Future<void> _updateConnection(List<ConnectivityResult> results) async {
    final ConnectionStatus previousStatus = _status;
    final ConnectionType primaryType = _primaryType(results);

    if (primaryType == ConnectionType.none) {
      _status = ConnectionStatus.disconnected;
      _type = ConnectionType.none;
    } else {
      _status = ConnectionStatus.connected;
      _type = primaryType;
      _lastConnectedAt = DateTime.now();
    }

    _statusController.add(_status);
    _typeController.add(_type);
    _onlineController.add(isConnected);

    if (previousStatus != ConnectionStatus.connected &&
        _status == ConnectionStatus.connected) {
      debugPrint('Connection restored via ${_type.name}');
      onConnectionRestored?.call();
    } else if (previousStatus == ConnectionStatus.connected &&
        _status == ConnectionStatus.disconnected) {
      debugPrint('Internet connection lost');
      onConnectionLost?.call();
    }
  }

  /// Priority order used when multiple simultaneous connections are
  /// reported (e.g. Wi-Fi + mobile data both active).
  static const List<ConnectivityResult> _typePriority = <ConnectivityResult>[
    ConnectivityResult.wifi,
    ConnectivityResult.ethernet,
    ConnectivityResult.mobile,
    ConnectivityResult.vpn,
    ConnectivityResult.bluetooth,
  ];

  ConnectionType _primaryType(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((ConnectivityResult r) => r == ConnectivityResult.none)) {
      return ConnectionType.none;
    }

    for (final ConnectivityResult candidate in _typePriority) {
      if (results.contains(candidate)) {
        return _mapConnectionType(candidate);
      }
    }

    return _mapConnectionType(results.first);
  }

  ConnectionType _mapConnectionType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.none:
        return ConnectionType.none;
      default:
        return ConnectionType.unknown;
    }
  }

  // ---------------------------------------------------------------------
  // Friendly Message Helpers
  // ---------------------------------------------------------------------

  String get statusText {
    switch (_status) {
      case ConnectionStatus.connected:
        switch (_type) {
          case ConnectionType.wifi:
            return 'Connected Wi-Fi';
          case ConnectionType.mobile:
            return 'Connected Mobile';
          case ConnectionType.ethernet:
            return 'Connected Ethernet';
          case ConnectionType.vpn:
            return 'Connected VPN';
          case ConnectionType.bluetooth:
            return 'Connected Bluetooth';
          default:
            return 'Connected';
        }
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting';
    }
  }

  String get connectionDescription {
    switch (_status) {
      case ConnectionStatus.connected:
        switch (_type) {
          case ConnectionType.wifi:
            return 'Connected via Wi-Fi';
          case ConnectionType.mobile:
            return 'Connected via mobile data';
          case ConnectionType.ethernet:
            return 'Connected via ethernet';
          case ConnectionType.vpn:
            return 'Connected via VPN';
          case ConnectionType.bluetooth:
            return 'Connected via Bluetooth';
          default:
            return 'Connected to the internet';
        }
      case ConnectionStatus.disconnected:
        return 'No internet connection';
      case ConnectionStatus.connecting:
        return 'Checking connection...';
    }
  }

  // ---------------------------------------------------------------------
  // Queue Helpers
  // ---------------------------------------------------------------------

  final List<String> _pendingOperations = <String>[];

  /// Queues [operation] for later retry once connectivity returns —
  /// a placeholder for future AI request / sync retry logic.
  void addPendingOperation(String operation) {
    _pendingOperations.add(operation);
    debugPrint('Pending operation queued: $operation');
  }

  /// All currently queued pending operations.
  List<String> get pendingOperations =>
      List<String>.unmodifiable(_pendingOperations);

  /// Clears every queued pending operation.
  void clearPendingOperations() {
    _pendingOperations.clear();
    debugPrint('Pending operations cleared');
  }
}

// ---------------------------------------------------------------------
// Banner Widget
// ---------------------------------------------------------------------

/// A warning banner shown when the device is offline.
class NoInternetBanner extends StatelessWidget {
  const NoInternetBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF6B5B), Color(0xFFFFA85B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFFF6B5B).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "You're offline. Nova AI will continue working with local "
              'data and sync automatically when the internet returns.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Status Card Widget
// ---------------------------------------------------------------------

/// A glassmorphism card summarizing the current connectivity state.
class ConnectivityStatusCard extends StatelessWidget {
  const ConnectivityStatusCard({
    super.key,
    required this.status,
    required this.type,
    required this.lastConnectedAt,
  });

  final ConnectionStatus status;
  final ConnectionType type;
  final DateTime? lastConnectedAt;

  Color get _glowColor {
    switch (status) {
      case ConnectionStatus.connected:
        return const Color(0xFF34D399);
      case ConnectionStatus.connecting:
        return const Color(0xFFFBBF24);
      case ConnectionStatus.disconnected:
        return const Color(0xFFFF6B5B);
    }
  }

  IconData get _icon {
    switch (type) {
      case ConnectionType.wifi:
        return Icons.wifi_rounded;
      case ConnectionType.mobile:
        return Icons.signal_cellular_alt_rounded;
      case ConnectionType.ethernet:
        return Icons.lan_rounded;
      case ConnectionType.vpn:
        return Icons.vpn_lock_rounded;
      case ConnectionType.bluetooth:
        return Icons.bluetooth_rounded;
      case ConnectionType.none:
        return Icons.wifi_off_rounded;
      case ConnectionType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get _statusText {
    switch (status) {
      case ConnectionStatus.connected:
        switch (type) {
          case ConnectionType.wifi:
            return 'Connected Wi-Fi';
          case ConnectionType.mobile:
            return 'Connected Mobile';
          case ConnectionType.ethernet:
            return 'Connected Ethernet';
          case ConnectionType.vpn:
            return 'Connected VPN';
          case ConnectionType.bluetooth:
            return 'Connected Bluetooth';
          default:
            return 'Connected';
        }
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting';
    }
  }

  String get _description {
    switch (status) {
      case ConnectionStatus.connected:
        switch (type) {
          case ConnectionType.wifi:
            return 'Connected via Wi-Fi';
          case ConnectionType.mobile:
            return 'Connected via mobile data';
          case ConnectionType.ethernet:
            return 'Connected via ethernet';
          case ConnectionType.vpn:
            return 'Connected via VPN';
          case ConnectionType.bluetooth:
            return 'Connected via Bluetooth';
          default:
            return 'Connected to the internet';
        }
      case ConnectionStatus.disconnected:
        return 'No internet connection';
      case ConnectionStatus.connecting:
        return 'Checking connection...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _glowColor.withOpacity(0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _glowColor.withOpacity(0.2),
            blurRadius: 22,
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _glowColor.withOpacity(0.15),
              border: Border.all(color: _glowColor.withOpacity(0.4)),
            ),
            child: Icon(_icon, color: _glowColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (lastConnectedAt != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Last connected: ${_formatTime(lastConnectedAt!)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final int hour24 = time.hour;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = hour24 >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}

// ---------------------------------------------------------------------
// Demo Screen
// ---------------------------------------------------------------------

/// A preview dashboard exercising every [ConnectivityService] method on
/// a dark, futuristic background.
class ConnectivityServiceDemo extends StatefulWidget {
  const ConnectivityServiceDemo({super.key});

  @override
  State<ConnectivityServiceDemo> createState() =>
      _ConnectivityServiceDemoState();
}

class _ConnectivityServiceDemoState extends State<ConnectivityServiceDemo> {
  final ConnectivityService _service = ConnectivityService.instance;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  int _operationCounter = 0;

  @override
  void initState() {
    super.initState();
    _statusSubscription = _service.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
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
                  'Connectivity & Offline Sync Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nova AI stays reliable even without internet by using '
                  'offline storage, smart connectivity monitoring, and '
                  'automatic synchronization when the connection returns.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (_service.status == ConnectionStatus.disconnected) ...<Widget>[
                  NoInternetBanner(onRetry: _service.refresh),
                  const SizedBox(height: 16),
                ],
                ConnectivityStatusCard(
                  status: _service.status,
                  type: _service.connectionType,
                  lastConnectedAt: _service.lastConnectedAt,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _button('Initialize Service', () async {
                      await _service.initialize();
                      setState(() {});
                    }),
                    _button('Check Connection', () async {
                      await _service.checkConnection();
                      setState(() {});
                    }),
                    _button('Refresh Status', () async {
                      await _service.refresh();
                      setState(() {});
                    }),
                    _button('Simulate Queue Operation', () async {
                      _operationCounter++;
                      _service.addPendingOperation(
                        'sync_operation_$_operationCounter',
                      );
                      setState(() {});
                    }),
                    _button('Clear Queue', () async {
                      _service.clearPendingOperations();
                      setState(() {});
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                _buildQueuePanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueuePanel() {
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
          Text(
            'Pending Operations (${_service.pendingOperations.length})',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_service.pendingOperations.isEmpty)
            Text(
              'No pending operations.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            )
          else
            ..._service.pendingOperations.map(
              (String op) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• $op',
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

