import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  bool get isReady => _storage != null;

  Future<({String url, String name})> uploadPdf({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    if (!isReady) {
      throw StateError('Firebase Storage hazir degil.');
    }
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage!.ref().child(path);

    await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));

    final url = await ref.getDownloadURL();
    return (url: url, name: safeName);
  }
}
