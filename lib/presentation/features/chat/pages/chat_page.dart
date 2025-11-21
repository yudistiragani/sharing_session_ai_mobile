import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_field.dart';
import '../widgets/doc_uploader.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../widgets/document_card.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'csv', 'txt'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan dokumen dibatalkan')),
        );
        return;
      }

      final file = result.files.single;
      final name = file.name;
      final bytes = file.bytes;
      final path = file.path;

      context.read<ChatBloc>().add(UploadDocument(name: name, bytes: bytes, path: path));

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Mengunggah dokumen: $name')),
      // );
    } catch (e, st) {
      debugPrint('Error picking file: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih dokumen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.android)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Knowledge Agent', style: TextStyle(fontSize: 16)),
                Text('Chat with your documents', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.only(top: 12, bottom: 84),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final m = state.messages[index];
                        return MessageBubble(message: m);
                      },
                    ),
                    if (state.isLoading)
                      const Positioned(
                        top: 8,
                        right: 16,
                        child: Chip(label: Text('Thinking...')),
                      ),
                  ],
                );
              },
            ),
          ),

          // Quick action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return Expanded(
                      child: DocUploader(
                        onPick: () => _pickFile(context),
                        isUploading: state.isUploading,
                        isIndexing: state.isIndexing,
                      ),
                    );
                  },
                ),
                // const SizedBox(width: 8),
                // ElevatedButton(
                //   onPressed: () => context.read<ChatBloc>().add(ToggleComposerExpanded()),
                //   child: const Text('Saran & Prompt'),
                // ),
              ],
            ),
          ),

          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.uploadedDocs.isEmpty) return const SizedBox.shrink();
              final last = state.uploadedDocs.last;
              return DocumentCard(
                doc: last,
                onTap: () {
                  showModalBottomSheet(context: context, builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(last.filename, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('doc_id: ${last.docId}'),
                          Text('chunks: ${last.totalChunks ?? '-'}'),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
                        ],
                      ),
                    );
                  });
                },
              );
            },
          ),

          // Composer
          BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
            return ChatInputField(
              isBusy: state.isLoading,
              onAttach: () => _pickFile(context),
              onSend: (text) {
                final trimmed = text.trim();
                if (trimmed.isEmpty) return;

                // jika ada dokumen yg diupload & diindex (pakai yang terakhir), kirim ke endpoint chat
                if (state.uploadedDocs.isNotEmpty) {
                  final lastDoc = state.uploadedDocs.last;
                  context.read<ChatBloc>().add(
                    AskDocumentQuestion(question: trimmed, docId: lastDoc.docId, topK: 3),
                  );
                } else {
                  // fallback: lokal echo / normal message
                  context.read<ChatBloc>().add(SendUserMessage(trimmed));
                }
              },
            );
          }),
        ],
      ),
    );
  }
}