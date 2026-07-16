import 'package:flutter/material.dart';
import '../services/usb_robot_service.dart';
import '../services/download_service.dart';
import '../services/llm_brain_service.dart';

/// AI mode chat screen where users type natural-language commands and
/// the Gemma 4 E2B brain (currently mocked) translates them to robot
/// actions.
class AiModeScreen extends StatefulWidget {
  /// USB robot service for sending generated commands.
  final USBRobotService usbService;

  /// Download service to check if the model is downloaded.
  final DownloadService downloadService;

  /// Callback to navigate to the Dashboard tab for model download.
  final VoidCallback onNavigateToDashboard;

  const AiModeScreen({
    super.key,
    required this.usbService,
    required this.downloadService,
    required this.onNavigateToDashboard,
  });

  @override
  State<AiModeScreen> createState() => _AiModeScreenState();
}

class _AiModeScreenState extends State<AiModeScreen> {
  final LlmBrainService _brainService = LlmBrainService();
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  /// Submit a voice/text command to the AI brain.
  void _submitCommand(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': query});
      _chatMessages.add({
        'sender': 'ai',
        'text': '🤖 Gemma is processing command...',
      });
    });
    _chatController.clear();
    Future.delayed(
      const Duration(milliseconds: 100),
      _scrollToBottom,
    );

    _brainService.processQuery(query).then((decision) {
      setState(() {
        _chatMessages.removeLast(); // Remove thinking message
        _chatMessages.add({'sender': 'ai', 'text': decision.reply});
      });
      Future.delayed(
        const Duration(milliseconds: 100),
        _scrollToBottom,
      );

      if (decision.command != null) {
        widget.usbService.sendCommand(decision.command!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.downloadService,
      builder: (context, _) {
        if (!widget.downloadService.isModelDownloaded) {
          return _buildModelLockedView();
        }
        return _buildChatView();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Model Not Downloaded — Locked View
  // ---------------------------------------------------------------------------

  Widget _buildModelLockedView() {
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
              'You must download the Gemma 4 E2B model before accessing '
              'the offline brain client interface.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onNavigateToDashboard,
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

  // ---------------------------------------------------------------------------
  // Chat View
  // ---------------------------------------------------------------------------

  Widget _buildChatView() {
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
                        'Type a command like "wave hello", "thumbs up", '
                        '"peace", or "stop" to trigger on-device actions.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScrollController,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        final isUser = msg['sender'] == 'user';
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
                              msg['text'] ?? '',
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
                    hintText:
                        'Speak to robot (e.g. "wave your hand")...',
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
                  onSubmitted: _submitCommand,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _submitCommand(_chatController.text),
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
  }
}
