class DocumentEntity {
  final String docId;
  final String filename;
  final int? totalChunks;
  final DateTime uploadedAt;

  const DocumentEntity({
    required this.docId,
    required this.filename,
    this.totalChunks,
    required this.uploadedAt,
  });
}
