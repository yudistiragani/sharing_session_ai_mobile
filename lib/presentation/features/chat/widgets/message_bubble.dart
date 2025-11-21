// lib/presentation/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/chat_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import 'document_source_view.dart';

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
          child: _buildMessageBody(context),
        ),
      ),
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    final isUser = message.fromUser;

    if (isUser) {
      return Text(
        message.text,
        style: const TextStyle(color: Colors.white, height: 1.3),
      );
    }

    // For agent messages: only show contexts when this message is the latest agent message.
    return BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
      // Find last agent message id in the current state messages
      final lastAgentIndex = state.messages.lastIndexWhere((m) => m.fromUser == false);
      final String? lastAgentId = lastAgentIndex != -1 ? state.messages[lastAgentIndex].id : null;

      final showContexts = (lastAgentId != null && lastAgentId == message.id && state.lastContexts.isNotEmpty);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Markdown answer
          MarkdownBody(
            data: message.text,
            selectable: true,
            onTapLink: (text, href, title) async {
              if (href == null) return;
              final uri = Uri.tryParse(href);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka link')));
              }
            },
          ),

          const SizedBox(height: 8),

          // Only render the small contexts list when this bubble is the latest agent message
          if (showContexts) ...[
            const Text('Sumber relevan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            // list small cards
            ...state.lastContexts.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.source, size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.title.isNotEmpty)
                            Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            c.snippet,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Trigger fetch doc sources and open bottom sheet
                                  context.read<ChatBloc>().add(FetchDocumentSources(
                                        docId: c.docId,
                                        question: message.text,
                                        topK: 3,
                                      ));
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<ChatBloc>(),
                                        child: DocumentSourceView(docId: c.docId),
                                      );
                                    },
                                  );
                                },
                                child: const Text('View source'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  // alias to view source (or you can implement highlight-only)
                                  context.read<ChatBloc>().add(FetchDocumentSources(
                                        docId: c.docId,
                                        question: message.text,
                                        topK: 3,
                                      ));
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<ChatBloc>(),
                                        child: DocumentSourceView(docId: c.docId),
                                      );
                                    },
                                  );
                                },
                                child: const Text('Show highlights'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          ] else
            const SizedBox.shrink(),
        ],
      );
    });
  }
}
