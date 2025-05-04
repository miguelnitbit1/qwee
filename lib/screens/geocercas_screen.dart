import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/geocerca_model.dart';
import '../mocks/geocercas_mocks.dart';
import '../providers/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class GeocercasScreen extends StatefulWidget {
  const GeocercasScreen({super.key});

  @override
  State<GeocercasScreen> createState() => _GeocercasScreenState();
}

class _GeocercasScreenState extends State<GeocercasScreen> {
  bool _requestingPermission = false;

  @override
  void initState() {
    super.initState();
    // Verificar si necesitamos solicitar permiso al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissionIfNeeded();
    });
  }

  // Función más eficiente para verificar y solicitar permiso solo si es necesario
  Future<void> _checkAndRequestPermissionIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Si ya estamos solicitando el permiso, evitar llamadas duplicadas
    if (_requestingPermission) return;
    
    // Si ya tenemos permiso y posición, no hacer nada
    if (userProvider.hasLocationPermission && userProvider.userPosition != null) {
      return;
    }
    
    // Si no tenemos el permiso, solicitarlo
    if (!userProvider.hasLocationPermission) {
      setState(() => _requestingPermission = true);
      
      try {
        // Verificar si está permanentemente denegado
        final isPermanentlyDenied = userProvider.locationPermissionStatus?.isPermanentlyDenied ?? false;
        
        if (!isPermanentlyDenied) {
          print('Solicitando permiso desde la pantalla GeocercasScreen');
          final status = await Permission.location.request();
          
          if (status.isGranted) {
            print('Permiso concedido, notificando al provider');
            await userProvider.onPermissionGranted();
          }
        }
      } catch (e) {
        print('Error al solicitar permiso: $e');
      } finally {
        setState(() => _requestingPermission = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Geocerca> geocercas = getMockGeocercas();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Indicador de estado de ubicación
                      // _buildLocationStatusIndicator(userProvider, theme),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Lado izquierdo - Título y subtítulo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Geocercas',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Explora zonas cercanas a tu ubicación',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: _buildContentSection(userProvider, theme, geocercas),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatusIndicator(UserProvider userProvider, ThemeData theme) {
    final hasPermission = userProvider.hasLocationPermission;
    final hasPosition = userProvider.userPosition != null;
    final isPermanentlyDenied = userProvider.locationPermissionStatus?.isPermanentlyDenied ?? false;
    
    return InkWell(
      onTap: _requestingPermission 
          ? null 
          : () {
              if (isPermanentlyDenied) {
                openAppSettings();
              } else if (!hasPermission) {
                _checkAndRequestPermissionIfNeeded();
              } else if (!hasPosition) {
                userProvider.refreshLocation();
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasPosition
              ? Colors.green.withOpacity(0.3)
              : _requestingPermission
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _requestingPermission
                  ? Icons.access_time
                  : hasPosition 
                      ? Icons.check_circle 
                      : isPermanentlyDenied
                          ? Icons.settings
                          : Icons.warning,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _requestingPermission
                  ? 'Solicitando permiso...'
                  : hasPosition
                      ? 'Ubicación activa'
                      : isPermanentlyDenied
                          ? 'Abrir configuración'
                          : 'Activar ubicación',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(UserProvider userProvider, ThemeData theme, List<Geocerca> geocercas) {
    final hasPosition = userProvider.userPosition != null;
    final isPermanentlyDenied = userProvider.locationPermissionStatus?.isPermanentlyDenied ?? false;
    
    if (!hasPosition) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPermanentlyDenied ? Icons.settings : Icons.location_off,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Se requiere tu ubicación',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isPermanentlyDenied 
                      ? 'Has denegado permanentemente el acceso a tu ubicación. Por favor, actívalo en la configuración de tu dispositivo.'
                      : 'Para ver las geocercas cercanas, necesitamos acceder a tu ubicación actual.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _requestingPermission
                      ? null
                      : () {
                          if (isPermanentlyDenied) {
                            openAppSettings();
                          } else {
                            _checkAndRequestPermissionIfNeeded();
                          }
                        },
                  icon: Icon(_requestingPermission
                      ? Icons.hourglass_empty
                      : isPermanentlyDenied 
                          ? Icons.settings 
                          : Icons.location_on),
                  label: Text(_requestingPermission
                      ? 'Solicitando...'
                      : isPermanentlyDenied 
                          ? 'Abrir configuración' 
                          : 'Activar ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final geocerca = geocercas[index];
          final position = userProvider.userPosition!;
          final distance = geocerca.distanceTo(
            position.latitude, 
            position.longitude
          ) / 1000; // Convertir a kilómetros
          
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                geocerca.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Distancia: ${distance.toStringAsFixed(2)} km',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
              ),
              onTap: () {
                // Aquí puedes agregar la lógica para manejar el tap en la geocerca
              },
            ),
          );
        },
        childCount: geocercas.length,
      ),
    );
  }
}