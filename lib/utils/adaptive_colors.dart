import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Clase para manejar colores adaptativos entre plataformas
/// Esta clase proporciona colores que se adaptan automáticamente a:
/// 1. La plataforma (iOS o Android)
/// 2. El modo de tema (claro u oscuro)
class AdaptiveColors {
  final BuildContext context;
  
  AdaptiveColors(this.context);
  
  /// Verifica si estamos en modo oscuro
  bool get isDark {
    if (Platform.isIOS) {
      return CupertinoTheme.of(context).brightness == Brightness.dark;
    } else {
      return Theme.of(context).brightness == Brightness.dark;
    }
  }
  
  /// Color primario de la aplicación
  Color get primary {
    if (Platform.isIOS) {
      return CupertinoTheme.of(context).primaryColor;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
  
  /// Color secundario de la aplicación
  Color get secondary {
    if (Platform.isIOS) {
      return CupertinoTheme.of(context).primaryColor; // iOS suele usar el mismo color
    } else {
      return Theme.of(context).colorScheme.secondary;
    }
  }
  
  /// Color de fondo general de la aplicación
  Color get background {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF121212) : CupertinoColors.systemBackground;
    } else {
      return Theme.of(context).scaffoldBackgroundColor;
    }
  }
  
  /// Color de superficie para tarjetas y contenedores elevados
  Color get surface {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemBackground;
    } else {
      return isDark ? const Color(0xFF1E1E1E) : Colors.white;
    }
  }
  
  /// Color de fondo para tarjetas secundarias o contenedores
  Color get cardBackground {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF2C2C2C) : CupertinoColors.systemGrey6;
    } else {
      return isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!;
    }
  }
  
  /// Color para bordes de tarjetas y divisores
  Color get cardBorder {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF3C3C3C) : CupertinoColors.systemGrey4;
    } else {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }
  
  /// Color de texto principal
  Color get textPrimary {
    if (Platform.isIOS) {
      return isDark ? CupertinoColors.white : CupertinoColors.black;
    } else {
      return isDark ? Colors.white : Colors.black87;
    }
  }
  
  /// Color de texto secundario (subtítulos, descripciones)
  Color get textSecondary {
    if (Platform.isIOS) {
      return isDark ? CupertinoColors.systemGrey : CupertinoColors.secondaryLabel;
    } else {
      return isDark ? Colors.grey[400]! : Colors.grey[700]!;
    }
  }
  
  /// Color para textos sobre fondos con color primario
  Color get onPrimary {
    if (Platform.isIOS) {
      return CupertinoColors.white;
    } else {
      return Theme.of(context).colorScheme.onPrimary;
    }
  }
  
  /// Color para textos sobre fondos con color secundario
  Color get onSecondary {
    if (Platform.isIOS) {
      return CupertinoColors.white;
    } else {
      return Theme.of(context).colorScheme.onSecondary;
    }
  }
  
  /// Color para textos sobre superficies
  Color get onSurface {
    return textPrimary;
  }
  
  /// Color de error
  Color get error {
    if (Platform.isIOS) {
      return CupertinoColors.systemRed;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }
  
  /// Color para texto sobre color de error
  Color get onError {
    return Colors.white;
  }
  
  /// Color para íconos
  Color get icon {
    return primary;
  }
  
  /// Color para burbujas de chat propias
  Color get messageBubbleMe {
    if (Platform.isIOS) {
      return CupertinoColors.activeBlue;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
  
  /// Color para burbujas de chat ajenas
  Color get messageBubbleOther {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF2C2C2C) : CupertinoColors.systemGrey5;
    } else {
      return Theme.of(context).colorScheme.surfaceVariant;
    }
  }
  
  /// Color para texto en burbujas propias
  Color get messageTextMe {
    return Colors.white;
  }
  
  /// Color para texto en burbujas ajenas
  Color get messageTextOther {
    if (Platform.isIOS) {
      return isDark ? CupertinoColors.white : CupertinoColors.label;
    } else {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
  
  /// Color de divider/separador
  Color get divider {
    if (Platform.isIOS) {
      return isDark ? const Color(0xFF2C2C2C) : CupertinoColors.systemGrey4;
    } else {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }
}

/// Extensión para acceder a colores adaptativos directamente desde BuildContext
extension AdaptiveColorsExtension on BuildContext {
  /// Acceso directo a los colores adaptativos
  /// 
  /// Uso:
  /// ```dart
  /// color: context.colors.primary
  /// textColor: context.colors.textPrimary
  /// ```
  AdaptiveColors get colors => AdaptiveColors(this);
} 