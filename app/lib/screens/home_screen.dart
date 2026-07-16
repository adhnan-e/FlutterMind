import 'package:flutter/material.dart';
import '../services/usb_robot_service.dart';
import '../services/download_service.dart';
import '../widgets/status_indicator.dart';
import '../widgets/console_log_card.dart';

/// Main dashboard screen showing model status, hardware connections,
/// quick gesture presets, and the serial console log.
class HomeScreen extends StatelessWidget {
  /// USB robot service for hardware state and sending commands.
  final USBRobotService usbService;

  /// Download service for model management.
  final DownloadService downloadService;

  /// Scroll controller for the console log auto-scroll.
  final ScrollController logScrollController;

  /// Callback to navigate to the Dashboard tab for model download.
  final VoidCallback onNavigateToDashboard;

  const HomeScreen({
    super.key,
    required this.usbService,
    required this.downloadService,
    required this.logScrollController,
    required this.onNavigateToDashboard,
  });

  /// All protocol-supported gestures including PEACE, HELLO, CLAP.
  static const List<String> _gestures = [
    'REST',
    'OPEN',
    'GRIP',
    'POINT',
    'PINCH',
    'WAVE',
    'THUMBSUP',
    'PEACE',
    'HELLO',
    'CLAP',
    'NOD',
    'SHAKE',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model Downloader / Status Banner
          ListenableBuilder(
            listenable: downloadService,
            builder: (context, _) {
              if (!downloadService.isModelDownloaded) {
                return _buildDownloadPromptCard();
              } else {
                return _buildModelStatusCard(context);
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
          ConsoleLogCard(
            usbService: usbService,
            scrollController: logScrollController,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Model Download Prompt
  // ---------------------------------------------------------------------------

  Widget _buildDownloadPromptCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7F5AF0).withAlpha(38),
              const Color(0xFF16161A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF7F5AF0).withAlpha(77),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF8906),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
            if (downloadService.isDownloading) ...[
              LinearProgressIndicator(
                value: downloadService.progress,
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
                    'Speed: ${downloadService.downloadSpeed}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    downloadService.downloadedSize,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => downloadService.cancelDownload(),
                icon: const Icon(Icons.cancel_rounded),
                label: const Text('Cancel Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              if (downloadService.error != null) ...[
                Text(
                  downloadService.error!,
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'This will download gemma-4-E2B-it.litertlm (~2.5GB) directly '
                'from Hugging Face to local app storage. Please connect to a '
                'stable Wi-Fi network.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => downloadService.startDownload(),
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

  // ---------------------------------------------------------------------------
  // Model Status (Downloaded)
  // ---------------------------------------------------------------------------

  Widget _buildModelStatusCard(BuildContext context) {
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
                    'Stored at: ${downloadService.localModelPath}',
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
                      'This will delete the 2.5GB model file from app '
                      'storage. You will need to download it again to use '
                      'offline AI features.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          downloadService.deleteModel();
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

  // ---------------------------------------------------------------------------
  // Hardware Status
  // ---------------------------------------------------------------------------

  Widget _buildHardwareStatusCard() {
    return ListenableBuilder(
      listenable: usbService,
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
                    if (!usbService.isSimulationMode)
                      ElevatedButton(
                        onPressed: usbService.isConnecting
                            ? null
                            : () => usbService.scanAndConnect(),
                        child: usbService.isConnecting
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
                      child: StatusIndicator(
                        title: 'Arduino #1 (Upper/Right)',
                        isConnected: usbService.isConnected1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatusIndicator(
                        title: 'Arduino #2 (Lower/Left)',
                        isConnected: usbService.isConnected2,
                      ),
                    ),
                  ],
                ),
                if (usbService.isSimulationMode) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Running in Simulation Mode. Sliders and preset gestures '
                    'will generate mock responses in the console logs below.',
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

  // ---------------------------------------------------------------------------
  // Quick Gesture Presets
  // ---------------------------------------------------------------------------

  Widget _buildQuickGesturesCard() {
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
              children: _gestures.map((g) {
                return ElevatedButton(
                  onPressed: () => usbService.sendCommand('GESTURE:$g'),
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
}
