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
  
  /// Si el botón debe ocupar todo el ancho disponible
  final bool expandWidth;
  
  /// Constructor
  const PlatformButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
    this.padding,
    this.expandWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Platform.isIOS
        ? _buildCupertinoButton(context)
        : _buildMaterialButton(context);
        
    // Si expandWidth es true, envolvemos el botón en un SizedBox para que ocupe todo el ancho
    return expandWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  /// Construye un botón estilo iOS
  Widget _buildCupertinoButton(BuildContext context) {
    // Determinar color según el tipo de botón
    Color? buttonColor;
    Color textColor = CupertinoTheme.of(context).primaryColor;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    if (isDestructive) {
      buttonColor = CupertinoColors.systemRed;
      textColor = CupertinoColors.white;
    } else if (isPrimary) {
      buttonColor = CupertinoTheme.of(context).primaryColor;
      textColor = CupertinoColors.white;
    } else {
      // Para botones no primarios, establecemos un color de fondo suave
      buttonColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF2F2F7);
    }
    
    // Armar widget de texto e icono si es necesario
    Widget child = Text(
      text,
      style: TextStyle(
        color: isPrimary || isDestructive 
            ? CupertinoColors.white 
            : textColor,
      ),
    );
    
    if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: 20,
            color: isPrimary || isDestructive 
                ? CupertinoColors.white 
                : textColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isPrimary || isDestructive 
                  ? CupertinoColors.white 
                  : textColor,
            ),
          ),
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
            ? WidgetStateProperty.all<EdgeInsetsGeometry>(padding!) 
            : null,
        minimumSize: WidgetStateProperty.all<Size>(
          const Size(88, 48), // Altura mínima
        ),
      ),
      child: child,
    );
  }
} 