import 'package:flutter/material.dart';
import 'cached_image_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import 'connection_status_indicator.dart';

class ChatAppBar extends StatelessWidget {
  const ChatAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Hero(
        tag: 'chat_header',
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              // Logo
              Image.asset('assets/whisp_logo.png', width: 40, height: 40),
              const SizedBox(width: 12),

              // Connection Status
              const ConnectionStatusIndicator(),

              const Spacer(),

              // Settings Icon
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              // Profile Avatar (Navigate to Profile)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.userChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final photoUrl = user?.photoURL;

                    return photoUrl != null && photoUrl.isNotEmpty
                        ? CachedImageWidget(
                          imageUrl: photoUrl,
                          width: 40,
                          height: 40,
                          isCircle: true,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.pink[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        )
                        : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.pink[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
