import 'dart:async';
import 'package:flutter/material.dart';

/// State management for authentication screen
mixin AuthStateMixin on State {
  // Typewriter animation state
  final List<String> greetings = [
    'Welcome',
    'Hola',
    'Bonjour',
    'Hallo',
    'こんにちは',
    'مرحبا',
  ];

  String visibleText = '';
  int greetingIndex = 0;
  bool isDeleting = false;
  bool initialCycleDone = false;

  // Form state
  String subtitleText = 'Sign in to continue to your chats';
  String usernameHint = 'Email or username';
  bool isSignupMode = false;
  bool showSubtitle = false;
  bool showForm = false;

  // Loading and avatar state
  bool isLoading = false;
  bool showUserAvatar = false;
  String userFirstLetter = '';

  // Timers
  Timer? typingTimer;
  Timer? cursorTimer;
  bool showCursor = true;

  // Controllers
  late TextEditingController usernameController;
  late TextEditingController passwordController;

  // Animations
  late AnimationController buttonAnimationController;
  late Animation<Offset> buttonPositionAnimation;

  void initializeControllers() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();
  }

  void disposeControllers() {
    usernameController.dispose();
    passwordController.dispose();
  }

  void disposeTimers() {
    typingTimer?.cancel();
    cursorTimer?.cancel();
  }
}
