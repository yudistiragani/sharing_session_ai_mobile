import 'package:flutter/material.dart';

class DocUploader extends StatelessWidget {
  final VoidCallback onPick;
  final bool isLoading;

  const DocUploader({
    super.key,
    required this.onPick,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPick,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(isLoading ? 'Mengunggah...' : 'Unggah Dokumen'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
