import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../widgets/chat.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Chats'),
              backgroundColor: CupertinoColors.systemBlue,
            ),
            child: const SafeArea(
              child: ChatComponent(),
            ),
          )
        : const Scaffold(
            body: ChatComponent(),
          );
  }
}