import 'package:flutter/material.dart';
import 'services/usb_robot_service.dart';
import 'services/download_service.dart';
import 'models/robot_pose.dart';

void main() {
  runApp(const FlutterMindApp());
}

class FlutterMindApp extends StatelessWidget {
  const FlutterMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterMind 🤖',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7F5AF0),
          secondary: Color(0xFF2CB67D),
          surface: Color(0xFF16161A),
          background: Color(0xFF0F0E17),
          error: Color(0xFFFF8906),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16161A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF7F5AF0),
          inactiveTrackColor: const Color(0xFF2D2E32),
          thumbColor: const Color(0xFF2CB67D),
          overlayColor: const Color(0xFF2CB67D).withOpacity(0.12),
        ),
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late final USBRobotService _usbService;
  late final DownloadService _downloadService;
  final RobotPose _currentPose = RobotPose();

  // Chat/AI State
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _logScrollController = ScrollController();

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _usbService = USBRobotService();
    _downloadService = DownloadService();

    // Add listener to automatically scroll log to bottom
    _usbService.addListener(_scrollToBottomLog);
  }

  void _scrollToBottomLog() {
    if (_logScrollController.hasClients) {
      _logScrollController.animateTo(
        _logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomChat() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _usbService.removeListener(_scrollToBottomLog);
    _usbService.dispose();
    _downloadService.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // Handle mock brain thinking
  void _submitVoiceCommand(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({"sender": "user", "text": query});
    });
    _chatController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottomChat);

    // Simulate AI decision logic (mocking Gemma 4 E2B)
    setState(() {
      _chatMessages.add({
        "sender": "ai",
        "text": "🤖 Gemma is processing command...",
      });
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottomChat);

    Future.delayed(const Duration(seconds: 1), () {
      final processedQuery = query.toLowerCase();
      String reply = "";
      String? commandToSend;

      if (processedQuery.contains("wave") || processedQuery.contains("hello")) {
        reply = "Decision: WAVE GESTURE. Dispatched command GESTURE:WAVE.";
        commandToSend = "GESTURE:WAVE";
      } else if (processedQuery.contains("grip") ||
          processedQuery.contains("close hand") ||
          processedQuery.contains("fist")) {
        reply = "Decision: GRIP GESTURE. Dispatched command GESTURE:GRIP.";
        commandToSend = "GESTURE:GRIP";
      } else if (processedQuery.contains("open hand") ||
          processedQuery.contains("release")) {
        reply = "Decision: OPEN GESTURE. Dispatched command GESTURE:OPEN.";
        commandToSend = "GESTURE:OPEN";
      } else if (processedQuery.contains("point")) {
        reply = "Decision: POINT GESTURE. Dispatched command GESTURE:POINT.";
        commandToSend = "GESTURE:POINT";
      } else if (processedQuery.contains("nod") ||
          processedQuery.contains("yes")) {
        reply = "Decision: NOD GESTURE. Dispatched command GESTURE:NOD.";
        commandToSend = "GESTURE:NOD";
      } else if (processedQuery.contains("shake head") ||
          processedQuery.contains("no")) {
        reply = "Decision: SHAKE GESTURE. Dispatched command GESTURE:SHAKE.";
        commandToSend = "GESTURE:SHAKE";
      } else if (processedQuery.contains("thumbs up")) {
        reply =
            "Decision: THUMBSUP GESTURE. Dispatched command GESTURE:THUMBSUP.";
        commandToSend = "GESTURE:THUMBSUP";
      } else if (processedQuery.contains("rest") ||
          processedQuery.contains("reset")) {
        reply = "Decision: REST GESTURE. Dispatched command GESTURE:REST.";
        commandToSend = "GESTURE:REST";
      } else if (processedQuery.contains("look left")) {
        reply = "Decision: Turn head left. Dispatched JOINT:NECK_PAN:150.";
        commandToSend = "JOINT:NECK_PAN:150";
      } else if (processedQuery.contains("look right")) {
        reply = "Decision: Turn head right. Dispatched JOINT:NECK_PAN:30.";
        commandToSend = "JOINT:NECK_PAN:30";
      } else {
        reply =
            "Gemma Offline Brain: I heard \"$query\". I don't see any matching physical mapping for this command in my default database. You can try: 'wave hello', 'close hand', 'look left', or 'thumbs up'.";
      }

      setState(() {
        _chatMessages.removeLast(); // Remove thinking message
        _chatMessages.add({"sender": "ai", "text": reply});
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottomChat);

      if (commandToSend != null) {
        _usbService.sendCommand(commandToSend);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FlutterMind 🤖',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF16161A),
        actions: [
          ListenableBuilder(
            listenable: _usbService,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      _usbService.isSimulationMode
                          ? 'SIMULATION'
                          : 'USB DEVICE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _usbService.isSimulationMode
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: !_usbService.isSimulationMode,
                      activeColor: const Color(0xFF2CB67D),
                      onChanged: (val) {
                        _usbService.setSimulationMode(!val);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation rail for larger screens / desktop tests
          NavigationRail(
            backgroundColor: const Color(0xFF16161A),
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                selectedIcon: Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFF7F5AF0),
                ),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.tune_rounded),
                selectedIcon: Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF7F5AF0),
                ),
                label: Text('Manual'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.psychology_rounded),
                selectedIcon: Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF7F5AF0),
                ),
                label: Text('Gemma Brain'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Main content switcher
          Expanded(child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildManualControls();
      case 2:
        return _buildGemmaBrain();
      default:
        return _buildDashboard();
    }
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Downloader Banner
          ListenableBuilder(
            listenable: _downloadService,
            builder: (context, _) {
              if (!_downloadService.isModelDownloaded) {
                return _buildDownloadPromptCard();
              } else {
                return _buildModelStatusCard();
              }
            },
          ),
          const SizedBox(height: 16),

          // USB Connection Status
          _buildHardwareStatusCard(),
          const SizedBox(height: 16),

          // Quick Preset Gestures
          _buildQuickGesturesCard(),
          const SizedBox(height: 16),

          // Serial Log Window
          _buildConsoleLogCard(),
        ],
      ),
    );
  }

  Widget _buildDownloadPromptCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7F5AF0).withOpacity(0.15),
              const Color(0xFF16161A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFF7F5AF0).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF8906),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Model Missing: Gemma 4 E2B',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'On-device offline intelligence requires a model file.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_downloadService.isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadService.progress,
                backgroundColor: const Color(0xFF2D2E32),
                color: const Color(0xFF2CB67D),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Speed: ${_downloadService.downloadSpeed}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _downloadService.downloadedSize,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _downloadService.cancelDownload(),
                icon: const Icon(Icons.cancel_rounded),
                label: const Text('Cancel Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              if (_downloadService.error != null) ...[
                Text(
                  _downloadService.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'This will download gemma-4-E2B-it.litertlm (~2.5GB) directly from Hugging Face to local app storage. Please connect to a stable Wi-Fi network.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _downloadService.startDownload(),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Model (~2.5GB)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F5AF0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2CB67D),
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemma 4 E2B Offline Brain ready',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Stored at: ${_downloadService.localModelPath}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.grey,
              ),
              tooltip: 'Delete Model',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Model?'),
                    content: const Text(
                      'This will delete the 2.5GB model file from app storage. You will need to download it again to use offline AI features.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _downloadService.deleteModel();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareStatusCard() {
    return ListenableBuilder(
      listenable: _usbService,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hardware Connections',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_usbService.isSimulationMode)
                      ElevatedButton(
                        onPressed: _usbService.isConnecting
                            ? null
                            : () => _usbService.scanAndConnect(),
                        child: _usbService.isConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Scan USB'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusIndicator(
                        'Arduino #1 (Upper/Right)',
                        _usbService.isConnected1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusIndicator(
                        'Arduino #2 (Lower/Left)',
                        _usbService.isConnected2,
                      ),
                    ),
                  ],
                ),
                if (_usbService.isSimulationMode) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Running in Simulation Mode. Sliders and preset gestures will generate mock responses in the console logs below.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String title, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF2CB67D).withOpacity(0.3)
              : const Color(0xFF2D2E32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFF2CB67D)
                      : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'CONNECTED' : 'DISCONNECTED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isConnected
                      ? const Color(0xFF2CB67D)
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGesturesCard() {
    final gestures = [
      'REST',
      'OPEN',
      'GRIP',
      'POINT',
      'PINCH',
      'WAVE',
      'THUMBSUP',
      'NOD',
      'SHAKE',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preset Robot Gestures',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gestures.map((g) {
                return ElevatedButton(
                  onPressed: () => _usbService.sendCommand("GESTURE:$g"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: g == 'REST'
                        ? const Color(0xFF2CB67D)
                        : const Color(0xFF2D2E32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(g),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleLogCard() {
    return ListenableBuilder(
      listenable: _usbService,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Serial Communication Console',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.grey,
                      ),
                      onPressed: () => _usbService.clearLogs(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2D2E32)),
                  ),
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: _usbService.consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = _usbService.consoleLogs[index];
                      // Style send/receive logs differently
                      Color logColor = Colors.white70;
                      if (log.contains("Send:")) {
                        logColor = const Color(0xFF7F5AF0);
                      } else if (log.contains("Recv") || log.contains("PONG")) {
                        logColor = const Color(0xFF2CB67D);
                      } else if (log.contains("Warning") ||
                          log.contains("Error")) {
                        logColor = Colors.redAccent;
                      }
                      return Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: logColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: MANUAL CONTROLS ---
  Widget _buildManualControls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Joint Calibration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Calibrate individual servo outputs directly.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildJointGroupCard('Head (Arduino 1)', [
            _buildJointSlider('NECK_PAN', _currentPose.neckPan, (val) {
              setState(() => _currentPose.neckPan = val);
              _usbService.sendCommand("JOINT:NECK_PAN:$val");
            }),
            _buildJointSlider('NECK_TILT', _currentPose.neckTilt, (val) {
              setState(() => _currentPose.neckTilt = val);
              _usbService.sendCommand("JOINT:NECK_TILT:$val");
            }),
          ]),
          const SizedBox(height: 16),
          _buildJointGroupCard('Right Arm (Arduino 1)', [
            _buildJointSlider('R_SHOULDER_X', _currentPose.rShoulderX, (val) {
              setState(() => _currentPose.rShoulderX = val);
              _usbService.sendCommand("JOINT:R_SHOULDER_X:$val");
            }),
            _buildJointSlider('R_SHOULDER_Y', _currentPose.rShoulderY, (val) {
              setState(() => _currentPose.rShoulderY = val);
              _usbService.sendCommand("JOINT:R_SHOULDER_Y:$val");
            }),
            _buildJointSlider('R_ELBOW', _currentPose.rElbow, (val) {
              setState(() => _currentPose.rElbow = val);
              _usbService.sendCommand("JOINT:R_ELBOW:$val");
            }),
            _buildJointSlider('R_WRIST', _currentPose.rWrist, (val) {
              setState(() => _currentPose.rWrist = val);
              _usbService.sendCommand("JOINT:R_WRIST:$val");
            }),
          ]),
          const SizedBox(height: 16),
          _buildJointGroupCard('Left Arm (Arduino 2)', [
            _buildJointSlider('L_SHOULDER_X', _currentPose.lShoulderX, (val) {
              setState(() => _currentPose.lShoulderX = val);
              _usbService.sendCommand("JOINT:L_SHOULDER_X:$val");
            }),
            _buildJointSlider('L_SHOULDER_Y', _currentPose.lShoulderY, (val) {
              setState(() => _currentPose.lShoulderY = val);
              _usbService.sendCommand("JOINT:L_SHOULDER_Y:$val");
            }),
            _buildJointSlider('L_ELBOW', _currentPose.lElbow, (val) {
              setState(() => _currentPose.lElbow = val);
              _usbService.sendCommand("JOINT:L_ELBOW:$val");
            }),
            _buildJointSlider('L_WRIST', _currentPose.lWrist, (val) {
              setState(() => _currentPose.lWrist = val);
              _usbService.sendCommand("JOINT:L_WRIST:$val");
            }),
          ]),
          const SizedBox(height: 16),
          _buildJointGroupCard('Right Hand (Arduino 1)', [
            _buildJointSlider('R_THUMB', _currentPose.rThumb, (val) {
              setState(() => _currentPose.rThumb = val);
              _usbService.sendCommand("JOINT:R_THUMB:$val");
            }),
            _buildJointSlider('R_INDEX', _currentPose.rIndex, (val) {
              setState(() => _currentPose.rIndex = val);
              _usbService.sendCommand("JOINT:R_INDEX:$val");
            }),
          ]),
          const SizedBox(height: 16),
          _buildJointGroupCard('Torso & Spine (Arduino 2)', [
            _buildJointSlider('SPINE_BEND', _currentPose.spineBend, (val) {
              setState(() => _currentPose.spineBend = val);
              _usbService.sendCommand("JOINT:SPINE_BEND:$val");
            }),
            _buildJointSlider('WAIST_ROTATE', _currentPose.waistRotate, (val) {
              setState(() => _currentPose.waistRotate = val);
              _usbService.sendCommand("JOINT:WAIST_ROTATE:$val");
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildJointGroupCard(String title, List<Widget> sliders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const Divider(color: Color(0xFF2D2E32)),
            const SizedBox(height: 8),
            ...sliders,
          ],
        ),
      ),
    );
  }

  Widget _buildJointSlider(
    String jointName,
    int value,
    ValueChanged<int> onChanged,
  ) {
    final limit = RobotPose.limits[jointName] ?? [0, 180];
    final double minVal = limit[0].toDouble();
    final double maxVal = limit[1].toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              jointName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            '$value°',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Color(0xFF2CB67D),
            ),
          ),
          Expanded(
            child: Slider(
              min: minVal,
              max: maxVal,
              value: value.toDouble().clamp(minVal, maxVal),
              onChanged: (val) {
                onChanged(val.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: GEMMA OFFLINE BRAIN ---
  Widget _buildGemmaBrain() {
    return ListenableBuilder(
      listenable: _downloadService,
      builder: (context, _) {
        if (!_downloadService.isModelDownloaded) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Brain Offline',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You must download the Gemma 4 E2B model before accessing the offline brain client interface.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F5AF0),
                    ),
                    child: const Text('Go to Dashboard to Download'),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemma 4 E2B Local Client',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Interact with the offline, on-device AI decision module.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D2E32)),
                  ),
                  child: _chatMessages.isEmpty
                      ? const Center(
                          child: Text(
                            'Type a command like "wave hello" or "thumbs up" to trigger on-device actions.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScrollController,
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            final msg = _chatMessages[index];
                            final isUser = msg["sender"] == "user";
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? const Color(0xFF7F5AF0)
                                      : const Color(0xFF2D2E32),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isUser
                                        ? const Radius.circular(12)
                                        : const Radius.circular(0),
                                    bottomRight: isUser
                                        ? const Radius.circular(0)
                                        : const Radius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  msg["text"] ?? "",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Speak to robot (e.g. "wave your hand")...',
                        fillColor: const Color(0xFF16161A),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2D2E32),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7F5AF0),
                          ),
                        ),
                      ),
                      onSubmitted: _submitVoiceCommand,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _submitVoiceCommand(_chatController.text),
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF7F5AF0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
