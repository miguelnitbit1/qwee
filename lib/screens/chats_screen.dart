import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/chat.dart';
import '../widgets/platform_scaffold.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      title: 'Chats',
      body: const ChatComponent(),
    );
  }
}