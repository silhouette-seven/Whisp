import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../widgets/cached_image_widget.dart';

import '../widgets/background_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  void _showEditAboutDialog(String currentAbout) {
    final TextEditingController controller = TextEditingController(
      text: currentAbout,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Edit About',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                if (currentUser != null) {
                  await _profileService.updateAbout(
                    currentUser!.uid,
                    controller.text.trim(),
                  );
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        await _profileService.updateProfileImage(
          currentUser!.uid,
          File(image.path),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _onInviteFriendPressed() {
    // Placeholder for invite friend functionality
    debugPrint('Invite a Friend button pressed');
  }

  void _onChangeLanguagePressed() {
    // Placeholder for change language functionality
    debugPrint('Change Language button pressed');
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox.shrink();

    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          currentUser?.photoURL != null
                              ? CachedImageWidget(
                                imageUrl: currentUser!.photoURL!,
                                width: 120,
                                height: 120,
                                isCircle: true,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.pink[200],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.pink[200],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.pink[200],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                          if (_isUploading)
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Grid for About and Connections
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // About Card
                        Expanded(
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: _profileService.getAbout(currentUser!.uid),
                            builder: (context, snapshot) {
                              final data =
                                  snapshot.data?.data()
                                      as Map<String, dynamic>?;
                              final aboutText =
                                  data?['about'] as String? ??
                                  'Just a Regular Person';

                              return GestureDetector(
                                onTap: () => _showEditAboutDialog(aboutText),
                                child: Container(
                                  height: 180,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE0E0E0,
                                    ), // Light grey like design
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'About',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        aboutText,
                                        textAlign: TextAlign.center,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Connections Card
                        Expanded(
                          child: Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Friends',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser!.uid)
                                            .collection('chats')
                                            .limit(3)
                                            .snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData)
                                        return const SizedBox();

                                      final docs = snapshot.data!.docs;
                                      if (docs.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No connections',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }

                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Simple layout for avatars
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            alignment: WrapAlignment.center,
                                            children:
                                                docs.map((doc) {
                                                  final data =
                                                      doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final img =
                                                      data['recipientImage']
                                                          as String?;
                                                  return img != null &&
                                                          img.isNotEmpty
                                                      ? CachedImageWidget(
                                                        imageUrl: img,
                                                        width: 36,
                                                        height: 36,
                                                        isCircle: true,
                                                        fit: BoxFit.cover,
                                                        placeholder: CircleAvatar(
                                                          radius: 18,
                                                          backgroundColor:
                                                              Colors.pink[200],
                                                          child: Text(
                                                            (data['recipientName']
                                                                        as String? ??
                                                                    '?')[0]
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        ),
                                                        errorWidget: CircleAvatar(
                                                          radius: 18,
                                                          backgroundColor:
                                                              Colors.pink[200],
                                                          child: Text(
                                                            (data['recipientName']
                                                                        as String? ??
                                                                    '?')[0]
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          ),
                                                        ),
                                                      )
                                                      : CircleAvatar(
                                                        radius: 18,
                                                        backgroundColor:
                                                            Colors.pink[200],
                                                        child: Text(
                                                          (data['recipientName']
                                                                      as String? ??
                                                                  '?')[0]
                                                              .toUpperCase(),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      );
                                                }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Invite a Friend Button
                    GestureDetector(
                      onTap: _onInviteFriendPressed,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.mail_outline,
                              size: 28,
                              color: Colors.black,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Invite a Friend',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Change Language Button
                    GestureDetector(
                      onTap: _onChangeLanguagePressed,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.language, size: 28, color: Colors.black),
                            SizedBox(height: 4),
                            Text(
                              'Change Language',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Top Bar (rendered last so it's on top)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
