import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for displaying the typewriter animated title
class TypewriterWidget extends StatelessWidget {
  final String visibleText;
  final bool showCursor;

  const TypewriterWidget({
    Key? key,
    required this.visibleText,
    required this.showCursor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$visibleText${showCursor ? '|' : ''}',
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: GoogleFonts.openSans(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 8.0,
                  color: Colors.black45,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
