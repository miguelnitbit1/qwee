import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../utils/adaptive_colors.dart';

/// Clase de utilidad para mostrar snackbars adaptados a la plataforma
class PlatformSnackbar {
  /// Muestra un snackbar adaptado a la plataforma
  static void show({
    required BuildContext context,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    final colors = context.colors;
    
    if (Platform.isIOS) {
      // En iOS usamos un overlay temporal al estilo de notificación
      // Crear la referencia del overlay fuera de su definición
      late final OverlayEntry overlayEntry;
      
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? colors.error : CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (actionLabel != null && onAction != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () {
                            overlayEntry.remove();
                            onAction();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Insertar y eliminar después de la duración
      Overlay.of(context).insert(overlayEntry);
      
      // Solo auto-remover si no hay acción o si hay acción pero también quieres auto-remover
      if (actionLabel == null || onAction == null) {
        Future.delayed(duration, () {
          // Verificar si el overlay sigue en el árbol antes de removerlo
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        });
      }
    } else {
      // En Android usamos el SnackBar estándar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: isError ? colors.error : colors.primary,
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction,
                  textColor: Colors.white,
                )
              : null,
        ),
      );
    }
  }
} 