// lib/domain/entities/document.dart

class DocumentEntity {
  final String docId;
  final String filename;
  final int? totalChunks;
  final DateTime uploadedAt;

  // indexing info
  final bool indexed;
  final String? jobId;
  final DateTime? indexedAt;
  final int? indexedCount;

  const DocumentEntity({
    required this.docId,
    required this.filename,
    this.totalChunks,
    required this.uploadedAt,
    this.indexed = false,
    this.jobId,
    this.indexedAt,
    this.indexedCount,
  });

  DocumentEntity copyWith({
    String? docId,
    String? filename,
    int? totalChunks,
    DateTime? uploadedAt,
    bool? indexed,
    String? jobId,
    DateTime? indexedAt,
    int? indexedCount,
  }) {
    return DocumentEntity(
      docId: docId ?? this.docId,
      filename: filename ?? this.filename,
      totalChunks: totalChunks ?? this.totalChunks,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      indexed: indexed ?? this.indexed,
      jobId: jobId ?? this.jobId,
      indexedAt: indexedAt ?? this.indexedAt,
      indexedCount: indexedCount ?? this.indexedCount,
    );
  }
}
