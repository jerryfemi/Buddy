import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String uid, File file) async {
    try {
      final ext = path.extension(file.path); // e.g. .jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${uid}_$timestamp$ext';
      final ref = _storage.ref().child('user_profiles').child(filename);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProfileImage(String imageUrl) async {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

  }
}