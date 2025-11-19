import 'package:flutter/material.dart';

class DocUploader extends StatelessWidget {
  final bool isUploading;
  final bool isIndexing;
  final VoidCallback onPick;

  const DocUploader({
    super.key,
    required this.isUploading,
    required this.isIndexing,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBusy = isUploading || isIndexing;

    String label = "Unggah Dokumen";

    if (isUploading) {
      label = "Mengunggah...";
    } else if (isIndexing) {
      label = "Mengindex...";
    }

    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onPick,
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
