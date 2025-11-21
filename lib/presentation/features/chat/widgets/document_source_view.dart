import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_state.dart';
import '../bloc/chat_bloc.dart';

class DocumentSourceView extends StatelessWidget {
  final String docId;
  const DocumentSourceView({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sumber & Highlight', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
                  final top = state.activeTopChunks;
                  final all = state.activeAllChunks;

                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (top.isEmpty && all.isEmpty) {
                    return const Center(child: Text('Tidak ada chunk untuk dokumen ini.'));
                  }

                  return ListView(
                    controller: controller,
                    children: [
                      if (top.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Top chunks', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...top.map((c) => _buildChunkCard(context, c, highlightOnly: true)).toList(),
                        const Divider(),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('All chunks', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...all.map((c) => _buildChunkCard(context, c)).toList(),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChunkCard(BuildContext context, DocChunk chunk, {bool highlightOnly = false}) {
    final highlights = chunk.highlights;
    final displayText = highlightOnly && (highlights != null && highlights.isNotEmpty) ? highlights.join(' ... ') : chunk.text;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chunk: ${chunk.chunkId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(displayText, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(onPressed: () {
                // show full chunk in dialog
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Full chunk'),
                    content: SingleChildScrollView(child: Text(chunk.text)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                  ),
                );
              }, child: const Text('Open full')),
              const SizedBox(width: 8),
              TextButton(onPressed: () {
                Clipboard.setData(ClipboardData(text: chunk.text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chunk disalin')));
              }, child: const Text('Copy')),
            ],
          )
        ]),
      ),
    );
  }
}
