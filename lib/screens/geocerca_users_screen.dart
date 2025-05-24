import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../models/user_temporal_model.dart';
import '../models/chat.dart';
import '../providers/geocerca_provider.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_scaffold.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_modal.dart';
import '../utils/adaptive_colors.dart';
import '../providers/chat_provider.dart';

class GeocercaUsersScreen extends StatefulWidget {
  const GeocercaUsersScreen({super.key});

  @override
  State<GeocercaUsersScreen> createState() => _GeocercaUsersScreenState();
}

class _GeocercaUsersScreenState extends State<GeocercaUsersScreen> {
  final TextEditingController _messageController = TextEditingController();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  void _showChatRequestDialog(BuildContext context, UserTemporal user) {
    final colors = context.colors;
    final isIOS = Platform.isIOS;
    
    _messageController.clear();
    
    if (isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Enviar solicitud a ${user.fullName}'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _messageController,
                placeholder: 'Escribe un mensaje (máx. 140 caracteres)',
                maxLength: 140,
                padding: const EdgeInsets.all(8),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                _sendChatRequest(user.id);
                Navigator.pop(context);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enviar solicitud a ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje (máx. 140 caracteres)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 140,
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: colors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                _sendChatRequest(user.id);
                Navigator.pop(context);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
    }
  }
  
  Future<void> _sendChatRequest(String userId) async {
    if (_messageController.text.trim().isEmpty) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Por favor, escribe un mensaje',
        isError: true,
      );
      return;
    }
    
    final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
    final success = await geocercaProvider.sendChatRequest(
      userId,
      _messageController.text.trim(),
    );
    
    if (success && mounted) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Solicitud enviada correctamente',
        isError: false,
      );
    } else if (mounted) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Error al enviar la solicitud',
        isError: true,
      );
    }
  }
  
  void _showUserDetails(BuildContext context, UserTemporal user) {
    final colors = context.colors;
    final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Verificar si ya existe un chat con este usuario
    final existingChat = chatProvider.getChatWithUser(user.id);
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(user.profileImageUrl),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        Text(
          'En geocerca desde hace ${user.timeElapsed}',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.description,
            style: TextStyle(
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (existingChat != null)
          // Si ya existe un chat, mostrar botón para ir al chat
          PlatformButton(
            text: 'Ir al chat',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(context, existingChat);
            },
          )
        else
          // Si no existe un chat, mostrar botón para solicitar chat
          PlatformButton(
            text: 'Enviar solicitud de chat',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              _showChatRequestDialog(context, user);
            },
          ),
      ],
    );
    
    PlatformModal.showContentModal(
      context: context,
      title: 'Perfil de ${user.firstName}',
      content: content,
      cancelText: 'Cerrar',
    );
  }
  
  // Método para navegar a la pantalla de chat
  void _navigateToChat(BuildContext context, Chat chat) {
    // Esta navegación podría ser implementada una vez que tengas una pantalla de chat individual
    // Por ahora, mostramos una notificación
    PlatformAlert.showNotification(
      context: context,
      message: 'Abriendo chat con ${chat.name}',
      isError: false,
    );
    
    // Navegar a la pantalla de chats (sección temporal)
    Navigator.pushNamed(context, '/chats');
  }
  
  @override
  Widget build(BuildContext context) {
    final geocercaProvider = Provider.of<GeocercaProvider>(context);
    final currentGeocerca = geocercaProvider.currentGeocerca;
    final currentUser = geocercaProvider.currentUser;
    final users = geocercaProvider.usersInCurrentGeocerca;
    final colors = context.colors;
    
    // Si no hay geocerca o usuario actual, redirigir
    if (currentGeocerca == null || currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return const SizedBox.shrink();
    }
    
    return WillPopScope(
      onWillPop: () async {
        // Asegurar que se restablezca correctamente la bandera de navegación
        geocercaProvider.isNavigating = false;
        return true;
      },
      child: PlatformScaffold(
        title: currentGeocerca.name,
        actions: [
          IconButton(
            icon: Icon(Platform.isIOS ? CupertinoIcons.bell : Icons.notifications),
            onPressed: () {
              // Mostrar solicitudes pendientes
              _showPendingRequests(context);
            },
          ),
          IconButton(
            icon: Icon(Platform.isIOS ? CupertinoIcons.arrow_right_circle : Icons.exit_to_app),
            onPressed: () {
              // Salir de la geocerca
              _confirmExit(context);
            },
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de información de la geocerca
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido a ${currentGeocerca.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usuarios conectados: ${users.length + 1}', // +1 por el usuario actual
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tu perfil temporal estará activo mientras permanezcas en esta geocerca.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de usuarios
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'No hay otros usuarios en esta geocerca',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserItem(context, user);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserItem(BuildContext context, UserTemporal user) {
    final colors = context.colors;
    final isIOS = Platform.isIOS;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(user.profileImageUrl),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          'En geocerca hace ${user.timeElapsed}',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        trailing: PlatformButton(
          text: 'Ver',
          isPrimary: false,
          expandWidth: false,
          onPressed: () => _showUserDetails(context, user),
        ),
        onTap: () => _showUserDetails(context, user),
      ),
    );
  }
  
  void _showPendingRequests(BuildContext context) {
    final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
    final requests = geocercaProvider.currentUserChatRequests;
    final colors = context.colors;
    
    if (requests.isEmpty) {
      PlatformAlert.showNotification(
        context: context,
        message: 'No tienes solicitudes pendientes',
        isError: false,
      );
      return;
    }
    
    // Contenido personalizado para el modal
    Widget content = ListView.builder(
      shrinkWrap: true,
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final sender = geocercaProvider.getUserById(request.fromUserId);
        
        if (sender == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(sender.profileImageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Hace ${_formatTimestamp(request.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.message,
                style: TextStyle(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlatformButton(
                    text: 'Rechazar',
                    isPrimary: false,
                    isDestructive: true,
                    expandWidth: false,
                    onPressed: () {
                      geocercaProvider.rejectChatRequest(request.id);
                      Navigator.pop(context);
                      PlatformAlert.showNotification(
                        context: context,
                        message: 'Solicitud rechazada',
                        isError: false,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  PlatformButton(
                    text: 'Aceptar',
                    isPrimary: true,
                    expandWidth: false,
                    onPressed: () async {
                      final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
                      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                      
                      // Primero aceptar la solicitud en GeocercaProvider
                      final success = await geocercaProvider.acceptChatRequest(request.id);
                      
                      // Luego crear el chat temporal en ChatProvider
                      if (success) {
                        final chatCreated = await chatProvider.handleChatRequestAccepted(geocercaProvider, request.id);
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          
                          if (chatCreated) {
                            PlatformAlert.showNotification(
                              context: context,
                              message: 'Chat iniciado con ${sender.fullName}',
                              isError: false,
                            );
                            
                            // Navegar a la pantalla de chats (opcional)
                            // Navigator.pushNamed(context, '/chats');
                          } else {
                            PlatformAlert.showNotification(
                              context: context,
                              message: 'Error al iniciar chat',
                              isError: true,
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    
    PlatformModal.showContentModal(
      context: context,
      title: 'Solicitudes de chat',
      content: content,
      cancelText: 'Cerrar',
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inSeconds}s';
    }
  }
  
  void _confirmExit(BuildContext context) {
    PlatformAlert.showConfirmDialog(
      context: context,
      title: 'Salir de la geocerca',
      message: '¿Estás seguro de que quieres salir de esta geocerca? Tu perfil temporal será eliminado.',
      confirmText: 'Salir',
      cancelText: 'Cancelar',
    ).then((confirmed) {
      if (confirmed) {
        final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
        // Primero actualizar la bandera de navegación
        geocercaProvider.isNavigating = false;
        // Después salir de la geocerca
        geocercaProvider.exitCurrentGeocerca();
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }
} 