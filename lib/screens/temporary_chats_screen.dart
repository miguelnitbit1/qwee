import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TemporaryChatsScreen extends StatelessWidget {
  const TemporaryChatsScreen({super.key});

  void _showChatDetails(BuildContext context, Map<String, dynamic> chatData, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(userData['imageUrl']),
                    child: null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userData['firstName']} ${userData['lastName']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          userData['phone'] ?? 'Sin teléfono',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatData['messages']?.length ?? 0,
                itemBuilder: (context, index) {
                  final message = chatData['messages'][index];
                  final isMe = message['isMe'];
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                message['imageUrl'],
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (message['text'] != null)
                            Text(
                              message['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            message['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats Temporales'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testUsers.length,
        itemBuilder: (context, index) {
          final user = _testUsers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user['imageUrl']),
              ),
              title: Text('${user['firstName']} ${user['lastName']}'),
              subtitle: Text(
                user['lastMessage'] ?? 'No hay mensajes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user['lastMessageTime'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (user['unreadCount'] > 0)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user['unreadCount'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => _showChatDetails(context, user['chatData'], user),
            ),
          );
        },
      ),
    );
  }

  static const List<Map<String, dynamic>> _testUsers = [
    {
      'firstName': 'Juan',
      'lastName': 'Pérez',
      'imageUrl': 'https://randomuser.me/api/portraits/men/4.jpg',
      'phone': '+34 111 222 333',
      'lastMessage': '¿Te gustaría ir al concierto?',
      'lastMessageTime': '5h',
      'unreadCount': 3,
      'chatData': {
        'messages': [
          {
            'text': '¿Te gustaría ir al concierto?',
            'time': '5h',
            'isMe': false,
          },
          {
            'text': '¿De qué concierto hablas?',
            'time': '4h',
            'isMe': true,
          },
          {
            'text': 'El de Coldplay, es esta noche',
            'time': '3h',
            'isMe': false,
          },
          {
            'text': '¡Me encantaría! ¿A qué hora?',
            'time': '2h',
            'isMe': true,
          },
        ],
      },
    },
    {
      'firstName': 'Laura',
      'lastName': 'Sánchez',
      'imageUrl': 'https://randomuser.me/api/portraits/women/5.jpg',
      'phone': '+34 444 555 666',
      'lastMessage': '¿Has terminado el proyecto?',
      'lastMessageTime': '1d',
      'unreadCount': 0,
      'chatData': {
        'messages': [
          {
            'text': '¿Has terminado el proyecto?',
            'time': '1d',
            'isMe': false,
          },
          {
            'text': 'Sí, lo acabo de enviar',
            'time': '1d',
            'isMe': true,
          },
          {
            'imageUrl': 'https://picsum.photos/200/200',
            'time': '1d',
            'isMe': false,
          },
        ],
      },
    },
    {
      'firstName': 'David',
      'lastName': 'Gómez',
      'imageUrl': 'https://randomuser.me/api/portraits/men/6.jpg',
      'phone': '+34 777 888 999',
      'lastMessage': '¿Vamos a jugar al fútbol?',
      'lastMessageTime': '2d',
      'unreadCount': 1,
      'chatData': {
        'messages': [
          {
            'text': '¿Vamos a jugar al fútbol?',
            'time': '2d',
            'isMe': false,
          },
          {
            'text': '¿Cuándo?',
            'time': '2d',
            'isMe': true,
          },
          {
            'text': 'Mañana a las 5',
            'time': '1d',
            'isMe': false,
          },
        ],
      },
    },
  ];
} 