import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for displaying the subtitle
class SubtitleWidget extends StatelessWidget {
  final String text;
  final bool isVisible;

  const SubtitleWidget({
    Key? key,
    required this.text,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: GoogleFonts.openSans(
          textStyle: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
