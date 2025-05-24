import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_modal.dart';
import '../utils/adaptive_colors.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_tabs.dart';

// Eliminamos la clase AdaptiveColors local ya que usaremos la global

class ChatComponent extends StatefulWidget {
  const ChatComponent({super.key});

  @override
  State<ChatComponent> createState() => _ChatComponentState();
}

class _ChatComponentState extends State<ChatComponent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final bool _isLoading = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Método para alternar la visibilidad del campo de búsqueda
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  // Método para filtrar los chats por texto de búsqueda
  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) return chats;
    
    return chats.where((chat) => 
      chat.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Método para mostrar detalles de un chat
  void _showChatDetails(BuildContext context, Chat chat) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final colors = context.colors;
    
    // Marcar mensajes como leídos
    chatProvider.markChatAsRead(chat.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useSafeArea: true, // Esto asegura que no tape los elementos de UI del sistema
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Header con información del usuario
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colors.cardBorder,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Botón para cerrar
                          IconButton(
                            icon: Icon(
                              Platform.isIOS ? CupertinoIcons.chevron_down : Icons.close,
                              color: colors.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          
                          // Avatar del usuario
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: chat.imageUrl != null 
                                ? NetworkImage(chat.imageUrl!) 
                                : null,
                            backgroundColor: colors.primary.withOpacity(0.2),
                            child: chat.imageUrl == null 
                                ? Icon(Icons.person, color: colors.primary) 
                                : null,
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Nombre y estado
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  chat.isTemporary ? 'Chat temporal de geocerca' : 'Usuario permanente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Botón de opciones
                          IconButton(
                            icon: Icon(
                              Platform.isIOS ? CupertinoIcons.ellipsis : Icons.more_vert,
                              color: colors.textSecondary,
                            ),
                            onPressed: () {
                              // Mostrar opciones de chat
                              _showChatOptions(context, chat);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de mensajes
                    Expanded(
                      child: _buildChatMessages(chat),
                    ),
                    
                    // Campo para enviar mensajes
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: colors.cardBorder,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Botón para adjuntar
                          IconButton(
                            icon: Icon(
                              Platform.isIOS ? CupertinoIcons.photo : Icons.attach_file,
                              color: colors.primary,
                            ),
                            onPressed: () {
                              // Implementar adjuntar archivos
                            },
                          ),
                          
                          // Campo de texto
                          Expanded(
                            child: PlatformTextField(
                              controller: _messageController,
                              placeholder: 'Escribe un mensaje...',
                              maxLines: 3,
                            ),
                          ),
                          
                          // Botón para enviar
                          IconButton(
                            icon: Icon(
                              Platform.isIOS ? CupertinoIcons.arrow_right_circle_fill : Icons.send,
                              color: colors.primary,
                            ),
                            onPressed: () {
                              _sendMessage(chat);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Método para mostrar opciones de chat
  void _showChatOptions(BuildContext context, Chat chat) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    final List<ModalAction> actions = [
      ModalAction(
        title: 'Ver información',
        icon: Platform.isIOS ? CupertinoIcons.info : Icons.info_outline,
        onPressed: () {
          Navigator.pop(context);
          // Implementar ver información
        },
      ),
      ModalAction(
        title: 'Silenciar notificaciones',
        icon: Platform.isIOS ? CupertinoIcons.bell_slash : Icons.notifications_off,
        onPressed: () {
          Navigator.pop(context);
          // Implementar silenciar
        },
      ),
      ModalAction(
        title: 'Eliminar chat',
        icon: Platform.isIOS ? CupertinoIcons.delete : Icons.delete,
        isDestructive: true,
        onPressed: () {
          Navigator.pop(context);
          _confirmDeleteChat(context, chat, chatProvider);
        },
      ),
    ];
    
    PlatformModal.showActionsModal(
      context: context,
      title: 'Opciones',
      actions: actions,
      cancelText: 'Cancelar',
    );
  }
  
  // Método para confirmar eliminación de chat
  void _confirmDeleteChat(BuildContext context, Chat chat, ChatProvider chatProvider) {
    PlatformAlert.showConfirmDialog(
      context: context,
      title: 'Eliminar chat',
      message: '¿Estás seguro de que quieres eliminar este chat? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    ).then((confirmed) {
      if (confirmed) {
        chatProvider.deleteChat(chat.id);
        Navigator.pop(context); // Cerrar pantalla de chat
        
        PlatformAlert.showNotification(
          context: context,
          message: 'Chat eliminado',
          isError: false,
        );
      }
    });
  }
  
  // Método para enviar un mensaje
  void _sendMessage(Chat chat) {
    if (_messageController.text.trim().isEmpty) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final receiverId = chat.participants.firstWhere((id) => id != 'current_user');
    
    chatProvider.sendMessage(
      chatId: chat.id,
      receiverId: receiverId,
      text: _messageController.text.trim(),
    );
    
    _messageController.clear();
  }
  
  // Construir lista de mensajes
  Widget _buildChatMessages(Chat chat) {
    final colors = context.colors;
    final messages = chat.messages;
    
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No hay mensajes',
          style: TextStyle(
            color: colors.textSecondary,
          ),
        ),
      );
    }
    
    // Ordenar mensajes por fecha (más antiguos primero)
    final sortedMessages = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: sortedMessages.length,
      reverse: false,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        final isMe = message.senderId == 'current_user';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: chat.imageUrl != null 
                      ? NetworkImage(chat.imageUrl!) 
                      : null,
                  backgroundColor: colors.primary.withOpacity(0.2),
                  child: chat.imageUrl == null 
                      ? Icon(Icons.person, size: 16, color: colors.primary) 
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? colors.primary : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: message.imageUrl != null
                      ? Image.network(
                          message.imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          message.text ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : colors.textPrimary,
                          ),
                        ),
                ),
              ),
              
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final colors = context.colors;
    
    try {
      // Obtener chats permanentes y temporales
      final permanentChats = _filterChats(chatProvider.permanentChats);
      final temporaryChats = _filterChats(chatProvider.temporaryChats);
      
      if (_isLoading) {
        return Center(
          child: Platform.isIOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        );
      }
      
      return Column(
        children: [
          // Barra de búsqueda y botón
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_isSearchVisible)
                  Expanded(
                    child: PlatformTextField(
                      controller: _searchController,
                      placeholder: 'Buscar chats...',
                      prefixIcon: Platform.isIOS ? CupertinoIcons.search : Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                
                IconButton(
                  icon: Icon(
                    _isSearchVisible
                        ? (Platform.isIOS ? CupertinoIcons.xmark_circle : Icons.close)
                        : (Platform.isIOS ? CupertinoIcons.search : Icons.search),
                    color: colors.primary,
                  ),
                  onPressed: _toggleSearch,
                ),
              ],
            ),
          ),
          
          // Pestañas y contenido
          Expanded(
            child: PlatformTabs(
              tabController: _tabController,
              tabs: const ['Permanentes', 'Temporales'],
              children: [
                // Pestaña de chats permanentes
                _buildChatList(permanentChats),
                
                // Pestaña de chats temporales
                _buildChatList(temporaryChats),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      // Manejo de error al cargar los chats
      PlatformAlert.showNotification(
        context: context,
        message: 'Error al cargar los chats: $e',
        isError: true,
      );
      
      return Center(
        child: Text(
          'Error al cargar los chats',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
  }
  
  // Construir lista de chats
  Widget _buildChatList(List<Chat> chats) {
    final colors = context.colors;
    
    if (chats.isEmpty) {
      return Center(
        child: Text(
          'No hay chats',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatItem(chat);
      },
    );
  }
  
  // Construir elemento de chat
  Widget _buildChatItem(Chat chat) {
    final colors = context.colors;
    final lastMessage = chat.lastMessage;
    final unreadCount = chat.unreadCount('current_user');
    
    // Obtener fecha relativa del último mensaje
    String lastActivity = '';
    if (chat.lastActivity != null) {
      final now = DateTime.now();
      final difference = now.difference(chat.lastActivity!);
      
      if (difference.inDays > 0) {
        lastActivity = '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        lastActivity = '${difference.inHours}h';
      } else {
        lastActivity = '${difference.inMinutes}m';
      }
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: chat.imageUrl != null ? NetworkImage(chat.imageUrl!) : null,
        backgroundColor: colors.primary.withOpacity(0.2),
        child: chat.imageUrl == null ? Icon(Icons.person, color: colors.primary) : null,
      ),
      title: Text(
        chat.name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          color: colors.textPrimary,
        ),
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage.text ?? 'Imagen',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
              ),
            )
          : Text(
              chat.isTemporary ? 'Chat temporal de geocerca' : 'Sin mensajes',
              style: TextStyle(
                color: colors.textSecondary,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            lastActivity,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _showChatDetails(context, chat),
    );
  }
}