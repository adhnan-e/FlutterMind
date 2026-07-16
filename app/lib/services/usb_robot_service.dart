import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

/// Service that manages USB serial connections to the two Arduino boards
/// and routes commands based on the serial protocol.
///
/// Supports both real USB hardware and a simulation mode for testing
/// without physical Arduinos attached.
///
/// See [docs/PROTOCOL.md] for the full command reference.
class USBRobotService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Connection state
  // ---------------------------------------------------------------------------

  bool _isConnecting = false;
  bool _isConnected1 = false; // Arduino #1 (Upper/Right)
  bool _isConnected2 = false; // Arduino #2 (Lower/Left)
  bool _isSimulationMode = true;

  UsbPort? _port1;
  UsbPort? _port2;
  StreamSubscription<Uint8List>? _subscription1;
  StreamSubscription<Uint8List>? _subscription2;

  final List<String> _consoleLogs = [];

  // ---------------------------------------------------------------------------
  // Heartbeat (PING) state
  // ---------------------------------------------------------------------------

  Timer? _pingTimer;
  DateTime? _lastPongTime;
  bool _pingWarning = false;
  static const Duration _pingInterval = Duration(seconds: 2);
  static const Duration _pongTimeout = Duration(seconds: 3);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// Whether a USB scan is in progress.
  bool get isConnecting => _isConnecting;

  /// Whether Arduino #1 (upper body / right arm / head) is connected.
  bool get isConnected1 => _isConnected1;

  /// Whether Arduino #2 (lower body / left arm / torso) is connected.
  bool get isConnected2 => _isConnected2;

  /// Whether at least one Arduino is connected.
  bool get isConnected => _isConnected1 || _isConnected2;

  /// Whether running in simulation mode (no real hardware).
  bool get isSimulationMode => _isSimulationMode;

  /// Read-only view of the console log entries.
  List<String> get consoleLogs => _consoleLogs;

  /// Whether the heartbeat has timed out (no PONG received).
  bool get pingWarning => _pingWarning;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  USBRobotService() {
    // Automatically monitor USB attachments on Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      UsbSerial.usbEventStream?.listen((UsbEvent event) {
        logToConsole(
          'USB Event: ${event.event} - ${event.device?.deviceName}',
        );
        scanAndConnect();
      });
    }
    logToConsole('Initialized Robot Service (Simulation Mode Active)');
  }

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  /// Append a timestamped message to the console log.
  void logToConsole(String msg) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _consoleLogs.add('[$timestamp] $msg');
    if (_consoleLogs.length > 100) {
      _consoleLogs.removeAt(0);
    }
    notifyListeners();
  }

  /// Clear all console log entries.
  void clearLogs() {
    _consoleLogs.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Simulation mode
  // ---------------------------------------------------------------------------

  /// Toggle simulation mode. Disconnects real hardware when enabled.
  void setSimulationMode(bool value) {
    _isSimulationMode = value;
    if (value) {
      disconnect();
    }
    logToConsole(
      value ? 'Simulation Mode Enabled' : 'Simulation Mode Disabled',
    );
  }

  // ---------------------------------------------------------------------------
  // Connection management
  // ---------------------------------------------------------------------------

  /// Scan for and connect to USB-attached Arduino boards.
  Future<void> scanAndConnect() async {
    if (_isSimulationMode) {
      logToConsole(
        'Cannot scan in Simulation Mode. Disable it to scan real hardware.',
      );
      return;
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final List<UsbDevice> devices = await UsbSerial.listDevices();
      logToConsole('Found ${devices.length} USB device(s) connected');

      if (devices.isEmpty) {
        logToConsole('No USB devices detected.');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Try connecting to first two devices
      for (int i = 0; i < devices.length; i++) {
        final dev = devices[i];
        logToConsole(
          'Attempting connection to device: ${dev.productName} '
          '(Vid: ${dev.vid}, Pid: ${dev.pid})',
        );

        final UsbPort? port = await dev.create();
        if (port == null || !await port.open()) {
          logToConsole(
            'Failed to open port for device ${dev.deviceName}',
          );
          continue;
        }

        await port.setDTR(true);
        await port.setRTS(true);
        await port.setPortParameters(
          115200,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );

        // Send protocol handshake
        port.write(
          Uint8List.fromList(utf8.encode('HELLO:FLUTTERMIND:v1.0\n')),
        );

        // Wait briefly for handshake reply
        await Future.delayed(const Duration(milliseconds: 500));

        if (i == 0) {
          _port1 = port;
          _isConnected1 = true;
          _subscription1 =
              port.inputStream?.listen((data) => _handleData(1, data));
          logToConsole('Connected to Arduino #1 (Upper/Right Arm/Head)');
        } else if (i == 1) {
          _port2 = port;
          _isConnected2 = true;
          _subscription2 =
              port.inputStream?.listen((data) => _handleData(2, data));
          logToConsole('Connected to Arduino #2 (Lower/Left Arm/Torso)');
        }
      }

      // Start heartbeat when connected
      if (isConnected) {
        _startPingHeartbeat();
        // Request initial status
        sendCommand('STATUS');
      }
    } catch (e) {
      logToConsole('Error during USB connection: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Data handling
  // ---------------------------------------------------------------------------

  void _handleData(int boardIndex, Uint8List data) {
    final message = utf8.decode(data).trim();
    logToConsole('Recv [Arduino #$boardIndex]: $message');

    // Track PONG for heartbeat monitoring
    if (message.contains('PONG')) {
      _lastPongTime = DateTime.now();
      if (_pingWarning) {
        _pingWarning = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Heartbeat (PING/PONG)
  // ---------------------------------------------------------------------------

  /// Start sending PING every 2 seconds per protocol spec.
  void _startPingHeartbeat() {
    _stopPingHeartbeat();
    _lastPongTime = DateTime.now();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (!isConnected || _isSimulationMode) {
        _stopPingHeartbeat();
        return;
      }

      // Send PING to both boards
      final bytes = Uint8List.fromList(utf8.encode('PING\n'));
      _writeToPort(1, bytes);
      _writeToPort(2, bytes);

      // Check for PONG timeout
      if (_lastPongTime != null &&
          DateTime.now().difference(_lastPongTime!) > _pongTimeout) {
        if (!_pingWarning) {
          _pingWarning = true;
          logToConsole(
            'Warning: No heartbeat response for ${_pongTimeout.inSeconds}s',
          );
          // Send STOP on connection loss per protocol spec
          sendCommand('STOP');
          notifyListeners();
        }
      }
    });
  }

  /// Stop the heartbeat timer.
  void _stopPingHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pingWarning = false;
  }

  // ---------------------------------------------------------------------------
  // Command routing
  // ---------------------------------------------------------------------------

  /// Send a command string to the appropriate Arduino board(s).
  ///
  /// In simulation mode, generates mock responses in the console log
  /// instead of writing to real USB ports.
  void sendCommand(String cmd) {
    logToConsole('Send: $cmd');

    if (_isSimulationMode) {
      _simulateResponse(cmd);
      return;
    }

    final rawBytes = Uint8List.fromList(utf8.encode('$cmd\n'));

    // Route commands based on protocol logic
    if (cmd.startsWith('JOINT:')) {
      final parts = cmd.split(':');
      if (parts.length >= 3) {
        final jointName = parts[1];
        if (jointName.startsWith('L_') ||
            jointName == 'SPINE_BEND' ||
            jointName == 'WAIST_ROTATE') {
          _writeToPort(2, rawBytes);
        } else {
          _writeToPort(1, rawBytes);
        }
      }
    } else if (cmd.startsWith('POSE:')) {
      final anglesStr = cmd.substring(5).split(',');
      if (anglesStr.length == 22) {
        final pose1 = 'POSE:${anglesStr.sublist(0, 11).join(',')}\n';
        final pose2 = 'POSE:${anglesStr.sublist(11, 22).join(',')}\n';
        _writeToPort(1, Uint8List.fromList(utf8.encode(pose1)));
        _writeToPort(2, Uint8List.fromList(utf8.encode(pose2)));
      } else {
        logToConsole('Error: POSE command must contain exactly 22 angles');
      }
    } else {
      // Generic commands (GESTURE, STOP, PING, STATUS, SPEED) go to both
      _writeToPort(1, rawBytes);
      _writeToPort(2, rawBytes);
    }
  }

  /// Simulate Arduino responses for testing without hardware.
  void _simulateResponse(String cmd) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (cmd.startsWith('JOINT:')) {
        logToConsole('Recv (Simulated): ACK:$cmd');
      } else if (cmd.startsWith('GESTURE:')) {
        final gesture = cmd.split(':')[1];
        logToConsole('Recv (Simulated): ACK:GESTURE:$gesture');
        Future.delayed(const Duration(seconds: 1), () {
          logToConsole('Recv (Simulated): EVENT:GESTURE_DONE:$gesture');
        });
      } else if (cmd.startsWith('POSE:')) {
        logToConsole('Recv (Simulated): ACK:POSE');
      } else if (cmd == 'PING') {
        logToConsole('Recv (Simulated): PONG');
      } else if (cmd == 'STATUS') {
        logToConsole(
          'Recv (Simulated): STATUS:OK:BATT:4.8:TEMP:27:SERVOS:22',
        );
      } else if (cmd == 'STOP') {
        logToConsole('Recv (Simulated): ACK:STOP');
      } else if (cmd.startsWith('SPEED:')) {
        logToConsole('Recv (Simulated): ACK:$cmd');
      }
    });
  }

  void _writeToPort(int boardIndex, Uint8List bytes) {
    if (boardIndex == 1 && _isConnected1 && _port1 != null) {
      _port1!.write(bytes);
    } else if (boardIndex == 2 && _isConnected2 && _port2 != null) {
      _port2!.write(bytes);
    } else {
      logToConsole(
        'Warning: Board #$boardIndex is not connected. Message dropped.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Disconnect all USB ports and stop the heartbeat.
  void disconnect() {
    _stopPingHeartbeat();
    _subscription1?.cancel();
    _subscription2?.cancel();
    _port1?.close();
    _port2?.close();
    _port1 = null;
    _port2 = null;
    _isConnected1 = false;
    _isConnected2 = false;
    logToConsole('Disconnected USB ports');
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
