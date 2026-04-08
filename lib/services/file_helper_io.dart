import 'dart:io';
import 'dart:typed_data';

/// Native implementation — reads file bytes then deletes the temp file.
Future<Uint8List?> readAndDeleteFile(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  try {
    await file.delete();
  } catch (_) {}
  return bytes;
}

Future<void> deleteFile(String path) async {
  try {
    await File(path).delete();
  } catch (_) {}
}
