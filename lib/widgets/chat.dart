import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../models/chat_user.dart';
import '../mocks/chat_mocks.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_modal.dart';
import '../widgets/platform_tabs.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_button.dart';

class ChatComponent extends StatefulWidget {
  const ChatComponent({Key? key}) : super(key: key);

  @override
  State<ChatComponent> createState() => _ChatComponentState();
}

class _ChatComponentState extends State<ChatComponent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChatUser> permanentUsers = [];
  final List<ChatUser> temporaryUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      // Convertimos los datos mock a objetos ChatUser
      final permanent = ChatMocks.permanentUsers
          .map((userData) => ChatUser.fromMap(userData))
          .toList();
      
      final temporary = ChatMocks.temporaryUsers
          .map((userData) => ChatUser.fromMap(userData))
          .toList();

      setState(() {
        permanentUsers.clear();
        temporaryUsers.clear();
        permanentUsers.addAll(permanent);
        temporaryUsers.addAll(temporary);
      });
    } catch (e) {
      print('Error cargando chats: $e');
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al cargar los chats: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showChatDetails(BuildContext context, Map<String, dynamic> chatData, ChatUser user) {
    final TextEditingController _messageController = TextEditingController();
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;
    
    // Contenido personalizado para el modal
    Widget chatContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Usuario y foto (header ya está incluido en el modal)
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
                          ? (isIOS ? CupertinoColors.activeBlue : theme.colorScheme.primary)
                          : (isIOS ? CupertinoColors.systemGrey5 : theme.colorScheme.surfaceVariant),
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
                              color: isMe
                                  ? (isIOS ? CupertinoColors.white : theme.colorScheme.onPrimary)
                                  : (isIOS ? CupertinoColors.label : theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe
                                ? (isIOS ? CupertinoColors.white.withOpacity(0.7) : theme.colorScheme.onPrimary.withOpacity(0.7))
                                : (isIOS ? CupertinoColors.secondaryLabel : theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Campo de mensaje
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              PlatformButton(
                text: '',
                icon: isIOS ? CupertinoIcons.paperclip : Icons.attach_file,
                onPressed: () {
                  // TODO: Implementar lógica para adjuntar archivos
                },
                expandWidth: false,
              ),
              Expanded(
                child: PlatformTextField(
                  controller: _messageController,
                  placeholder: 'Escribe un mensaje...',
                  keyboardType: TextInputType.multiline,
                ),
              ),
              PlatformButton(
                text: '',
                icon: isIOS ? CupertinoIcons.arrow_right_circle_fill : Icons.send,
                isPrimary: true,
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    // TODO: Implementar lógica para enviar el mensaje
                    print('Mensaje enviado: ${_messageController.text}');
                    _messageController.clear();
                  }
                },
                expandWidth: false,
              ),
            ],
          ),
        ),
      ],
    );
    
    // Este es un caso especial donde no usamos PlatformModal directamente
    // porque necesitamos más personalización
    if (isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header personalizado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: CupertinoColors.systemGrey,
                      backgroundImage: NetworkImage(user.imageUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                            ),
                          ),
                          Text(
                            user.phone ?? 'Sin teléfono',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xB3FFFFFF), // CupertinoColors.white con opacity 0.7
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contenido del chat
              Expanded(child: chatContent),
            ],
          ),
        ),
      );
    } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
                // Header personalizado
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: theme.colorScheme.secondary,
                      backgroundImage: NetworkImage(user.imageUrl),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          Text(
                            user.phone ?? 'Sin teléfono',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
                // Contenido del chat
                Expanded(child: chatContent),
            ],
          ),
        ),
      ),
    );
    }
  }

  Widget _buildChatList(List<ChatUser> users) {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Dismissible(
          key: Key(user.imageUrl),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onError,
              size: 26,
            ),
          ),
          dismissThresholds: const {
            DismissDirection.endToStart: 0.5,
          },
          movementDuration: const Duration(milliseconds: 200),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar eliminación'),
                  content: Text('¿Estás seguro de que quieres eliminar el chat con ${user.firstName}?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Eliminar',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            setState(() {
              if (users == permanentUsers) {
                permanentUsers.removeAt(index);
              } else {
                temporaryUsers.removeAt(index);
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chat con ${user.firstName} eliminado'),
                action: SnackBarAction(
                  label: 'Deshacer',
                  onPressed: () {
                    setState(() {
                      if (users == permanentUsers) {
                        permanentUsers.insert(index, user);
                      } else {
                        temporaryUsers.insert(index, user);
                      }
                    });
                  },
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.secondary,
                backgroundImage: NetworkImage(user.imageUrl),
              ),
              title: Text(
                '${user.firstName} ${user.lastName}',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                user.lastMessage ?? 'No hay mensajes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.lastMessageTime ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (user.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user.unreadCount.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => _showChatDetails(context, user.chatData, user),
            ),
          ),
        );
      },
    );
  }

  // Método para filtrar usuarios
  List<ChatUser> _getFilteredUsers(List<ChatUser> users) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return users;
    
    return users.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      return fullName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    if (_isLoading) {
      return Center(
        child: isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Barra de búsqueda
        if (_isSearchVisible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: PlatformTextField(
              controller: _searchController,
              placeholder: 'Buscar...',
              prefixIcon: isIOS ? CupertinoIcons.search : Icons.search,
              suffixIcon: isIOS ? CupertinoIcons.clear_circled_solid : Icons.close,
              onSuffixIconPressed: () {
                setState(() {
                  _isSearchVisible = false;
                  _searchController.clear();
                });
              },
              onChanged: (value) => setState(() {}),
              autofocus: true,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSearchVisible = true;
                });
              },
              child: Icon(
                isIOS ? CupertinoIcons.search : Icons.search,
                color: isIOS 
                    ? CupertinoTheme.of(context).primaryColor 
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        
        // Tabs adaptados a la plataforma
        Expanded(
          child: PlatformTabs(
            tabController: _tabController,
            tabs: const ['Permanentes', 'Temporales'],
            children: [
              _buildChatList(_getFilteredUsers(permanentUsers)),
              _buildChatList(_getFilteredUsers(temporaryUsers)),
            ],
            onTabChanged: (index) {
              // Podemos agregar acciones específicas al cambiar de tab
            },
          ),
        ),
      ],
    );
  }
}