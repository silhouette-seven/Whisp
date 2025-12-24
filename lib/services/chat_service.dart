import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a new chat with the user specified by [recipientEmail].
  /// Returns the chatId.
  Future<String> createChat(String recipientEmail) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    // 1. Find recipient user by email
    final userQuery =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: recipientEmail)
            .limit(1)
            .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('User not found');
    }

    final recipientDoc = userQuery.docs.first;
    final recipientId = recipientDoc.id;
    final recipientData = recipientDoc.data();

    if (recipientId == currentUser.uid) {
      throw Exception('You cannot chat with yourself');
    }

    // 2. Check if chat already exists in CURRENT user's chats
    final existingChatQuery =
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('chats')
            .where('recipientId', isEqualTo: recipientId)
            .limit(1)
            .get();

    if (existingChatQuery.docs.isNotEmpty) {
      return existingChatQuery.docs.first.id; // Return existing chatId
    }

    // 3. Create new chat
    // We generate a new chatId
    final chatId =
        _firestore.collection('users').doc().id; // Generate random ID

    final batch = _firestore.batch();

    // Current User's Chat Doc
    final currentUserChatRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(chatId);

    final currentUserChatData = {
      'chatId': chatId,
      'recipientId': recipientId,
      'recipientName': recipientData['username'] ?? 'Unknown',
      'recipientImage': recipientData['image'] ?? '',
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser.uid,
    };

    batch.set(currentUserChatRef, currentUserChatData);

    // Recipient's Chat Doc
    final recipientChatRef = _firestore
        .collection('users')
        .doc(recipientId)
        .collection('chats')
        .doc(chatId);

    final recipientChatData = {
      'chatId': chatId,
      'recipientId': currentUser.uid,
      'recipientName': currentUser.displayName ?? 'Unknown',
      'recipientImage': currentUser.photoURL ?? '',
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser.uid,
    };

    batch.set(recipientChatRef, recipientChatData);

    await batch.commit();
    return chatId;
  }

  /// Stream of chats for the current user
  Stream<QuerySnapshot> getChats() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Stream of messages for a specific chat (from CURRENT user's subcollection)
  Stream<QuerySnapshot> getMessages(String chatId) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Sends a message
  Future<void> sendMessage(
    String chatId,
    dynamic content, {
    String type = 'text',
    String? messageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageData = {
      'senderId': user.uid,
      'type': type,
      if (type == 'file')
        ...?content as Map<String, dynamic>?, // If content is metadata map
      if (type != 'file') 'content': content, // If content is string
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent', // Mark as sent when writing to DB
    };

    final batch = _firestore.batch();

    // 1. Get recipientId from current user's chat doc to know where to send the other copy
    final chatDocRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId);

    final chatDocSnapshot = await chatDocRef.get();
    if (!chatDocSnapshot.exists) throw Exception('Chat not found');

    final recipientId = chatDocSnapshot.get('recipientId') as String;

    // 2. Write to Current User's Messages
    // Use provided messageId or generate new one
    final currentUserMessageRef =
        messageId != null
            ? chatDocRef.collection('messages').doc(messageId)
            : chatDocRef.collection('messages').doc();

    batch.set(currentUserMessageRef, messageData);

    // Update Current User's Chat Metadata
    batch.update(chatDocRef, {
      'lastMessage':
          type == 'image' ? '📷 Image' : (type == 'file' ? '📎 File' : content),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Write to Recipient's Messages
    final recipientChatRef = _firestore
        .collection('users')
        .doc(recipientId)
        .collection('chats')
        .doc(chatId);

    final recipientMessageRef = recipientChatRef
        .collection('messages')
        .doc(currentUserMessageRef.id);
    batch.set(recipientMessageRef, messageData);

    // Update Recipient's Chat Metadata
    batch.update(recipientChatRef, {
      'lastMessage':
          type == 'image' ? '📷 Image' : (type == 'file' ? '📎 File' : content),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String> uploadChatImage(
    String chatId,
    File file, {
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      final fileToUpload = result != null ? File(result.path) : file;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(fileToUpload);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading chat image: $e');
      throw Exception('Failed to upload image');
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    File file,
    String chatId,
    String fileName,
    Function(double) onProgress,
  ) async {
    String? localPath;
    try {
      // 1. Copy file to local storage for immediate access (bandwidth optimization)
      try {
        final dir = await getApplicationDocumentsDirectory();
        localPath = path.join(dir.path, fileName);
        await file.copy(localPath);
      } catch (e) {
        debugPrint('Error copying file locally: $e');
        // Continue with upload even if local copy fails
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files')
          .child(chatId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      await uploadTask;
      final url = await storageRef.getDownloadURL();

      return {
        'url': url,
        'fileName': fileName,
        'size': await file.length(),
        'extension': path.extension(fileName),
      };
    } catch (e) {
      // If upload fails, delete the local copy to avoid clutter
      if (localPath != null) {
        try {
          final localFile = File(localPath);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (deleteError) {
          debugPrint(
            'Error deleting local file after upload failure: $deleteError',
          );
        }
      }
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }
}
