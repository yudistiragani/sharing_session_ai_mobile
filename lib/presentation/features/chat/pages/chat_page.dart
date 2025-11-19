import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_field.dart';
import '../widgets/doc_uploader.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true, // IMPORTANT: ambil bytes juga
        type: FileType.custom,
        allowedExtensions: ['pdf','docx','doc','csv','txt'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan dokumen dibatalkan')),
        );
        return;
      }

      final file = result.files.single;
      final name = file.name;
      final bytes = file.bytes; // bisa null di beberapa platform jika withData=false
      final path = file.path;

      // dispatch richer event
      context.read<ChatBloc>().add(UploadDocument(name: name, bytes: bytes, path: path));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mengunggah dokumen: $name')),
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
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
                        isLoading: state.isLoading,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.read<ChatBloc>().add(ToggleComposerExpanded()),
                  child: const Text('Saran & Prompt'),
                ),
              ],
            ),
          ),

          // Composer
          BlocBuilder<ChatBloc, ChatState>(builder: (context, state) {
            return ChatInputField(
              isBusy: state.isLoading,
              onAttach: () => _pickFile(context),
              onSend: (text) => context.read<ChatBloc>().add(SendUserMessage(text)),
            );
          }),
        ],
      ),
    );
  }
}