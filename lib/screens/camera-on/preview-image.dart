// lib/camera/image_preview_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';

Future<String?> showImagePreviewDialog(BuildContext context, String imagePath) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'retake'),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ถ่ายใหม่'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'ok'),
                  icon: const Icon(Icons.check),
                  label: const Text('ตกลง'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
