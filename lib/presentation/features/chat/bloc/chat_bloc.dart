import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../../../domain/entities/document.dart';


class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final _uuid = const Uuid();

  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<SendUserMessage>(_onSendUserMessage);
    on<ReceiveAgentMessage>(_onReceiveAgentMessage);
    on<UploadDocument>(_onUploadDocument);
    on<ToggleComposerExpanded>(_onToggleComposerExpanded);
    on<AskDocumentQuestion>(_onAskDocumentQuestion);
    on<FetchDocumentSources>(_onFetchDocumentSources);
  }

  FutureOr<void> _onAskDocumentQuestion(AskDocumentQuestion event, Emitter<ChatState> emit) async {
    final question = event.question.trim();
    final docId = event.docId;
    final topK = event.topK;

    if (question.isEmpty) return;

    // 1) push user message
    final userMsg = ChatMessageEntity(
      id: _uuid.v4(),
      text: question,
      fromUser: true,
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(messages: [...state.messages, userMsg], isLoading: true));

    try {
      final dio = Dio();
      final url = 'http://192.168.1.12:8000/agent/chat';

      final resp = await dio.post(
        url,
        data: {'doc_id': docId, 'question': question, 'top_k': topK},
        options: Options(contentType: Headers.formUrlEncodedContentType, headers: {'accept': 'application/json'}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;

        final answer = data['answer']?.toString() ?? 'No answer';
        final contextsRaw = data['contexts']; // expected array (may be empty)
        final List<DocContext> contexts = [];

        if (contextsRaw is List) {
          for (final item in contextsRaw) {
            try {
              // item may be string or object with fields
              if (item is String) {
                contexts.add(DocContext(title: '', snippet: item, docId: docId, sourceId: ''));
              } else if (item is Map) {
                final title = item['title']?.toString() ?? (item['source']?.toString() ?? '');
                final snippet = item['snippet']?.toString() ?? item['text']?.toString() ?? '';
                final sourceDocId = item['doc_id']?.toString() ?? docId;
                final sourceId = item['id']?.toString() ?? '';
                contexts.add(DocContext(title: title, snippet: snippet, docId: sourceDocId, sourceId: sourceId));
              }
            } catch (_) {}
          }
        }

        // Add agent message (answer rendered as markdown in UI)
        final agentMsg = ChatMessageEntity(
          id: _uuid.v4(),
          text: answer,
          fromUser: false,
          createdAt: DateTime.now(),
        );

        emit(state.copyWith(
          messages: [...state.messages, agentMsg],
          lastContexts: contexts,
          isLoading: false,
        ));
      } else {
        add(ReceiveAgentMessage('Gagal mendapatkan jawaban: status ${resp.statusCode}'));
        emit(state.copyWith(isLoading: false));
      }
    } catch (e, st) {
      debugPrint('AskDocumentQuestion error: $e\n$st');
      add(ReceiveAgentMessage('Terjadi error saat meminta jawaban: $e'));
      emit(state.copyWith(isLoading: false));
    }
  }

  // Handler: fetch document sources -> GET /agent/docs/{doc_id}?question=...&top_k=3
  FutureOr<void> _onFetchDocumentSources(FetchDocumentSources event, Emitter<ChatState> emit) async {
    final docId = event.docId;
    final question = event.question;
    final topK = event.topK;

    emit(state.copyWith(isLoading: true));

    try {
      final dio = Dio();
      final url = 'http://192.168.1.12:8000/agent/docs/$docId';
      final resp = await dio.get(url, queryParameters: {'question': question, 'top_k': topK});

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;

        // parse top_chunks and chunks (flexible)
        final topChunksRaw = data['top_chunks'];
        final chunksRaw = data['chunks'] ?? data['all_chunks'] ?? [];

        List<DocChunk> topChunks = [];
        List<DocChunk> allChunks = [];

        if (topChunksRaw is List) {
          for (final item in topChunksRaw) {
            try {
              if (item is Map) {
                topChunks.add(DocChunk(
                  chunkId: item['chunk_id']?.toString() ?? item['id']?.toString() ?? '',
                  text: item['text']?.toString() ?? item['content']?.toString() ?? '',
                  highlights: item['highlights'] is List ? List<String>.from(item['highlights'].map((e)=>e.toString())) : null,
                ));
              }
            } catch (_) {}
          }
        }

        if (chunksRaw is List) {
          for (final item in chunksRaw) {
            try {
              if (item is Map) {
                allChunks.add(DocChunk(
                  chunkId: item['chunk_id']?.toString() ?? item['id']?.toString() ?? '',
                  text: item['text']?.toString() ?? item['content']?.toString() ?? '',
                  highlights: item['highlights'] is List ? List<String>.from(item['highlights'].map((e)=>e.toString())) : null,
                ));
              }
            } catch (_) {}
          }
        }

        emit(state.copyWith(
          activeDocId: docId,
          activeTopChunks: topChunks,
          activeAllChunks: allChunks,
          isLoading: false,
        ));
      } else {
        add(ReceiveAgentMessage('Gagal mengambil sumber dokumen: status ${resp.statusCode}'));
        emit(state.copyWith(isLoading: false));
      }
    } catch (e, st) {
      debugPrint('FetchDocumentSources error: $e\n$st');
      add(ReceiveAgentMessage('Terjadi error saat mengambil sumber dokumen: $e'));
      emit(state.copyWith(isLoading: false));
    }
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
    emit(state.copyWith(messages: [...state.messages, docMsg], isLoading: true, isUploading: true, isIndexing: false,));

    try {
      final dio = Dio();
      final url = 'http://192.168.1.12:8000/agent/upload';

      MultipartFile filePart;
      if (bytes != null) {
        filePart = MultipartFile.fromBytes(
          bytes,
          filename: name,
          contentType: MediaType('application', _extToMime(name)),
        );
      } else if (path != null) {
        filePart = await MultipartFile.fromFile(
          path,
          filename: name,
          contentType: MediaType('application', _extToMime(name)),
        );
      } else {
        throw Exception('No file data available');
      }

      final formData = FormData.fromMap({'file': filePart});

      final resp = await dio.post(
        url,
        data: formData,
        options: Options(headers: {'accept': 'application/json', 'Content-Type': 'multipart/form-data'}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data;
        final docId = data['doc_id']?.toString() ?? '';
        final filename = data['filename']?.toString() ?? name;
        final totalChunks = data['total_chunks'] is int
            ? data['total_chunks'] as int
            : int.tryParse('${data['total_chunks']}');

        // create initial doc entity (indexed=false)
        var docEntity = DocumentEntity(
          docId: docId,
          filename: filename,
          totalChunks: totalChunks,
          uploadedAt: DateTime.now(),
        );

        // append to state (optimistic)
        final updatedDocs = [...state.uploadedDocs, docEntity];

        emit(state.copyWith(
          uploadedDocs: updatedDocs,
          isLoading: true, isUploading: false, isIndexing: true,
          messages: [
            ...state.messages,
            ChatMessageEntity(
              id: _uuid.v4(),
              text: 'Dokumen \"$filename\" berhasil diunggah (doc_id: $docId). Memulai proses indexing...',
              fromUser: false,
              createdAt: DateTime.now(),
            )
          ],
        ));

        // ---------- INDEXING STEP ----------
        try {
          final indexUrl = 'http://192.168.1.12:8000/agent/index';
          // form-url-encoded body as required by endpoint
          final indexResp = await dio.post(
            indexUrl,
            data: {
              'doc_id': docId,
              'mode': 'sync',
              'batch_size': 16,
              'concurrency': 8,
            },
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: {'accept': 'application/json'},
            ),
          );

          if (indexResp.statusCode == 200 || indexResp.statusCode == 201) {
            final idxData = indexResp.data;
            final job = idxData['job'];
            final jobId = job != null ? job['id']?.toString() : null;
            final finishedAtStr = job != null ? job['finished_at']?.toString() : null;
            DateTime? finishedAt;
            try {
              if (finishedAtStr != null) finishedAt = DateTime.parse(finishedAtStr);
            } catch (_) {}

            final details = job != null ? job['details'] : null;
            final indexedCount = details != null && details['indexed_count'] != null
                ? int.tryParse('${details['indexed_count']}')
                : null;

            // update docEntity with indexing result
            final updatedDocEntity = docEntity.copyWith(
              indexed: true,
              jobId: jobId,
              indexedAt: finishedAt,
              indexedCount: indexedCount,
            );

            // replace last (or matching) doc in list (safer: replace by docId)
            final replaced = updatedDocs.map((d) => d.docId == docId ? updatedDocEntity : d).toList();

            emit(state.copyWith(
              uploadedDocs: replaced,
              isLoading: false,
              isUploading: false,
              isIndexing: false,
              messages: [
                ...state.messages,
                ChatMessageEntity(
                  id: _uuid.v4(),
                  text: 'Indexing selesai untuk \"$filename\" — indexed_count: ${indexedCount ?? '-'}',
                  fromUser: false,
                  createdAt: DateTime.now(),
                )
              ],
            ));
          } else {
            // indexing returned non-200
            emit(state.copyWith(isLoading: false, isUploading: false, isIndexing: false));
            add(ReceiveAgentMessage('Indexing gagal untuk \"$filename\": server status ${indexResp.statusCode}'));
          }
        } catch (e, st) {
          debugPrint('Indexing error: $e\n$st');
          emit(state.copyWith(isLoading: false, isUploading: false, isIndexing: false));
          add(ReceiveAgentMessage('Gagal melakukan indexing untuk \"$filename\": $e'));
        }
      } else {
        add(ReceiveAgentMessage('Gagal mengunggah dokumen \"$name\": server mengembalikan status ${resp.statusCode}'));
      }
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      add(ReceiveAgentMessage('Gagal memproses dokumen \"$name\": $e'));
    } finally {
      emit(state.copyWith(isLoading: false, isUploading: false, isIndexing: false));
    }
  }

  // helper:
  String _extToMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'msword';
      case 'csv':
      case 'txt':
        return 'plain';
      default:
        return 'octet-stream';
    }
  }

  FutureOr<void> _onToggleComposerExpanded(ToggleComposerExpanded event, Emitter<ChatState> emit) {
    emit(state.copyWith(composerExpanded: !state.composerExpanded));
  }

  // FutureOr<void> _onAskDocumentQuestion(AskDocumentQuestion event, Emitter<ChatState> emit) async {
  //   final question = event.question.trim();
  //   final docId = event.docId;
  //   final topK = event.topK;

  //   if (question.isEmpty) return;

  //   // 1) Add user's question into chat UI
  //   final userMsg = ChatMessageEntity(
  //     id: _uuid.v4(),
  //     text: question,
  //     fromUser: true,
  //     createdAt: DateTime.now(),
  //   );
  //   emit(state.copyWith(messages: [...state.messages, userMsg], isUploading: false, isIndexing: false, isLoading: true));

  //   try {
  //     final dio = Dio();
  //     final url = 'http://192.168.1.12:8000/agent/chat';

  //     final resp = await dio.post(
  //       url,
  //       data: {
  //         'doc_id': docId,
  //         'question': question,
  //         'top_k': topK,
  //       },
  //       options: Options(
  //         contentType: Headers.formUrlEncodedContentType,
  //         headers: {'accept': 'application/json'},
  //       ),
  //     );

  //     if (resp.statusCode == 200 || resp.statusCode == 201) {
  //       final data = resp.data;
  //       final answer = data['answer']?.toString() ?? 'Tidak ada jawaban dari server.';
  //       final sessionId = data['chat_session_id']?.toString();

  //       // Append agent answer
  //       final agentMsg = ChatMessageEntity(
  //         id: _uuid.v4(),
  //         text: answer,
  //         fromUser: false,
  //         createdAt: DateTime.now(),
  //       );

  //       // optional: you can store sessionId somewhere if needed (not implemented here)
  //       emit(state.copyWith(messages: [...state.messages, agentMsg], isLoading: false));
  //     } else {
  //       add(ReceiveAgentMessage('Gagal mendapatkan jawaban: server status ${resp.statusCode}'));
  //       emit(state.copyWith(isLoading: false));
  //     }
  //   } catch (e, st) {
  //     debugPrint('Chat request error: $e\n$st');
  //     add(ReceiveAgentMessage('Terjadi error saat meminta jawaban: $e'));
  //     emit(state.copyWith(isLoading: false));
  //   }
  // }
}