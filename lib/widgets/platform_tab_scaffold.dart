import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;

/// Modelo para representar una pestaña
class TabItem {
  /// Título de la pestaña
  final String title;
  
  /// Icono para la pestaña
  final IconData icon;
  
  /// Icono para la pestaña cuando está activa (opcional)
  final IconData? activeIcon;
  
  /// Contenido de la pestaña
  final Widget content;
  
  /// Constructor
  const TabItem({
    required this.title,
    required this.icon,
    this.activeIcon,
    required this.content,
  });
}

/// Widget que implementa un scaffold con pestañas adaptado a la plataforma
class PlatformTabScaffold extends StatefulWidget {
  /// Título para la barra de navegación
  final String title;
  
  /// Lista de pestañas a mostrar
  final List<TabItem> tabs;
  
  /// Índice de la pestaña seleccionada inicialmente
  final int initialTabIndex;
  
  /// Si se debe mostrar el título en la barra de navegación
  final bool showAppBarTitle;
  
  /// Acciones adicionales para la barra de navegación
  final List<Widget>? actions;
  
  /// Constructor
  const PlatformTabScaffold({
    super.key,
    required this.title,
    required this.tabs,
    this.initialTabIndex = 0,
    this.showAppBarTitle = true,
    this.actions,
  });

  @override
  State<PlatformTabScaffold> createState() => _PlatformTabScaffoldState();
}

class _PlatformTabScaffoldState extends State<PlatformTabScaffold> {
  late int _selectedTabIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }
  
  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoTabScaffold()
        : _buildMaterialTabScaffold();
  }

  /// Construye un scaffold con pestañas para iOS
  Widget _buildCupertinoTabScaffold() {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: widget.tabs.map((tab) => BottomNavigationBarItem(
          icon: Icon(tab.icon),
          activeIcon: tab.activeIcon != null ? Icon(tab.activeIcon) : null,
          label: tab.title,
        )).toList(),
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoPageScaffold(
          navigationBar: widget.showAppBarTitle
              ? CupertinoNavigationBar(
                  middle: Text(widget.title),
                  backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
                  trailing: widget.actions != null && widget.actions!.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions!,
                        )
                      : null,
                )
              : null,
          child: SafeArea(
            child: widget.tabs[index].content,
          ),
        );
      },
    );
  }
  
  /// Construye un scaffold con pestañas para Material (Android)
  Widget _buildMaterialTabScaffold() {
    return Scaffold(
      appBar: widget.showAppBarTitle
          ? AppBar(
              title: Text(widget.title),
              actions: widget.actions,
            )
          : null,
      body: widget.tabs[_selectedTabIndex].content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: _onTabSelected,
        destinations: widget.tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon),
          selectedIcon: tab.activeIcon != null ? Icon(tab.activeIcon) : null,
          label: tab.title,
        )).toList(),
      ),
    );
  }
} 