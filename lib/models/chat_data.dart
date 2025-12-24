import 'package:flutter/material.dart';

class ChatData {
  final String name;
  final String message;
  final String avatarUrl; // Using asset path or network url
  final Color? avatarColor; // Fallback if no image

  ChatData({
    required this.name,
    required this.message,
    this.avatarUrl = '',
    this.avatarColor,
  });
}

final List<ChatData> dummyChats = [
  ChatData(
    name: 'Jane',
    message: 'How About Dinner!',
    avatarColor: const Color(0xFFFFE0B2), // Light Orange
  ),
  ChatData(
    name: 'Jane',
    message: 'How About Dinner!',
    avatarColor: const Color(0xFFC8E6C9), // Light Green
  ),
  ChatData(
    name: 'Jane',
    message: 'How About Dinner!',
    avatarColor: const Color(0xFFF8BBD0), // Light Pink
  ),
  ChatData(
    name: 'Jane',
    message: 'How About Dinner!',
    avatarColor: const Color(0xFFE1BEE7), // Light Purple
  ),
];
