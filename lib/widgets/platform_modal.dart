import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

class ModalAction {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  ModalAction({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// Widget que muestra un modal adaptado a la plataforma (iOS o Android)
class PlatformModal {
  /// Muestra un modal de acciones adaptado a la plataforma
  static Future<void> showActionsModal({
    required BuildContext context,
    required String title,
    required List<ModalAction> actions,
    String? cancelText,
  }) async {
    if (Platform.isIOS) {
      return _showCupertinoModal(
        context: context,
        title: title,
        actions: actions,
        cancelText: cancelText ?? 'Cancelar',
      );
    } else {
      return _showMaterialModal(
        context: context,
        title: title,
        actions: actions,
        cancelText: cancelText,
      );
    }
  }

  /// Muestra un modal con contenido personalizado adaptado a la plataforma
  static Future<void> showContentModal({
    required BuildContext context,
    required String title,
    required Widget content,
    String? cancelText,
  }) async {
    if (Platform.isIOS) {
      return showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          message: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: content,
          ),
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText ?? 'Cerrar'),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Para que el modal pueda crecer según el contenido
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMaterialModalHandle(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              content,
              const SizedBox(height: 16),
              if (cancelText != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(cancelText),
                ),
            ],
          ),
        ),
      );
    }
  }

  // Implementación de modal para iOS
  static Future<void> _showCupertinoModal({
    required BuildContext context,
    required String title,
    required List<ModalAction> actions,
    required String cancelText,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            isDestructiveAction: action.isDestructive,
            onPressed: () {
              Navigator.pop(context);
              action.onPressed();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: action.isDestructive
                      ? CupertinoColors.destructiveRed
                      : CupertinoColors.activeBlue,
                ),
                const SizedBox(width: 10),
                Text(action.title),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(cancelText),
        ),
      ),
    );
  }

  // Implementación de modal para Android
  static Future<void> _showMaterialModal({
    required BuildContext context,
    required String title,
    required List<ModalAction> actions,
    String? cancelText,
  }) {
    final theme = Theme.of(context);
    
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMaterialModalHandle(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...actions.map((action) {
              return ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive
                      ? Colors.red
                      : theme.colorScheme.primary,
                ),
                title: Text(
                  action.title,
                  style: TextStyle(
                    color: action.isDestructive ? Colors.red : null,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  action.onPressed();
                },
              );
            }),  
          ],
        ),
      ),
    );
  }
  
  // Helper para construir el indicador de arrastre del modal en Material
  static Widget _buildMaterialModalHandle() {
    return Container(
      width: 50,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 20),
    );
  }
}
