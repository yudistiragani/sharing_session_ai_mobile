import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/entities/document.dart';

class DocumentCard extends StatelessWidget {
  final DocumentEntity doc;
  final VoidCallback? onTap;

  const DocumentCard({super.key, required this.doc, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(doc.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('doc_id: ${doc.docId} • chunks: ${doc.totalChunks ?? '-'}'),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: doc.docId));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('doc_id disalin')));
          },
        ),
      ),
    );
  }
}
