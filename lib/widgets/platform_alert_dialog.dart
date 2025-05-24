import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../utils/adaptive_colors.dart';

/// Clase de utilidad para mostrar diálogos de confirmación adaptados a la plataforma
class PlatformAlertDialog {
  /// Muestra un diálogo de confirmación adaptado a la plataforma con botones personalizables
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    bool isDestructiveAction = false,
    Color? confirmColor,
  }) async {
    final colors = context.colors;
    final destructiveColor = isDestructiveAction ? colors.error : null;
    final buttonColor = confirmColor ?? (isDestructiveAction ? colors.error : colors.primary);
    
    if (Platform.isIOS) {
      // Diálogo estilo iOS
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: false,
              child: Text(cancelText ?? 'Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructiveAction,
              isDefaultAction: !isDestructiveAction,
              child: Text(confirmText ?? (isDestructiveAction ? 'Eliminar' : 'Aceptar')),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return result ?? false;
    } else {
      // Diálogo estilo Material
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText ?? 'Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText ?? (isDestructiveAction ? 'Eliminar' : 'Aceptar'),
                style: TextStyle(color: buttonColor),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
  }

  /// Método específico para diálogos de confirmación de eliminación
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
    String? title,
    String? message,
    String? cancelText,
    String? deleteText,
  }) async {
    return await show(
      context: context,
      title: title ?? 'Confirmar eliminación',
      message: message ?? '¿Estás seguro de que quieres eliminar $itemName?',
      cancelText: cancelText,
      confirmText: deleteText ?? 'Eliminar',
      isDestructiveAction: true,
    );
  }
} 