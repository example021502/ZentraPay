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
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chat with AI Assistance",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
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

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.green : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isUser ? "You" : "Assistant",
              style: TextStyle(
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
              style: TextStyle(fontSize: 10, color: AppColors.textBlack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isSending,
              decoration: const InputDecoration(
                hintText: "Ask anything...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _isSending ? null : _sendMessage,
            backgroundColor: AppColors.green,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
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
