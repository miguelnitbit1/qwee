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
  
  /// Si el contenido es scrollable (para aplicar efectos nativos)
  final bool isScrollable;
  
  /// Si la barra de navegación debe ser translúcida en iOS
  final bool hasTranslucentAppBar;
  
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
    this.isScrollable = true,
    this.hasTranslucentAppBar = true,
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
    final Color navBarColor = hasGradientHeader 
        ? (gradientColor ?? CupertinoColors.activeBlue).withOpacity(hasTranslucentAppBar ? 0.8 : 1.0) 
        : hasTranslucentAppBar
            ? theme.barBackgroundColor.withOpacity(0.8)
            : theme.barBackgroundColor;
    
    // Para iOS, usamos CupertinoPageScaffold con customización nativa
    return CupertinoPageScaffold(
      // Usar navigationBar con efectos nativos de iOS
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: navBarColor,
        // En iOS, el borde inferior es null para un efecto más translúcido
        border: hasTranslucentAppBar ? null : Border(bottom: BorderSide(color: CupertinoColors.separator)),
        transitionBetweenRoutes: true,
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
      // El fondo del CupertinoPageScaffold tiene blur nativo en iOS
      backgroundColor: CupertinoColors.systemBackground.withOpacity(hasTranslucentAppBar ? 0.95 : 1.0),
      child: _buildBody(context, true),
    );
  }
  
  /// Construye un scaffold para Material (Android)
  Widget _buildMaterialScaffold(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Usar configuración moderna de AppBar para Material 3
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBackButton,
        actions: actions,
        scrolledUnderElevation: isScrollable ? 4.0 : 0.0, // Sombra cuando se hace scroll
        backgroundColor: hasGradientHeader 
            ? (gradientColor ?? theme.colorScheme.primary)
            : theme.colorScheme.background,
        foregroundColor: hasGradientHeader 
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
      ),
      body: _buildBody(context, false),
      floatingActionButton: floatingActionButton,
    );
  }
  
  /// Construye el cuerpo del scaffold con el header opcional
  Widget _buildBody(BuildContext context, bool isIOS) {
    final isHeaderVisible = hasGradientHeader;
    
    // Si no hay header, simplemente devolvemos el body
    if (!isHeaderVisible) {
      return SafeArea(
        top: !isIOS, // En iOS, el CupertinoPageScaffold ya maneja el SafeArea
        child: body,
      );
    }
    
    // Si hay header, construimos una estructura con Column
    final theme = isIOS 
        ? CupertinoTheme.of(context) 
        : Theme.of(context);
    final primaryColor = gradientColor ?? 
        (isIOS ? CupertinoColors.activeBlue : Theme.of(context).colorScheme.primary);
    
    return SafeArea(
      top: !isIOS, // En iOS, el CupertinoPageScaffold ya maneja el SafeArea
      child: Column(
        children: [
          // Header con gradiente
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
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: gradientSubtitle != null
                ? Text(
                    gradientSubtitle!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isIOS ? CupertinoColors.white : Colors.white,
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
    );
  }
} 