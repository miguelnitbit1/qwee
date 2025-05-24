import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Clase para representar una acción en una alerta
class AlertAction {
  /// Texto de la acción
  final String text;
  
  /// Si la acción es la principal
  final bool isPrimary;
  
  /// Callback cuando se presiona la acción
  final VoidCallback onPressed;
  
  /// Constructor
  const AlertAction({
    required this.text,
    this.isPrimary = false,
    required this.onPressed,
  });
}

/// Clase de utilidad para mostrar alertas y diálogos adaptados a la plataforma
class PlatformAlert {
  
  /// Muestra un diálogo de alerta simple adaptado a la plataforma
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    List<AlertAction>? actions,
    String? okText,
  }) async {
    if (Platform.isIOS) {
      return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions != null && actions.isNotEmpty
              ? actions.map((action) {
                  return CupertinoDialogAction(
                    isDefaultAction: action.isPrimary,
                    onPressed: action.onPressed,
                    child: Text(action.text),
                  );
                }).toList()
              : [
                  CupertinoDialogAction(
                    child: Text(okText ?? 'OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions != null && actions.isNotEmpty 
              ? actions.map((action) {
                  return TextButton(
                    onPressed: action.onPressed,
                    style: action.isPrimary 
                        ? TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    child: Text(action.text),
                  );
                }).toList()
              : [
                  TextButton(
                    child: Text(okText ?? 'OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
        ),
      );
    }
  }
  
  /// Muestra un diálogo de confirmación adaptado a la plataforma
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    if (Platform.isIOS) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(cancelText ?? 'Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(confirmText ?? 'Confirmar'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return result ?? false;
    } else {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(cancelText ?? 'Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText ?? 'Confirmar'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
  }
  
  /// Muestra un diálogo de carga adaptado a la plataforma
  static Future<T> showLoadingDialog<T>({
    required BuildContext context,
    required Future<T> future,
    String? message,
  }) async {
    final loadingDialog = Platform.isIOS
        ? CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
          )
        : AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(message ?? 'Cargando...'),
                ),
              ],
            ),
          );

    // Mostrar el diálogo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => loadingDialog,
    );

    try {
      // Ejecutar la operación futura
      final result = await future;
      
      // Cerrar el diálogo si el contexto sigue siendo válido
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return result;
    } catch (e) {
      // Cerrar el diálogo si el contexto sigue siendo válido
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
  
  /// Muestra un snackbar o una alerta adaptada a la plataforma
  static void showNotification({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    if (Platform.isIOS) {
      // En iOS usamos un overlay temporal
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError 
                    ? CupertinoColors.systemRed 
                    : CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
      
      // Insertar y eliminar después de la duración
      Overlay.of(context).insert(overlay);
      Future.delayed(duration, () => overlay.remove());
    } else {
      // En Android usamos el SnackBar estándar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: isError 
              ? Colors.red 
              : Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
} 