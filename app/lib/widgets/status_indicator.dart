import 'package:flutter/material.dart';

/// Displays a hardware connection status indicator with a colored dot
/// and CONNECTED / DISCONNECTED label.
class StatusIndicator extends StatelessWidget {
  /// Title label (e.g. "Arduino #1 (Upper/Right)").
  final String title;

  /// Whether this device is currently connected.
  final bool isConnected;

  const StatusIndicator({
    super.key,
    required this.title,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF2CB67D).withAlpha(77)
              : const Color(0xFF2D2E32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isConnected ? const Color(0xFF2CB67D) : Colors.redAccent,
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
}
