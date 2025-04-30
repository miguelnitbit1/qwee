import 'package:flutter/material.dart';
import '../components/chat.dart';
import '../models/chat_user.dart';
import '../mocks/chat_mocks.dart';

class TemporaryChatsScreen extends StatelessWidget {
  const TemporaryChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = ChatMocks.temporaryUsers
        .map((user) => ChatUser.fromMap(user))
        .toList();

    return ChatScreen(
      isTemporary: true,
      users: users,
    );
  }
}