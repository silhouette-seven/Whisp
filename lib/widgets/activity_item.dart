import 'package:flutter/material.dart';

class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9), // Light grey from design
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Icon/Image placeholder
          Icon(icon, size: 60, color: Colors.black),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle, // e.g. "Ludo"
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  title, // e.g. "Chess"
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Checkers', // Placeholder for 3rd line
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Invite Text
          const Text(
            'Invite',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3B2A), // Dark green
            ),
          ),
        ],
      ),
    );
  }
}
