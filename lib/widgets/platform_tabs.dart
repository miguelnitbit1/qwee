import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../utils/adaptive_colors.dart';

/// Widget que implementa una barra de pestañas adaptada a la plataforma
class PlatformTabs extends StatefulWidget {
  /// Controlador de pestañas
  final TabController? tabController;
  
  /// Títulos de las pestañas
  final List<String> tabs;
  
  /// Widgets de contenido para cada pestaña
  final List<Widget> children;
  
  /// Índice inicial seleccionado
  final int initialIndex;
  
  /// Callback cuando cambia la pestaña seleccionada
  final Function(int)? onTabChanged;
  
  /// Constructor
  const PlatformTabs({
    super.key,
    this.tabController,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
    this.onTabChanged,
  }) : assert(tabs.length == children.length, 'El número de tabs debe ser igual al número de children');

  @override
  State<PlatformTabs> createState() => _PlatformTabsState();
}

class _PlatformTabsState extends State<PlatformTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Si no se proporciona un controlador, creamos uno
    _tabController = widget.tabController ?? 
        TabController(
          length: widget.tabs.length, 
          vsync: this,
          initialIndex: widget.initialIndex,
        );
        
    _tabController.addListener(_handleTabChange);
  }
  
  @override
  void dispose() {
    if (widget.tabController == null) {
      _tabController.dispose();
    }
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging || _currentIndex != _tabController.index) {
      setState(() {
        _currentIndex = _tabController.index;
      });
      
      if (widget.onTabChanged != null) {
        widget.onTabChanged!(_currentIndex);
      }
    }
  }
  
  void _onCupertinoTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Actualizamos el controlador si existe
    if (!_tabController.indexIsChanging) {
      _tabController.animateTo(index);
    }
    
    if (widget.onTabChanged != null) {
      widget.onTabChanged!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoTabs()
        : _buildMaterialTabs();
  }
  
  /// Construye pestañas para iOS usando CupertinoSegmentedControl
  Widget _buildCupertinoTabs() {
    // Usamos la extensión de contexto para acceder a los colores adaptativos
    final colors = context.colors;
    
    // Crear mapa para el segmented control
    final Map<int, Widget> segments = {};
    for (int i = 0; i < widget.tabs.length; i++) {
      segments[i] = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          widget.tabs[i],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: i == _currentIndex 
                ? colors.onPrimary
                : colors.textSecondary,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CupertinoSegmentedControl<int>(
              children: segments,
              groupValue: _currentIndex,
              onValueChanged: _onCupertinoTabChanged,
              selectedColor: colors.primary,
              unselectedColor: colors.cardBackground,
              borderColor: colors.isDark ? Colors.transparent : colors.primary.withOpacity(0.5),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.children[_currentIndex],
        ),
      ],
    );
  }
  
  /// Construye pestañas para Android usando TabBar
  Widget _buildMaterialTabs() {
    // Usamos la extensión de contexto para acceder a los colores adaptativos
    final colors = context.colors;
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: widget.tabs.map((title) => 
              Tab(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ).toList(),
            labelColor: colors.onPrimary,
            unselectedLabelColor: colors.textSecondary,
            indicator: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            splashBorderRadius: BorderRadius.circular(8),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.children,
          ),
        ),
      ],
    );
  }
} 