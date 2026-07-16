import 'package:flutter/material.dart';
import '../services/usb_robot_service.dart';

/// Displays a scrollable serial communication console with color-coded
/// log entries.
///
/// Send commands appear purple, received/PONG messages green, and
/// warnings/errors red.
class ConsoleLogCard extends StatelessWidget {
  /// The USB robot service whose [USBRobotService.consoleLogs] to display.
  final USBRobotService usbService;

  /// Scroll controller for auto-scrolling to the latest log entry.
  final ScrollController scrollController;

  const ConsoleLogCard({
    super.key,
    required this.usbService,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
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
                      tooltip: 'Clear logs',
                      onPressed: () => usbService.clearLogs(),
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
                    controller: scrollController,
                    itemCount: usbService.consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = usbService.consoleLogs[index];
                      return Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _logColor(log),
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

  /// Determine the display color for a log entry based on its content.
  Color _logColor(String log) {
    if (log.contains('Send:')) return const Color(0xFF7F5AF0);
    if (log.contains('Recv') || log.contains('PONG')) {
      return const Color(0xFF2CB67D);
    }
    if (log.contains('Warning') || log.contains('Error')) {
      return Colors.redAccent;
    }
    return Colors.white70;
  }
}
