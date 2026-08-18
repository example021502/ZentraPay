import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/repositories/voice_command_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AIAssistanceScreen extends StatefulWidget {
  const AIAssistanceScreen({super.key});

  @override
  State<AIAssistanceScreen> createState() => _AIAssistanceScreenState();
}

class _AIAssistanceScreenState extends State<AIAssistanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello there, how may i be of help today?",
      isUser: false,
      time: "",
    ),
  ];
  bool _isSending = false;

  // `VoiceCommandResult` (the shared /api/zvoice/history shape) has no
  // commandType field, so CHAT turns can't be filtered out of the shared
  // history cache client-side — it would mix in VOICE entries from the
  // recording screen. Rather than render a misleading merged history, this
  // screen keeps its own local, session-only chat transcript and appends to
  // it directly from each sendCommand() round trip (user bubble immediately,
  // assistant bubble once the real reply comes back).
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          time: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
        ),
      );
      _messageController.clear();
      _isSending = true;
    });

    try {
      final result = await VoiceCommandHistoryRepository.instance.sendCommand(
        commandType: 'CHAT',
        transcript: text,
      );
      if (!mounted) return;
      final reply = result.responseText;
      setState(() {
        _messages.add(
          ChatMessage(
            text: (reply != null && reply.isNotEmpty)
                ? reply
                : "Sorry, I couldn't come up with a reply for that.",
            isUser: false,
            time: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Something went wrong reaching the assistant. Please try again.",
            isUser: false,
            time: DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // Pink rounded-bottom hero header, matching the rest of ZVoice AI's
  // sticky-hero pages rather than a flat Material AppBar.
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        decoration: const BoxDecoration(
          color: AppColors.main,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.main,
                  size: 16,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                "Chat with AI Assistance",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 38), // Balances the back button so the
            // title stays visually centered.
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Matches the Figma frame: the user's own bubble sits on the left in
    // pale green, the assistant's reply on the right in pale grey.
    return Align(
      alignment: message.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isUser ? "You" : "Assistant",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: const TextStyle(fontSize: 14, color: AppColors.textBlack),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: const TextStyle(fontSize: 10, color: AppColors.textBlack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: !_isSending,
                  decoration: const InputDecoration(
                    hintText: "Ask anything...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}
