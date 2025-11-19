import 'package:flutter/material.dart';
import '../bloc/chat_state.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final radius = BorderRadius.circular(12);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: isUser ? Theme.of(context).colorScheme.primary : Colors.white,
            borderRadius: isUser
                ? radius.copyWith(bottomRight: const Radius.circular(6))
                : radius.copyWith(bottomLeft: const Radius.circular(6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}