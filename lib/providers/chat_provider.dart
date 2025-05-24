import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/user_temporal_model.dart';
import '../mocks/chat_mocks.dart';
import 'geocerca_provider.dart';

/// Provider para gestionar todos los chats y mensajes de la aplicación
class ChatProvider with ChangeNotifier {
  // Colecciones principales
  List<Chat> _chats = [];
  
  // Getters
  List<Chat> get chats => _chats;
  
  // Filtros por tipo de chat
  List<Chat> get permanentChats => _chats.where((chat) => !chat.isTemporary).toList();
  List<Chat> get temporaryChats => _chats.where((chat) => chat.isTemporary).toList();
  
  // Socket para tiempo real (se implementará después)
  // Socket? _socket;
  
  // Constructor
  ChatProvider() {
    _loadChats();
  }
  
  // Cargar chats desde almacenamiento local o mocks
  Future<void> _loadChats() async {
    try {
      // Intentar cargar desde almacenamiento local
      final List<Chat> loadedChats = await _loadFromStorage();
      
      if (loadedChats.isEmpty) {
        // Si no hay chats guardados, cargar datos mock
        _loadMockChats();
      } else {
        _chats = loadedChats;
        notifyListeners();
      }
    } catch (e) {
      print('Error al cargar chats: $e');
      // En caso de error, cargar mocks
      _loadMockChats();
    }
  }
  
  // Cargar chats desde almacenamiento local
  Future<List<Chat>> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatData = prefs.getString('chats');
      
      if (chatData != null) {
        final List<dynamic> chatsJson = jsonDecode(chatData);
        return chatsJson.map((json) => Chat.fromMap(json)).toList();
      }
    } catch (e) {
      print('Error al cargar chats desde almacenamiento: $e');
    }
    
    return [];
  }
  
  // Guardar chats en almacenamiento local
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = jsonEncode(_chats.map((chat) => chat.toMap()).toList());
      await prefs.setString('chats', chatsJson);
    } catch (e) {
      print('Error al guardar chats en almacenamiento: $e');
    }
  }
  
  // Cargar datos mock para pruebas
  void _loadMockChats() {
    final List<Chat> mockChats = [];
    
    // Cargar chats permanentes
    for (var userData in ChatMocks.permanentUsers) {
      final String chatId = 'chat_${mockChats.length + 1}';
      final List<ChatMessage> messages = [];
      
      // Convertir mensajes del formato mock al nuevo formato
      if (userData['chatData'] != null && userData['chatData']['messages'] != null) {
        for (var msgData in userData['chatData']['messages']) {
          final bool isMe = msgData['isMe'] == true;
          
          messages.add(ChatMessage(
            id: 'msg_${messages.length + 1}_$chatId',
            senderId: isMe ? 'current_user' : 'user_${userData['firstName']}',
            receiverId: isMe ? 'user_${userData['firstName']}' : 'current_user',
            text: msgData['text'],
            imageUrl: msgData['imageUrl'],
            timestamp: DateTime.now().subtract(Duration(
              hours: msgData['time'].toString().contains('h') 
                  ? int.parse(msgData['time'].toString().replaceAll('h', ''))
                  : 0,
              days: msgData['time'].toString().contains('d')
                  ? int.parse(msgData['time'].toString().replaceAll('d', ''))
                  : 0,
            )),
            isRead: true,
            chatId: chatId,
            isTemporary: false,
          ));
        }
      }
      
      mockChats.add(Chat(
        id: chatId,
        name: '${userData['firstName']} ${userData['lastName']}',
        imageUrl: userData['imageUrl'],
        participants: ['current_user', 'user_${userData['firstName']}'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActivity: messages.isNotEmpty 
            ? messages.map((m) => m.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
        isTemporary: false,
        messages: messages,
      ));
    }
    
    // Cargar chats temporales
    for (var userData in ChatMocks.temporaryUsers) {
      final String chatId = 'temp_chat_${mockChats.length + 1}';
      final List<ChatMessage> messages = [];
      
      // Convertir mensajes del formato mock al nuevo formato
      if (userData['chatData'] != null && userData['chatData']['messages'] != null) {
        for (var msgData in userData['chatData']['messages']) {
          final bool isMe = msgData['isMe'] == true;
          
          messages.add(ChatMessage(
            id: 'msg_${messages.length + 1}_$chatId',
            senderId: isMe ? 'current_user' : 'temp_user_${userData['firstName']}',
            receiverId: isMe ? 'temp_user_${userData['firstName']}' : 'current_user',
            text: msgData['text'],
            imageUrl: msgData['imageUrl'],
            timestamp: DateTime.now().subtract(Duration(
              hours: msgData['time'].toString().contains('h') 
                  ? int.parse(msgData['time'].toString().replaceAll('h', ''))
                  : 0,
              days: msgData['time'].toString().contains('d')
                  ? int.parse(msgData['time'].toString().replaceAll('d', ''))
                  : 0,
            )),
            isRead: false,
            chatId: chatId,
            isTemporary: true,
          ));
        }
      }
      
      mockChats.add(Chat(
        id: chatId,
        name: '${userData['firstName']} ${userData['lastName']}',
        imageUrl: userData['imageUrl'],
        participants: ['current_user', 'temp_user_${userData['firstName']}'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        lastActivity: messages.isNotEmpty 
            ? messages.map((m) => m.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
        isTemporary: true,
        geocercaId: 'geocerca_1', // ID de geocerca mock
        messages: messages,
      ));
    }
    
    _chats = mockChats;
    notifyListeners();
    _saveToStorage(); // Guardar mocks en almacenamiento local
  }
  
  // Obtener un chat por su ID
  Chat? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }
  
  // Obtener el chat entre el usuario actual y otro usuario
  Chat? getChatWithUser(String otherUserId) {
    try {
      return _chats.firstWhere((chat) => 
        chat.participants.contains('current_user') && 
        chat.participants.contains(otherUserId)
      );
    } catch (e) {
      return null;
    }
  }
  
  // Enviar un mensaje
  Future<bool> sendMessage({
    required String chatId, 
    required String receiverId, 
    String? text, 
    String? imageUrl
  }) async {
    try {
      // Verificar que exista el chat
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex < 0) return false;
      
      // Crear nuevo mensaje
      final message = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'current_user',
        receiverId: receiverId,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isRead: false,
        chatId: chatId,
        isTemporary: _chats[chatIndex].isTemporary,
      );
      
      // Añadir mensaje al chat
      final updatedChat = _chats[chatIndex].addMessage(message);
      _chats[chatIndex] = updatedChat;
      
      // Aquí se implementaría el envío por socket.io
      
      notifyListeners();
      _saveToStorage();
      return true;
    } catch (e) {
      print('Error al enviar mensaje: $e');
      return false;
    }
  }
  
  // Marcar mensajes como leídos
  Future<bool> markChatAsRead(String chatId) async {
    try {
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex < 0) return false;
      
      final updatedChat = _chats[chatIndex].markAsRead('current_user');
      _chats[chatIndex] = updatedChat;
      
      notifyListeners();
      _saveToStorage();
      return true;
    } catch (e) {
      print('Error al marcar mensajes como leídos: $e');
      return false;
    }
  }
  
  // Crear un nuevo chat temporal después de aceptar una solicitud
  Future<Chat?> createTemporaryChat(UserTemporal otherUser, String? geocercaId) async {
    try {
      // Verificar si ya existe un chat con este usuario
      final existingChat = getChatWithUser(otherUser.id);
      if (existingChat != null) {
        return existingChat;
      }
      
      // Crear nuevo chat
      final chatId = 'temp_chat_${DateTime.now().millisecondsSinceEpoch}';
      final newChat = Chat(
        id: chatId,
        name: otherUser.fullName,
        imageUrl: otherUser.profileImageUrl,
        participants: ['current_user', otherUser.id],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        isTemporary: true,
        geocercaId: geocercaId ?? otherUser.geocercaId,
        messages: [], // Sin mensajes iniciales
      );
      
      _chats.add(newChat);
      notifyListeners();
      _saveToStorage();
      
      return newChat;
    } catch (e) {
      print('Error al crear chat temporal: $e');
      return null;
    }
  }
  
  // Eliminar un chat
  Future<bool> deleteChat(String chatId) async {
    try {
      _chats.removeWhere((chat) => chat.id == chatId);
      notifyListeners();
      _saveToStorage();
      return true;
    } catch (e) {
      print('Error al eliminar chat: $e');
      return false;
    }
  }
  
  // Método para vincular con geocercaProvider y manejar la aceptación de solicitudes
  Future<bool> handleChatRequestAccepted(GeocercaProvider geocercaProvider, String requestId) async {
    try {
      // Buscar la solicitud
      final currentUser = geocercaProvider.currentUser;
      if (currentUser == null) return false;
      
      final requests = geocercaProvider.currentUserChatRequests;
      final request = requests.firstWhere((req) => req.id == requestId);
      
      // Buscar el usuario que envió la solicitud
      final sender = geocercaProvider.getUserById(request.fromUserId);
      if (sender == null) return false;
      
      // Crear un nuevo chat temporal
      final chat = await createTemporaryChat(sender, currentUser.geocercaId);
      
      return chat != null;
    } catch (e) {
      print('Error al manejar solicitud aceptada: $e');
      return false;
    }
  }
  
  // Método para conectar al socket.io (implementación futura)
  Future<void> connectToSocket() async {
    // Implementación futura para socket.io
  }
  
  // Método para desconectar del socket.io (implementación futura)
  void disconnectFromSocket() {
    // Implementación futura para socket.io
  }
  
  @override
  void dispose() {
    // Desconectar del socket al cerrar
    disconnectFromSocket();
    super.dispose();
  }
} 