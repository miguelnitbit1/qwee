import 'package:flutter/material.dart';
import '../components/chat.dart';
import '../models/chat_user.dart';
import '../mocks/chat_mocks.dart';

class PermanentChatsScreen extends StatelessWidget {
  const PermanentChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = ChatMocks.permanentUsers
        .map((user) => ChatUser.fromMap(user))
        .toList();

    return ChatScreen(
      isTemporary: false,
      users: users,
    );
  }
}