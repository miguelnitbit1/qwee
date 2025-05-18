import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Campo de texto que se adapta automáticamente a la plataforma (iOS o Android)
class PlatformTextField extends StatelessWidget {
  /// Controlador del campo de texto
  final TextEditingController? controller;
  
  /// Texto de placeholder o hint
  final String? placeholder;
  
  /// Texto de etiqueta (solo para Material)
  final String? label;
  
  /// Si el campo es obligatorio
  final bool isRequired;
  
  /// Función de validación personalizada
  final String? Function(String?)? validator;
  
  /// Tipo de teclado
  final TextInputType keyboardType;
  
  /// Si debe ocultar el texto (para contraseñas)
  final bool obscureText;
  
  /// Icono a mostrar al inicio del campo
  final IconData? prefixIcon;
  
  /// Icono a mostrar al final del campo
  final IconData? suffixIcon;
  
  /// Callback para el icono de sufijo
  final VoidCallback? onSuffixIconPressed;
  
  /// Callback cuando el texto cambia
  final Function(String)? onChanged;
  
  /// Callback cuando se envía (con la tecla enter)
  final Function(String)? onSubmitted;
  
  /// Si está en modo autofocus
  final bool autofocus;
  
  /// Constructor
  const PlatformTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.isRequired = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoTextField(context)
        : _buildMaterialTextField(context);
  }

  /// Construye un campo de texto estilo iOS
  Widget _buildCupertinoTextField(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDarkMode = cupertinoTheme.brightness == Brightness.dark;
    
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefix: prefixIcon != null 
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                prefixIcon,
                color: cupertinoTheme.primaryColor,
                size: 20,
              ),
            )
          : null,
      suffix: suffixIcon != null
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onSuffixIconPressed,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  suffixIcon,
                  color: cupertinoTheme.primaryColor,
                  size: 20,
                ),
              ),
            )
          : null,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF2C2C2C) 
            : CupertinoColors.extraLightBackgroundGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 0.5,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }

  /// Construye un campo de texto estilo Material
  Widget _buildMaterialTextField(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null 
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconPressed,
              ) 
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        if (validator != null) {
          return validator!(value);
        }
        return null;
      },
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }
} 