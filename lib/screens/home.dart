import 'package:chat_app/screens/chats_screen.dart';

import 'package:flutter/material.dart';
import '../widgets/chat_app_bar.dart';
import 'package:chat_app/widgets/background_container.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const ChatAppBar(),
              const Expanded(child: ChatsScreen()),
            ],
          ),
        ),
      ),
    );
  }
}
