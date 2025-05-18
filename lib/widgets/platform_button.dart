import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Botón que se adapta automáticamente a la plataforma (iOS o Android)
class PlatformButton extends StatelessWidget {
  /// Callback cuando se presiona el botón
  final VoidCallback? onPressed;
  
  /// Texto del botón
  final String text;
  
  /// Si el botón es el principal (filled en iOS, primary en Material)
  final bool isPrimary;
  
  /// Si el botón es de tipo destructivo (rojo)
  final bool isDestructive;
  
  /// Icono opcional para mostrar antes del texto
  final IconData? icon;
  
  /// Padding personalizado
  final EdgeInsetsGeometry? padding;
  
  /// Constructor
  const PlatformButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoButton(context)
        : _buildMaterialButton(context);
  }

  /// Construye un botón estilo iOS
  Widget _buildCupertinoButton(BuildContext context) {
    // Determinar color según el tipo de botón
    Color? buttonColor;
    
    if (isDestructive) {
      buttonColor = CupertinoColors.systemRed;
    } else if (isPrimary) {
      buttonColor = CupertinoTheme.of(context).primaryColor;
    }
    
    // Armar widget de texto e icono si es necesario
    Widget child = Text(text);
    
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return isPrimary
        ? CupertinoButton.filled(
            padding: padding,
            onPressed: onPressed,
            disabledColor: CupertinoColors.systemGrey4,
            child: child,
          )
        : CupertinoButton(
            padding: padding,
            onPressed: onPressed,
            color: buttonColor,
            child: child,
          );
  }

  /// Construye un botón estilo Material
  Widget _buildMaterialButton(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determinar estilo según el tipo de botón
    ButtonStyle? buttonStyle;
    
    if (isDestructive) {
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );
    } else if (isPrimary) {
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    } else {
      buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
      );
    }
    
    // Armar widget de texto e icono si es necesario
    Widget child = Text(text);
    
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle.copyWith(
        padding: padding != null 
            ? MaterialStateProperty.all<EdgeInsetsGeometry>(padding!) 
            : null,
      ),
      child: child,
    );
  }
} 