import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final _uuid = const Uuid();

  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<SendUserMessage>(_onSendUserMessage);
    on<ReceiveAgentMessage>(_onReceiveAgentMessage);
    on<UploadDocument>(_onUploadDocument);
    on<ToggleComposerExpanded>(_onToggleComposerExpanded);
  }

  FutureOr<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) {
    // Load welcome messages / suggestions
    final welcome = ChatMessageEntity(
      id: _uuid.v4(),
      text: 'Halo! Unggah dokumenmu atau tanyakan sesuatu tentang dokumen yang sudah diunggah.',
      fromUser: false,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(messages: [welcome]));
  }

  FutureOr<void> _onSendUserMessage(SendUserMessage event, Emitter<ChatState> emit) async {
    if (event.text.trim().isEmpty) return;
    final userMsg = ChatMessageEntity(
      id: _uuid.v4(),
      text: event.text,
      fromUser: true,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(messages: [...state.messages, userMsg], isLoading: true));

    // Simulate API call: in production, call repository/usecase
    await Future.delayed(const Duration(milliseconds: 700));

    // Fake agent response (replace with streaming / real response)
    add(ReceiveAgentMessage('Menjawab: "${event.text}" — (ini respon simulasi)'));
  }

  FutureOr<void> _onReceiveAgentMessage(ReceiveAgentMessage event, Emitter<ChatState> emit) {
    final agentMsg = ChatMessageEntity(
      id: _uuid.v4(),
      text: event.text,
      fromUser: false,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(messages: [...state.messages, agentMsg], isLoading: false));
  }

  FutureOr<void> _onUploadDocument(UploadDocument event, Emitter<ChatState> emit) async {
    final name = event.name;
    final bytes = event.bytes;
    final path = event.path;

    final docMsg = ChatMessageEntity(
      id: _uuid.v4(),
      text: 'Mengunggah dokumen: $name',
      fromUser: true,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(messages: [...state.messages, docMsg], isLoading: true));

    try {
      // TODO: panggil repository/upload API anda di sini.
      // contoh pseudo:
      // await repository.uploadDocument(name: name, bytes: bytes, path: path);

      await Future.delayed(const Duration(seconds: 1)); // simulasi

      add(ReceiveAgentMessage('Dokumen "$name" berhasil diproses dan siap dicari.'));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
      add(ReceiveAgentMessage('Gagal memproses dokumen "$name": $e'));
    }
  }

  FutureOr<void> _onToggleComposerExpanded(ToggleComposerExpanded event, Emitter<ChatState> emit) {
    emit(state.copyWith(composerExpanded: !state.composerExpanded));
  }
}