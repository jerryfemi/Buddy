import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Storage Rules', () {
    late FirebaseAuth auth;
    late FirebaseStorage storage;
    late String uid;

    setUpAll(() async {
      auth = FirebaseAuth.instance;
      storage = FirebaseStorage.instance;

      // Make sure user is signed in (anonymous is fine for testing)
      final user = await auth.signInAnonymously();
      uid = user.user!.uid;
    });

    test('User can upload to their own profile image path', () async {
      // Create a tiny test file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/test.txt');
      await file.writeAsString('hello test');

      final ref = storage.ref().child('user_profiles/$uid.txt');
      try {
        await ref.putFile(file);
      } catch (e) {
        fail('❌ Upload failed. Rules may be too strict. Error: $e');
      }
    });

    test('User cannot upload to someone else\'s profile path', () async {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/test2.txt');
      await file.writeAsString('should fail');

      final ref = storage.ref().child('user_profiles/someOtherUser.txt');

      await ref.putFile(file);
      fail(' Upload should have failed but succeeded.');
    });
  });
}
