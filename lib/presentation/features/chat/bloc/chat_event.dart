import 'package:equatable/equatable.dart';
import '../widgets/message_bubble.dart';
import 'dart:typed_data';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Fixed: Ensure ChatStarted is defined
class ChatStarted extends ChatEvent {
  ChatStarted();
}

class SendUserMessage extends ChatEvent {
  final String text;
  SendUserMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class ReceiveAgentMessage extends ChatEvent {
  final String text;
  ReceiveAgentMessage(this.text);

  @override
  List<Object?> get props => [text];
}

class UploadDocument extends ChatEvent {
  final String name;
  final Uint8List? bytes;
  final String? path;

  UploadDocument({required this.name, this.bytes, this.path});

  @override
  List<Object?> get props => [name, bytes, path];
}

class ToggleComposerExpanded extends ChatEvent {}

// Chat event: ask question against a specific document
class AskDocumentQuestion extends ChatEvent {
  final String question;
  final String docId; // gunakan last uploaded docId jika tidak disediakan oleh UI
  final int topK;

  AskDocumentQuestion({
    required this.question,
    required this.docId,
    this.topK = 3,
  });

  @override
  List<Object?> get props => [question, docId, topK];
}

// NEW: fetch document sources / highlights
class FetchDocumentSources extends ChatEvent {
  final String docId;
  final String question;
  final int topK;

  FetchDocumentSources({required this.docId, required this.question, this.topK = 3});

  @override
  List<Object?> get props => [docId, question, topK];
}
