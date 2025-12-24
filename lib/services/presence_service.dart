import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update the user's presence status
  Future<void> updatePresence(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true, // Optional flag, but timestamp is source of truth
      });
    } catch (e) {
      // Fail silently for presence updates to avoid spamming logs/UI
      // print('Error updating presence: $e');
    }
  }

  // Stream of a user's presence
  // Returns true if the user was seen in the last 5 seconds (approx)
  // We'll actually return the raw timestamp or a boolean based on a threshold check in UI
  // But for simplicity, let's return a Stream of the document and parse it in UI
  // Stream of a user's last seen timestamp
  Stream<DateTime?> getLastSeen(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null || !data.containsKey('lastSeen')) return null;

      final lastSeen = data['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    });
  }
}
