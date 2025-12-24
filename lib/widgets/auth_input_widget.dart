import 'package:flutter/material.dart';
import 'dart:ui';

/// Widget for the authentication input form with buttons
class AuthInputWidget extends StatelessWidget {
  final bool isVisible;
  final bool showUserAvatar;
  final bool isLoading;
  final bool isSignupMode;
  final String userFirstLetter;
  final String usernameHint;
  final String? loadingMessage;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Animation<Offset> buttonPositionAnimation;
  final AnimationController buttonAnimationController;
  final VoidCallback onSubmit;
  final VoidCallback onBackPressed;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const AuthInputWidget({
    Key? key,
    required this.isVisible,
    required this.showUserAvatar,
    required this.isLoading,
    required this.isSignupMode,
    required this.userFirstLetter,
    required this.usernameHint,
    this.loadingMessage,
    required this.usernameController,
    required this.passwordController,
    required this.buttonPositionAnimation,
    required this.buttonAnimationController,
    required this.onSubmit,
    required this.onBackPressed,
    this.onCancel,
    this.showCancelButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Stack(
        children: [
          // Input field with glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // User avatar
                    if (showUserAvatar)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.black,
                          child: Text(
                            userFirstLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    // Text input field OR Loading Message
                    Expanded(
                      child:
                          isLoading
                              ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  loadingMessage ?? 'Please wait...',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                              : SizedBox(
                                width: 0,
                                child: TextField(
                                  style: const TextStyle(color: Colors.black),
                                  controller:
                                      showUserAvatar
                                          ? passwordController
                                          : usernameController,
                                  obscureText:
                                      showUserAvatar && !isSignupMode
                                          ? false
                                          : showUserAvatar,
                                  decoration: InputDecoration(
                                    labelStyle: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Colors.black,
                                    ),
                                    hintText:
                                        showUserAvatar
                                            ? 'Password'
                                            : usernameHint,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(width: 30),
                    // Action button (arrow/loading/check)
                    SlideTransition(
                      position: buttonPositionAnimation,
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: _buildActionButton(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Red back button (Cancel or Back)
          if (showUserAvatar || showCancelButton)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: (showUserAvatar || showCancelButton) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: isLoading ? onCancel : onBackPressed,
                    child: Icon(
                      isLoading ? Icons.close : Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: null,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      onPressed: onSubmit,
      child:
          showUserAvatar
              ? CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black,
                child: const Icon(Icons.check, color: Colors.white),
              )
              : const Icon(Icons.arrow_forward, color: Colors.white),
    );
  }
}
