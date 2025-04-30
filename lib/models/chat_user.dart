class ChatUser {
  final String firstName;
  final String lastName;
  final String imageUrl;
  final String? phone;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic> chatData;

  const ChatUser({
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
    this.phone,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.chatData,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      firstName: map['firstName'],
      lastName: map['lastName'],
      imageUrl: map['imageUrl'],
      phone: map['phone'],
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'],
      unreadCount: map['unreadCount'] ?? 0,
      chatData: map['chatData'],
    );
  }
}