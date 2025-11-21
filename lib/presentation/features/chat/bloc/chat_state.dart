import 'package:equatable/equatable.dart';
import '../../../../domain/entities/document.dart'; // sesuaikan path jika perlu

class DocContext {
  final String title; // optional label from contexts array
  final String snippet; // short snippet or summary
  final String docId;
  final String sourceId; // optional id reference

  DocContext({
    required this.title,
    required this.snippet,
    required this.docId,
    required this.sourceId,
  });
}

class DocChunk {
  final String chunkId;
  final String text;
  final List<String>? highlights; // highlighted substrings (if provided)
  DocChunk({required this.chunkId, required this.text, this.highlights});
}

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
  final bool isUploading;
  final bool isIndexing;
  final bool composerExpanded;
  final List<DocumentEntity> uploadedDocs; // NON-NULLABLE
  final List<DocContext> lastContexts;
  final String? activeDocId;
  final List<DocChunk> activeTopChunks;
  final List<DocChunk> activeAllChunks;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isIndexing = false,
    this.composerExpanded = false,
    List<DocumentEntity>? uploadedDocs,
    this.lastContexts = const [],
    this.activeDocId,
    this.activeTopChunks = const [],
    this.activeAllChunks = const [],
  }) : uploadedDocs = uploadedDocs ?? const []; // but store non-null

  ChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? isUploading,
    bool? isIndexing,
    bool? composerExpanded,
    List<DocumentEntity>? uploadedDocs,
    List<DocContext>? lastContexts,
    String? activeDocId,
    List<DocChunk>? activeTopChunks,
    List<DocChunk>? activeAllChunks,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isIndexing: isIndexing ?? this.isIndexing,
      composerExpanded: composerExpanded ?? this.composerExpanded,
      uploadedDocs: uploadedDocs ?? this.uploadedDocs,
      lastContexts: lastContexts ?? this.lastContexts,
      activeDocId: activeDocId ?? this.activeDocId,
      activeTopChunks: activeTopChunks ?? this.activeTopChunks,
      activeAllChunks: activeAllChunks ?? this.activeAllChunks,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, composerExpanded, uploadedDocs, lastContexts,
        activeDocId,
        activeTopChunks,
        activeAllChunks,];
}
