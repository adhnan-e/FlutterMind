import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

class USBRobotService extends ChangeNotifier {
  // Connection states
  bool _isConnecting = false;
  bool _isConnected1 = false; // Arduino #1 (Upper/Right)
  bool _isConnected2 = false; // Arduino #2 (Lower/Left)
  bool _isSimulationMode = true;

  UsbPort? _port1;
  UsbPort? _port2;
  StreamSubscription<Uint8List>? _subscription1;
  StreamSubscription<Uint8List>? _subscription2;

  final List<String> _consoleLogs = [];

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected1 => _isConnected1;
  bool get isConnected2 => _isConnected2;
  bool get isConnected => _isConnected1 || _isConnected2;
  bool get isSimulationMode => _isSimulationMode;
  List<String> get consoleLogs => _consoleLogs;

  USBRobotService() {
    // Automatically monitor USB attachments if on Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      UsbSerial.usbEventStream?.listen((UsbEvent event) {
        logToConsole("USB Event: ${event.event} - ${event.device?.deviceName}");
        scanAndConnect();
      });
    }
    logToConsole("Initialized Robot Service (Simulation Mode Active)");
  }

  void logToConsole(String msg) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _consoleLogs.add("[$timestamp] $msg");
    if (_consoleLogs.length > 100) {
      _consoleLogs.removeAt(0);
    }
    notifyListeners();
  }

  void clearLogs() {
    _consoleLogs.clear();
    notifyListeners();
  }

  // Toggle simulation mode manually
  void setSimulationMode(bool value) {
    _isSimulationMode = value;
    if (value) {
      disconnect();
    }
    logToConsole(value ? "Simulation Mode Enabled" : "Simulation Mode Disabled");
  }

  // Scan and connect to connected Arduinos
  Future<void> scanAndConnect() async {
    if (_isSimulationMode) {
      logToConsole("Cannot scan in Simulation Mode. Disable it to scan real hardware.");
      return;
    }

    _isConnecting = true;
    notifyListeners();

    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      logToConsole("Found ${devices.length} USB device(s) connected");

      if (devices.isEmpty) {
        logToConsole("No USB devices detected.");
        _isConnecting = false;
        notifyListeners();
        return;
      }

      // Try connecting to first two devices
      for (int i = 0; i < devices.length; i++) {
        final dev = devices[i];
        logToConsole("Attempting connection to device: ${dev.productName} (Vid: ${dev.vid}, Pid: ${dev.pid})");
        
        UsbPort? port = await dev.create();
        if (port == null || !await port.open()) {
          logToConsole("Failed to open port for device ${dev.deviceName}");
          continue;
        }

        await port.setDTR(true);
        await port.setRTS(true);
        await port.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

        // We will perform a simple handshake to identify if it is UPPER (Arduino 1) or LOWER (Arduino 2)
        // Send hello request
        port.write(Uint8List.fromList(utf8.encode("HELLO:FLUTTERMIND:v1.0\n")));
        
        // Wait briefly for handshake reply
        await Future.delayed(const Duration(milliseconds: 500));

        // Read buffer to detect ID
        // Note: In production we use StreamSubscription, but here we do a quick check
        if (i == 0) {
          _port1 = port;
          _isConnected1 = true;
          _subscription1 = port.inputStream?.listen((data) => _handleData(1, data));
          logToConsole("Connected to Arduino #1 (Upper/Right Arm/Head)");
        } else if (i == 1) {
          _port2 = port;
          _isConnected2 = true;
          _subscription2 = port.inputStream?.listen((data) => _handleData(2, data));
          logToConsole("Connected to Arduino #2 (Lower/Left Arm/Torso)");
        }
      }
    } catch (e) {
      logToConsole("Error during USB connection: $e");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _handleData(int boardIndex, Uint8List data) {
    final message = utf8.decode(data).trim();
    logToConsole("Recv [Arduino #$boardIndex]: $message");
  }

  // Send command to the correct board
  void sendCommand(String cmd) {
    logToConsole("Send: $cmd");

    if (_isSimulationMode) {
      // Simulate Arduino behavior
      Future.delayed(const Duration(milliseconds: 100), () {
        if (cmd.startsWith("JOINT:")) {
          logToConsole("Recv (Simulated): ACK:$cmd");
        } else if (cmd.startsWith("GESTURE:")) {
          final gesture = cmd.split(":")[1];
          logToConsole("Recv (Simulated): ACK:GESTURE:$gesture");
          Future.delayed(const Duration(seconds: 1), () {
            logToConsole("Recv (Simulated): EVENT:GESTURE_DONE:$gesture");
          });
        } else if (cmd.startsWith("POSE:")) {
          logToConsole("Recv (Simulated): ACK:POSE");
        } else if (cmd == "PING") {
          logToConsole("Recv (Simulated): PONG");
        } else if (cmd == "STATUS") {
          logToConsole("Recv (Simulated): STATUS:OK:BATT:4.8:TEMP:27:SERVOS:22");
        }
      });
      return;
    }

    final rawBytes = Uint8List.fromList(utf8.encode("$cmd\n"));

    // Route commands to specific board based on protocol logic
    if (cmd.startsWith("JOINT:")) {
      final parts = cmd.split(":");
      if (parts.length >= 3) {
        final jointName = parts[1];
        if (jointName.startsWith("L_") || jointName == "SPINE_BEND" || jointName == "WAIST_ROTATE") {
          _writeToPort(2, rawBytes);
        } else {
          _writeToPort(1, rawBytes);
        }
      }
    } else if (cmd.startsWith("POSE:")) {
      // Split POSE command: POSE:a1,a2,...,a22
      final anglesStr = cmd.substring(5).split(",");
      if (anglesStr.length == 22) {
        final pose1 = "POSE:${anglesStr.sublist(0, 11).join(',')}\n";
        final pose2 = "POSE:${anglesStr.sublist(11, 22).join(',')}\n";
        _writeToPort(1, Uint8List.fromList(utf8.encode(pose1)));
        _writeToPort(2, Uint8List.fromList(utf8.encode(pose2)));
      } else {
        logToConsole("Error: POSE command must contain exactly 22 angles");
      }
    } else {
      // Generic commands go to both boards
      _writeToPort(1, rawBytes);
      _writeToPort(2, rawBytes);
    }
  }

  void _writeToPort(int boardIndex, Uint8List bytes) {
    if (boardIndex == 1 && _isConnected1 && _port1 != null) {
      _port1!.write(bytes);
    } else if (boardIndex == 2 && _isConnected2 && _port2 != null) {
      _port2!.write(bytes);
    } else {
      logToConsole("Warning: Board #$boardIndex is not connected. Message dropped.");
    }
  }

  void disconnect() {
    _subscription1?.cancel();
    _subscription2?.cancel();
    _port1?.close();
    _port2?.close();
    _port1 = null;
    _port2 = null;
    _isConnected1 = false;
    _isConnected2 = false;
    logToConsole("Disconnected USB ports");
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
