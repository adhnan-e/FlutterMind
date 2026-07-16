import 'package:flutter/material.dart';
import '../services/usb_robot_service.dart';

/// Dedicated gesture preset screen with large tap-friendly buttons for
/// all protocol-supported gesture sequences.
class GestureScreen extends StatelessWidget {
  /// USB robot service for sending gesture commands.
  final USBRobotService usbService;

  const GestureScreen({
    super.key,
    required this.usbService,
  });

  /// All gesture names supported by the protocol, with display labels
  /// and icons.
  static const List<_GestureEntry> _gestures = [
    _GestureEntry('REST', Icons.hotel_rounded, Color(0xFF2CB67D)),
    _GestureEntry('OPEN', Icons.pan_tool_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('GRIP', Icons.front_hand_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('POINT', Icons.touch_app_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('PINCH', Icons.pinch_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('WAVE', Icons.waving_hand_rounded, Color(0xFFFF8906)),
    _GestureEntry('THUMBSUP', Icons.thumb_up_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('PEACE', Icons.back_hand_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('HELLO', Icons.emoji_people_rounded, Color(0xFFFF8906)),
    _GestureEntry('CLAP', Icons.volunteer_activism_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('NOD', Icons.swap_vert_rounded, Color(0xFF7F5AF0)),
    _GestureEntry('SHAKE', Icons.swap_horiz_rounded, Color(0xFF7F5AF0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gesture Presets',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Tap to trigger pre-programmed gesture sequences.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _gestures.length,
              itemBuilder: (context, index) {
                final g = _gestures[index];
                return _GestureButton(
                  entry: g,
                  onTap: () => usbService.sendCommand('GESTURE:${g.name}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for a gesture entry.
class _GestureEntry {
  final String name;
  final IconData icon;
  final Color color;

  const _GestureEntry(this.name, this.icon, this.color);
}

/// A large tap-friendly gesture button with icon and label.
class _GestureButton extends StatelessWidget {
  final _GestureEntry entry;
  final VoidCallback onTap;

  const _GestureButton({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF16161A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: entry.color.withAlpha(77),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entry.icon, color: entry.color, size: 36),
              const SizedBox(height: 8),
              Text(
                entry.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: entry.color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
