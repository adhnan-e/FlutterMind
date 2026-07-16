import 'package:flutter/material.dart';
import 'services/usb_robot_service.dart';
import 'services/download_service.dart';
import 'services/robot_state_service.dart';
import 'screens/home_screen.dart';
import 'screens/manual_control_screen.dart';
import 'screens/gesture_screen.dart';
import 'screens/ai_mode_screen.dart';

void main() {
  runApp(const FlutterMindApp());
}

/// Root application widget for FlutterMind.
///
/// Configures the dark theme, color palette, and launches the
/// [MainDashboard] shell.
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
          overlayColor: const Color(0xFF2CB67D).withAlpha(31),
        ),
      ),
      home: const MainDashboard(),
    );
  }
}

/// Main navigation shell with a [NavigationRail] and tab content switcher.
///
/// Owns the shared services ([USBRobotService], [DownloadService],
/// [RobotStateService]) and passes them to child screens.
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late final USBRobotService _usbService;
  late final DownloadService _downloadService;
  late final RobotStateService _robotState;

  final ScrollController _logScrollController = ScrollController();

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _usbService = USBRobotService();
    _downloadService = DownloadService();
    _robotState = RobotStateService();

    // Auto-scroll log to bottom on new entries
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

  @override
  void dispose() {
    _usbService.removeListener(_scrollToBottomLog);
    _usbService.dispose();
    _downloadService.dispose();
    _robotState.dispose();
    _logScrollController.dispose();
    super.dispose();
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
          // Emergency STOP button — always visible
          ListenableBuilder(
            listenable: _usbService,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: IconButton(
                  icon: Icon(
                    Icons.emergency_rounded,
                    color: _usbService.pingWarning
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  tooltip: 'Emergency STOP',
                  onPressed: () {
                    _usbService.sendCommand('STOP');
                    _robotState.resetPose();
                  },
                ),
              );
            },
          ),
          // Simulation / USB mode toggle
          ListenableBuilder(
            listenable: _usbService,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      activeThumbColor: const Color(0xFF2CB67D),
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
          // Navigation rail
          NavigationRail(
            backgroundColor: const Color(0xFF16161A),
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              setState(() => _selectedTab = index);
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
                icon: Icon(Icons.gesture_rounded),
                selectedIcon: Icon(
                  Icons.gesture_rounded,
                  color: Color(0xFF7F5AF0),
                ),
                label: Text('Gestures'),
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
          // Main content
          Expanded(child: _buildSelectedTabContent()),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return HomeScreen(
          usbService: _usbService,
          downloadService: _downloadService,
          logScrollController: _logScrollController,
          onNavigateToDashboard: () => setState(() => _selectedTab = 0),
        );
      case 1:
        return ManualControlScreen(
          usbService: _usbService,
          robotState: _robotState,
        );
      case 2:
        return GestureScreen(usbService: _usbService);
      case 3:
        return AiModeScreen(
          usbService: _usbService,
          downloadService: _downloadService,
          onNavigateToDashboard: () => setState(() => _selectedTab = 0),
        );
      default:
        return HomeScreen(
          usbService: _usbService,
          downloadService: _downloadService,
          logScrollController: _logScrollController,
          onNavigateToDashboard: () => setState(() => _selectedTab = 0),
        );
    }
  }
}
