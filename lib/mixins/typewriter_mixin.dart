import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin for typewriter animation logic
abstract class TypewriterMixin<T extends StatefulWidget> extends State<T> {
  late List<String> greetings;
  late String visibleText;
  late int greetingIndex;
  late bool isDeleting;
  late bool initialCycleDone;
  late Timer? typingTimer;
  late bool showCursor;
  late Timer? cursorTimer;
  late VoidCallback onFadeInsStart;

  void startCursorTimer() {
    cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => showCursor = !showCursor);
    });
  }

  void startTypewriter() {
    void scheduleNext(Duration d, void Function() cb) {
      typingTimer = Timer(d, cb);
    }

    void step() {
      final current = greetings[greetingIndex];

      if (!isDeleting) {
        if (visibleText.length < current.length) {
          setState(() => visibleText = current.substring(0, visibleText.length + 1));
          scheduleNext(const Duration(milliseconds: 120), step);
        } else {
          if (!initialCycleDone) {
            initialCycleDone = true;
            onFadeInsStart();
          }
          scheduleNext(const Duration(milliseconds: 900), () {
            isDeleting = true;
            step();
          });
        }
      } else {
        if (visibleText.isNotEmpty) {
          setState(() => visibleText = visibleText.substring(0, visibleText.length - 1));
          scheduleNext(const Duration(milliseconds: 60), step);
        } else {
          isDeleting = false;
          greetingIndex = (greetingIndex + 1) % greetings.length;
          scheduleNext(const Duration(milliseconds: 200), step);
        }
      }
    }

    step();
  }
}
