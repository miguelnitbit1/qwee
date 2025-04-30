class ChatMocks {
  static const List<Map<String, dynamic>> permanentUsers = [
     {
      'firstName': 'Ana',
      'lastName': 'García',
      'imageUrl': 'https://randomuser.me/api/portraits/women/1.jpg',
      'phone': '+34 123 456 789',
      'lastMessage': '¡Hola! ¿Cómo estás?',
      'lastMessageTime': '2h',
      'unreadCount': 2,
      'chatData': {
        'messages': [
          {
            'text': '¡Hola! ¿Cómo estás?',
            'time': '2h',
            'isMe': false,
          },
          {
            'text': '¡Hola Ana! Todo bien, ¿y tú?',
            'time': '1h',
            'isMe': true,
          },
          {
            'text': 'Muy bien, gracias por preguntar. ¿Quieres quedar para tomar un café?',
            'time': '30m',
            'isMe': false,
          },
        ],
      },
    },
    {
      'firstName': 'Carlos',
      'lastName': 'Martínez',
      'imageUrl': 'https://randomuser.me/api/portraits/men/2.jpg',
      'phone': '+34 987 654 321',
      'lastMessage': '¿Vas a la reunión mañana?',
      'lastMessageTime': '1d',
      'unreadCount': 0,
      'chatData': {
        'messages': [
          {
            'text': '¿Vas a la reunión mañana?',
            'time': '1d',
            'isMe': false,
          },
          {
            'text': 'Sí, estaré allí a las 10',
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
      'firstName': 'María',
      'lastName': 'López',
      'imageUrl': 'https://randomuser.me/api/portraits/women/3.jpg',
      'phone': '+34 555 123 456',
      'lastMessage': '¿Has visto la última película?',
      'lastMessageTime': '3d',
      'unreadCount': 1,
      'chatData': {
        'messages': [
          {
            'text': '¿Has visto la última película?',
            'time': '3d',
            'isMe': false,
          },
          {
            'text': 'No, ¿es buena?',
            'time': '3d',
            'isMe': true,
          },
          {
            'text': 'Sí, es increíble. Deberías verla',
            'time': '2d',
            'isMe': false,
          },
        ],
      },
    }
  ];

  static const List<Map<String, dynamic>> temporaryUsers = [
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