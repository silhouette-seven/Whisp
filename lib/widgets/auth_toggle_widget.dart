import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for the Signup/Login toggle
class AuthToggleWidget extends StatelessWidget {
  final bool isSignupMode;
  final VoidCallback onToggle;

  const AuthToggleWidget({
    Key? key,
    required this.isSignupMode,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              isSignupMode ? 'Have an account?  ' : "Don't have an account?  ",
              style: GoogleFonts.openSans(
                textStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: onToggle,
            child: Text(
              isSignupMode ? 'Login' : 'Signup',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
