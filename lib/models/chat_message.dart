
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String chatId;
  final bool isTemporary;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    required this.chatId,
    this.isTemporary = false,
  });

  // Constructor para crear desde un mapa (para JSON)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'] is DateTime 
          ? map['timestamp'] 
          : DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      chatId: map['chatId'],
      isTemporary: map['isTemporary'] ?? false,
    );
  }

  // Convertir a mapa (para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'chatId': chatId,
      'isTemporary': isTemporary,
    };
  }

  // Crear una copia con algunos atributos modificados
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    String? chatId,
    bool? isTemporary,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      chatId: chatId ?? this.chatId,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, text: $text, isTemporary: $isTemporary)';
  }
} 