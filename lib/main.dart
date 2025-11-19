import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'presentation/features/chat/bloc/chat_bloc.dart';
import 'presentation/features/chat/bloc/chat_event.dart';
import 'presentation/features/chat/pages/chat_page.dart';


void main() {
  runApp(const ChatAgentApp());
}

class ChatAgentApp extends StatelessWidget {
  const ChatAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Knowledge Agent',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF414A5A)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      ),
      home: BlocProvider(
        create: (_) => ChatBloc()..add(ChatStarted()),
        child: const ChatPage(),
      ),
    );
  }
}