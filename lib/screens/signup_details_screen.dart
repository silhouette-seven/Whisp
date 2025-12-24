import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:chat_app/screens/splash_screen.dart';
import 'package:chat_app/screens/auth_state_wrapper.dart';
import 'package:chat_app/widgets/background_container.dart';

class SignupDetailsScreen extends StatefulWidget {
  final String email;

  const SignupDetailsScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<SignupDetailsScreen> createState() => _SignupDetailsScreenState();
}

class _SignupDetailsScreenState extends State<SignupDetailsScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String? _uploadedImageUrl; // Track uploaded image URL for cleanup

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${path.basename(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  Future<String> _uploadProfilePhoto(String userId) async {
    if (_selectedImage == null) {
      throw Exception('No image selected');
    }

    try {
      // Compress image first
      final compressedImage = await _compressImage(_selectedImage!);
      final fileToUpload = compressedImage ?? _selectedImage!;

      debugPrint('[Upload] Starting image upload for user: $userId');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile.jpg');

      debugPrint('[Upload] Uploading image to Firebase Storage...');
      final uploadTask = storageRef.putFile(fileToUpload);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100)
            .toStringAsFixed(2);
        debugPrint(
          '[Upload] Progress: $progress% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)',
        );
      });

      await uploadTask;
      debugPrint('[Upload] Upload complete');

      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('[Upload] Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('[Upload] Error uploading image: $e');
      throw Exception('Failed to upload profile photo');
    }
  }

  Future<void> _createUserDocument(String userId, String photoUrl) async {
    try {
      debugPrint('[Firestore] Creating user document for userId: $userId');

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'username': _nameController.text.trim(),
        'email': widget.email,
        'image': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[Firestore] User document created successfully');
    } catch (e) {
      debugPrint('[Firestore] Error creating user document: $e');
      throw Exception('Failed to create user profile in database');
    }
  }

  Future<void> _deleteUploadedImage(String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile.jpg');
      await storageRef.delete();
    } catch (e) {
      debugPrint('Error deleting uploaded image: $e');
    }
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (_selectedImage == null) {
      _showError('Please select a profile photo');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Authentication error. Please try again.');
      }

      debugPrint('[Signup] Starting signup process for user: ${user.uid}');

      // Step 1: Update password (from temp password to actual password)
      debugPrint('[Signup] Updating password...');
      await user.updatePassword(_passwordController.text);
      debugPrint('[Signup] Password updated successfully');

      // Step 2: Upload profile photo and get URL
      debugPrint('[Signup] Starting image upload...');
      final photoUrl = await _uploadProfilePhoto(user.uid);
      _uploadedImageUrl = photoUrl;

      try {
        // Step 3: Create Firestore document
        debugPrint('[Signup] Creating Firestore document...');
        await _createUserDocument(user.uid, photoUrl);

        // Step 4: Update user profile in Auth
        debugPrint('[Signup] Updating user profile in Firebase Auth...');
        await user.updateDisplayName(_nameController.text.trim());
        await user.updatePhotoURL(photoUrl);
        await user.reload();
        debugPrint('[Signup] Signup process completed successfully');

        // Navigation to ChatsScreen will happen automatically via StreamBuilder
      } catch (e) {
        // If anything fails after upload, try to clean up the uploaded image
        debugPrint('[Signup] Error during signup, attempting cleanup...');
        if (_uploadedImageUrl != null) {
          await _deleteUploadedImage(user.uid);
          debugPrint('[Signup] Uploaded image deleted');
        }
        rethrow;
      }
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An unexpected error occurred. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleCancel() async {
    try {
      // Delete the account since signup is incomplete
      await FirebaseAuth.instance.currentUser?.delete();
      // Sign out to be safe
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthStateWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (!_isLoading) await _handleCancel();
      },
      child: BackgroundContainer(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 32.0,
                    bottom: bottomInset + 100,
                  ),
                  child: Column(
                    children: [
                      // Title
                      const SizedBox(height: 40),

                      // Profile Photo Picker
                      GestureDetector(
                        onTap: _isLoading ? null : _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300]!.withAlpha(200),
                            border: Border.all(
                              color: Colors.grey[800]!,
                              width: 3,
                            ),
                            image:
                                _selectedImage != null
                                    ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              _selectedImage == null
                                  ? const Center(
                                    child: Text(
                                      'Select\nPhoto',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email Field (Disabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300]!.withAlpha(200),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _nameController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black54),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300]!.withAlpha(200),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black54),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300]!.withAlpha(200),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Confirm Password',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black54),
                          ),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cancel Button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleCancel,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(100),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: 40),

                          // Submit Button
                          GestureDetector(
                            onTap: _isLoading ? null : _handleSubmit,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(100),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Logo at bottom
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset('assets/whisp_logo.png', width: 60),
                ),
              ),
              if (_isLoading) const Positioned.fill(child: SplashScreen()),
            ],
          ),
        ),
      ),
    );
  }
}
