import 'package:flutter/material.dart';
import '../widgets/activity_item.dart';
import '../widgets/friends_online_item.dart';

class SharedExperience extends StatefulWidget {
  const SharedExperience({super.key});
  @override
  State<SharedExperience> createState() => _SharedExperienceState();
}

class _SharedExperienceState extends State<SharedExperience> {
  final List<String> _activities = [
    'Chess',
    'Ludo',
    'Checkers',
    'Scrabble',
    'Monopoly',
    'Risk',
  ]; // Mock data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Shared Header - Moved to Home
            // const ChatAppBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // "Shared Experience" Title (Hero)
                    Center(
                      child: Hero(
                        tag: 'shared_experience_title',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Shared Experience',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3B2A),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Friends Online Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Friends Online',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1B3B2A),
                            ),
                          ),
                          const Spacer(),
                          // Mock Friends List
                          Row(
                            children: List.generate(
                              3,
                              (index) => const FriendsOnlineItem(imageUrl: ''),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main Content Area
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side: Infinite Scrollable List
                          Expanded(
                            flex: 3,
                            child: ListView.builder(
                              itemCount: 1000, // Infinite scrolling simulation
                              itemBuilder: (context, index) {
                                final activity =
                                    _activities[index % _activities.length];
                                return ActivityItem(
                                  title: activity,
                                  subtitle: 'Play now',
                                  icon: Icons.games, // Placeholder icon
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Right Side: Switchable Tabs
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildTabIcon(Icons.gamepad, true),
                                  _buildTabIcon(Icons.album, false),
                                  _buildTabIcon(Icons.movie, false),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // History Section (Bottom)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Center(
                                child: Text(
                                  'History',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1B3B2A),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Last Played',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '25/11/25',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Win',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3B2A),
                            ),
                          ),
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'See More',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.black,
        size: 28,
      ),
    );
  }
}
