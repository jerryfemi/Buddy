import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _usersCollection = 'users';

  Future<void> createUserProfileIfNotExists(User user) async {
    final userDoc = _firestore.collection(_usersCollection).doc(user.uid);

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  //  Listen to live updates of a user profile
  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map(
          (snapshot) => snapshot.data(),
    );
  }

  //  Update profile fields
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(_usersCollection).doc(uid).update(data);
  }
}