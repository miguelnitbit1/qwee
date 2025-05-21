import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../widgets/platform_button.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_modal.dart';
import '../widgets/platform_scaffold.dart';

class PlatformExampleScreen extends StatefulWidget {
  const PlatformExampleScreen({super.key});

  @override
  State<PlatformExampleScreen> createState() => _PlatformExampleScreenState();
}

class _PlatformExampleScreenState extends State<PlatformExampleScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
  
  void _showSimpleAlert() {
    PlatformAlert.showAlert(
      context: context,
      title: 'Título de alerta',
      message: 'Este es un mensaje de alerta simple para mostrar información al usuario.',
      actions: [
        AlertAction(
          text: 'Aceptar',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
  
  void _showConfirmDialog() async {
    final bool result = await PlatformAlert.showConfirmDialog(
      context: context,
      title: 'Confirmar acción',
      message: '¿Estás seguro de que deseas realizar esta acción?',
      confirmText: 'Sí, continuar',
      cancelText: 'Cancelar',
    );
    
    if (result && mounted) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Acción confirmada',
        isError: false,
      );
    }
  }
  
  void _showActionsModal() {
    final List<ModalAction> actions = [
      ModalAction(
        title: 'Editar',
        icon: Platform.isIOS ? CupertinoIcons.pencil : Icons.edit,
        onPressed: () {
          PlatformAlert.showNotification(
            context: context,
            message: 'Acción de editar seleccionada',
            isError: false,
          );
        },
      ),
      ModalAction(
        title: 'Compartir',
        icon: Platform.isIOS ? CupertinoIcons.share : Icons.share,
        onPressed: () {
          PlatformAlert.showNotification(
            context: context,
            message: 'Acción de compartir seleccionada',
            isError: false,
          );
        },
      ),
      ModalAction(
        title: 'Eliminar',
        icon: Platform.isIOS ? CupertinoIcons.delete : Icons.delete,
        isDestructive: true,
        onPressed: () {
          _showConfirmDialog();
        },
      ),
    ];
    
    PlatformModal.showActionsModal(
      context: context,
      title: 'Acciones disponibles',
      actions: actions,
      cancelText: 'Cancelar',
    );
  }
  
  void _showContentModal() {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformTextField(
          controller: _textController,
          placeholder: 'Ingrese texto aquí',
          label: 'Texto',
        ),
        const SizedBox(height: 16),
        PlatformButton(
          text: 'Enviar',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            if (_textController.text.isNotEmpty) {
              PlatformAlert.showNotification(
                context: context,
                message: 'Texto enviado: ${_textController.text}',
                isError: false,
              );
            }
          },
        ),
      ],
    );
    
    PlatformModal.showContentModal(
      context: context,
      title: 'Modal con contenido personalizado',
      content: content,
      cancelText: 'Cerrar',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      title: 'Ejemplos',
      hasGradientHeader: true,
      gradientSubtitle: 'Widgets adaptables para iOS y Android',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Botones'),
          PlatformButton(
            text: 'Botón primario',
            isPrimary: true,
            onPressed: () {
              PlatformAlert.showNotification(
                context: context,
                message: 'Botón primario presionado',
                isError: false,
              );
            },
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Botón secundario',
            isPrimary: false,
            onPressed: () {
              PlatformAlert.showNotification(
                context: context,
                message: 'Botón secundario presionado',
                isError: false,
              );
            },
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Botón con icono',
            isPrimary: true,
            icon: Platform.isIOS ? CupertinoIcons.star : Icons.star,
            onPressed: () {
              PlatformAlert.showNotification(
                context: context,
                message: 'Botón con icono presionado',
                isError: false,
              );
            },
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Botón destructivo',
            isDestructive: true,
            icon: Platform.isIOS ? CupertinoIcons.delete : Icons.delete,
            onPressed: () {
              _showConfirmDialog();
            },
          ),
          
          _buildSection('Campos de texto'),
          PlatformTextField(
            controller: _textController,
            label: 'Campo de texto',
            placeholder: 'Ingrese texto aquí',
            prefixIcon: Platform.isIOS ? CupertinoIcons.textformat : Icons.text_fields,
          ),
          const SizedBox(height: 16),
          PlatformTextField(
            label: 'Campo de contraseña',
            placeholder: 'Ingrese contraseña',
            obscureText: _obscureText,
            prefixIcon: Platform.isIOS ? CupertinoIcons.lock : Icons.lock,
            suffixIcon: _obscureText 
                ? (Platform.isIOS ? CupertinoIcons.eye : Icons.visibility) 
                : (Platform.isIOS ? CupertinoIcons.eye_slash : Icons.visibility_off),
            onSuffixIconPressed: _toggleObscureText,
          ),
          
          _buildSection('Alertas y diálogos'),
          PlatformButton(
            text: 'Mostrar alerta',
            onPressed: _showSimpleAlert,
            icon: Platform.isIOS ? CupertinoIcons.info : Icons.info,
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Mostrar diálogo de confirmación',
            onPressed: _showConfirmDialog,
            icon: Platform.isIOS ? CupertinoIcons.question : Icons.help,
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Mostrar notificación',
            onPressed: () {
              PlatformAlert.showNotification(
                context: context,
                message: 'Esta es una notificación de ejemplo',
                isError: false,
              );
            },
            icon: Platform.isIOS ? CupertinoIcons.bell : Icons.notifications,
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Mostrar error',
            onPressed: () {
              PlatformAlert.showNotification(
                context: context,
                message: 'Este es un mensaje de error de ejemplo',
                isError: true,
              );
            },
            icon: Platform.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error,
          ),
          
          _buildSection('Modales'),
          PlatformButton(
            text: 'Modal con acciones',
            onPressed: _showActionsModal,
            icon: Platform.isIOS ? CupertinoIcons.list_bullet : Icons.list,
          ),
          const SizedBox(height: 8),
          PlatformButton(
            text: 'Modal con contenido personalizado',
            onPressed: _showContentModal,
            icon: Platform.isIOS ? CupertinoIcons.doc_text : Icons.article,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Platform.isIOS 
                ? CupertinoColors.label 
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
} 