import 'package:flutter/material.dart';

class FriendsOnlineItem extends StatelessWidget {
  final String imageUrl;
  final bool isOnline;

  const FriendsOnlineItem({
    super.key,
    required this.imageUrl,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange[100],
            child: const Icon(
              Icons.person,
              color: Colors.orange,
            ), // Placeholder
            // backgroundImage: NetworkImage(imageUrl), // Use when real images are available
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD9D9D9),
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
