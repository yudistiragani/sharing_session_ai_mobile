// lib/presentation/features/chat/bloc/chat_state.dart
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/document.dart'; // sesuaikan path jika perlu

class ChatMessageEntity extends Equatable {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, text, fromUser, createdAt];
}

class ChatState extends Equatable {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final bool composerExpanded;
  final List<DocumentEntity> uploadedDocs; // NON-NULLABLE

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.composerExpanded = false,
    List<DocumentEntity>? uploadedDocs, // accept nullable param
  }) : uploadedDocs = uploadedDocs ?? const []; // but store non-null

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? composerExpanded,
    List<DocumentEntity>? uploadedDocs,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      composerExpanded: composerExpanded ?? this.composerExpanded,
      uploadedDocs: uploadedDocs ?? this.uploadedDocs,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, composerExpanded, uploadedDocs];
}
