import 'package:equatable/equatable.dart';

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

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.composerExpanded = false,
  });

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? composerExpanded,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      composerExpanded: composerExpanded ?? this.composerExpanded,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, composerExpanded];
}