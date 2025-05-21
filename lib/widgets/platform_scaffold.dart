import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Widget que implementa un Scaffold adaptado a la plataforma (iOS o Android)
class PlatformScaffold extends StatelessWidget {
  /// Título para la barra de navegación
  final String title;
  
  /// Contenido principal del scaffold
  final Widget body;
  
  /// Si se debe mostrar un botón de retroceso
  final bool showBackButton;
  
  /// Acciones adicionales para la barra de navegación
  final List<Widget>? actions;
  
  /// Widget para el botón flotante (solo para Material)
  final Widget? floatingActionButton;
  
  /// Si debe tener un gradiente en el header
  final bool hasGradientHeader;
  
  /// Color del gradiente
  final Color? gradientColor;
  
  /// Subtítulo para el header con gradiente
  final String? gradientSubtitle;
  
  /// Constructor
  const PlatformScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.actions,
    this.floatingActionButton,
    this.hasGradientHeader = false,
    this.gradientColor,
    this.gradientSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoScaffold(context)
        : _buildMaterialScaffold(context);
  }

  /// Construye un scaffold para iOS
  Widget _buildCupertinoScaffold(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: hasGradientHeader 
            ? (gradientColor ?? CupertinoColors.activeBlue) 
            : theme.barBackgroundColor,
        leading: showBackButton 
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              ) 
            : null,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con gradiente (opcional)
            if (hasGradientHeader) 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      gradientColor ?? CupertinoColors.activeBlue,
                      (gradientColor ?? CupertinoColors.activeBlue).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: gradientSubtitle != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gradientSubtitle!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            
            // Contenido principal
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye un scaffold para Material (Android)
  Widget _buildMaterialScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = gradientColor ?? theme.colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
      ),
      body: Column(
        children: [
          // Header con gradiente (opcional)
          if (hasGradientHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: gradientSubtitle != null
                  ? Text(
                      gradientSubtitle!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
            ),
          
          // Contenido principal
          Expanded(
            child: body,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
} 