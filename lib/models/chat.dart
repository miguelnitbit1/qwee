import 'chat_message.dart';

class Chat {
  final String id;
  final String name; // Nombre del chat o del otro usuario
  final String? imageUrl; // Imagen del chat o del otro usuario
  final List<String> participants; // IDs de los participantes
  final DateTime createdAt;
  final DateTime? lastActivity;
  final bool isTemporary; // Si es un chat temporal (de geocerca) o permanente
  final String? geocercaId; // ID de la geocerca si es temporal
  final List<ChatMessage> messages; // Mensajes del chat

  const Chat({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.participants,
    required this.createdAt,
    this.lastActivity,
    this.isTemporary = false,
    this.geocercaId,
    this.messages = const [],
  });

  // Último mensaje del chat
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    
    // Ordenar mensajes por fecha (más reciente primero)
    final sortedMessages = List<ChatMessage>.from(messages)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedMessages.first;
  }

  // Número de mensajes no leídos para un usuario específico
  int unreadCount(String userId) {
    return messages.where((msg) => 
      msg.receiverId == userId && !msg.isRead
    ).length;
  }

  // Constructor para crear desde un mapa (para JSON)
  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.parse(map['createdAt']),
      lastActivity: map['lastActivity'] != null 
          ? (map['lastActivity'] is DateTime 
              ? map['lastActivity'] 
              : DateTime.parse(map['lastActivity']))
          : null,
      isTemporary: map['isTemporary'] ?? false,
      geocercaId: map['geocercaId'],
      messages: (map['messages'] as List?)
          ?.map((msgMap) => ChatMessage.fromMap(msgMap))
          .toList() ?? [],
    );
  }

  // Convertir a mapa (para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'isTemporary': isTemporary,
      'geocercaId': geocercaId,
      'messages': messages.map((msg) => msg.toMap()).toList(),
    };
  }

  // Crear una copia con algunos atributos modificados
  Chat copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? lastActivity,
    bool? isTemporary,
    String? geocercaId,
    List<ChatMessage>? messages,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isTemporary: isTemporary ?? this.isTemporary,
      geocercaId: geocercaId ?? this.geocercaId,
      messages: messages ?? this.messages,
    );
  }

  // Añadir un mensaje al chat y devolver un nuevo objeto Chat
  Chat addMessage(ChatMessage message) {
    final newMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: newMessages,
      lastActivity: DateTime.now(),
    );
  }

  // Marcar como leídos los mensajes para un usuario específico
  Chat markAsRead(String userId) {
    final newMessages = messages.map((msg) {
      if (msg.receiverId == userId && !msg.isRead) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();
    
    return copyWith(messages: newMessages);
  }

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, isTemporary: $isTemporary, messageCount: ${messages.length})';
  }
} 