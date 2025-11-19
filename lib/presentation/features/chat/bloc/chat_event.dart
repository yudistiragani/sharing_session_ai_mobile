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