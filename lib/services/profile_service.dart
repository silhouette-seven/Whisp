import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the "About" text for a user
  Stream<DocumentSnapshot> getAbout(String uid) {
    return _firestore.collection('user_about').doc(uid).snapshots();
  }

  // Update the "About" text for a user
  Future<void> updateAbout(String uid, String aboutText) async {
    await _firestore.collection('user_about').doc(uid).set({
      'about': aboutText,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Update Profile Image
  Future<String> updateProfileImage(String uid, File imageFile) async {
    try {
      // 1. Upload to Storage
      final ref = _storage.ref().child('users/$uid/profile_image.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // 2. Update Auth Profile
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      // 3. Update User Document in Firestore (if you keep a users collection)
      await _firestore.collection('users').doc(uid).set({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }
}
