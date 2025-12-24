import 'dart:async';
import 'package:chat_app/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/presence_service.dart';
import 'authentication_screen.dart';
import 'signup_details_screen.dart';

import 'splash_screen.dart';

/// Wrapper widget that determines the correct screen based on auth state
/// and Firestore user document existence
class AuthStateWrapper extends StatefulWidget {
  const AuthStateWrapper({Key? key}) : super(key: key);

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  final PresenceService _presenceService = PresenceService();
  Timer? _presenceTimer;
  User? _currentUser;
  bool _isFirstCheck = true; // Track if this is the first check on app launch

  // Memoize the Firestore stream to prevent recreation on every build/auth change
  Stream<DocumentSnapshot>? _firestoreStream;
  String? _streamUserId;

  @override
  void dispose() {
    _stopPresenceUpdates();
    super.dispose();
  }

  void _startPresenceUpdates(User user) {
    if (_presenceTimer != null && _presenceTimer!.isActive) return;

    _currentUser = user;
    // Update immediately
    _presenceService.updatePresence(user.uid);

    // Then every 5 seconds
    _presenceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentUser != null) {
        _presenceService.updatePresence(_currentUser!.uid);
      }
    });
  }

  void _stopPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _currentUser = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        // Show splash screen while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = authSnapshot.data;

        // User is not logged in - show authentication screen
        if (user == null) {
          _stopPresenceUpdates();
          _isFirstCheck = false; // Reset flag on logout
          _firestoreStream = null; // Reset stream
          _streamUserId = null;
          return const AuthenticationScreen();
        }

        // User is logged in but not verified - show authentication screen
        if (!user.emailVerified) {
          _stopPresenceUpdates();
          _firestoreStream = null;
          _streamUserId = null;
          return const AuthenticationScreen();
        }

        // Initialize stream only if user changed or stream is null
        if (_firestoreStream == null || _streamUserId != user.uid) {
          _streamUserId = user.uid;
          _firestoreStream =
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots();
        }

        // User is logged in AND verified - check if profile exists in Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestoreStream,
          builder: (context, firestoreSnapshot) {
            // Show splash screen while checking Firestore
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            // Check if document exists and has data
            final userDoc = firestoreSnapshot.data;
            final profileExists = userDoc?.exists ?? false;

            // If profile doesn't exist, user needs to complete signup
            if (!profileExists) {
              _stopPresenceUpdates();

              // If this is the first check (app restart) and profile is missing,
              // force sign out to "start over"
              if (_isFirstCheck) {
                // We need to schedule this to avoid build-phase errors
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAuth.instance.signOut();
                  // The stream will update and show AuthenticationScreen
                });
                // Show splash while signing out
                return const SplashScreen();
              }

              return SignupDetailsScreen(email: user.email ?? '');
            }

            // Profile exists - proceed to chats AND start presence updates
            // We use a post-frame callback or just call it here safely because
            // _startPresenceUpdates checks if timer is already active.
            _isFirstCheck =
                false; // Profile exists, so subsequent checks are fine
            _startPresenceUpdates(user);

            return Home();
          },
        );
      },
    );
  }
}
