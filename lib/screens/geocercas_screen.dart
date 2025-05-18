import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../models/geocerca_model.dart';
import '../mocks/geocercas_mocks.dart';
import '../providers/user_provider.dart';
import '../services/map_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_alert.dart';

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

  Future<void> _checkAndRequestPermissionIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
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
        final hasLocationPermission = userProvider.hasLocationPermission;
        print('Verificando permisos: ${hasLocationPermission}');
        if (!hasLocationPermission) {
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
      return Platform.isIOS
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            )
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
    }

    List<Geocerca> geocercas = getMockGeocercas();

    return Platform.isIOS
        ? _buildCupertinoLayout(userProvider, geocercas)
        : _buildMaterialLayout(userProvider, theme, geocercas);
  }
  
  Widget _buildCupertinoLayout(UserProvider userProvider, List<Geocerca> geocercas) {
    final hasPosition = userProvider.userPosition != null;
    final isPermanentlyDenied = userProvider.locationPermissionStatus?.isPermanentlyDenied ?? false;
    
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Geocercas'),
        backgroundColor: CupertinoColors.systemBlue,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header con gradiente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.systemBlue,
                    CupertinoColors.systemBlue.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explora zonas cercanas a tu ubicación',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: !hasPosition
                  ? _buildPermissionRequiredContent(userProvider, isPermanentlyDenied)
                  : _buildGeocercasList(userProvider, geocercas),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMaterialLayout(UserProvider userProvider, ThemeData theme, List<Geocerca> geocercas) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 135,
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
  
  Widget _buildPermissionRequiredContent(UserProvider userProvider, bool isPermanentlyDenied) {
    final isIOS = Platform.isIOS;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermanentlyDenied 
                  ? (isIOS ? CupertinoIcons.settings : Icons.settings)
                  : (isIOS ? CupertinoIcons.location_slash : Icons.location_off),
              size: 64,
              color: isIOS ? CupertinoColors.systemGrey : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Se requiere tu ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermanentlyDenied 
                  ? 'Has denegado permanentemente el acceso a tu ubicación. Por favor, actívalo en la configuración de tu dispositivo.'
                  : 'Para ver las geocercas cercanas, necesitamos acceder a tu ubicación actual.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PlatformButton(
              text: _requestingPermission
                  ? 'Solicitando...'
                  : isPermanentlyDenied 
                      ? 'Abrir configuración' 
                      : 'Activar ubicación',
              isPrimary: true,
              icon: _requestingPermission
                  ? (isIOS ? CupertinoIcons.hourglass : Icons.hourglass_empty)
                  : isPermanentlyDenied 
                      ? (isIOS ? CupertinoIcons.settings : Icons.settings)
                      : (isIOS ? CupertinoIcons.location : Icons.location_on),
              onPressed: _requestingPermission
                  ? null
                  : () {
                      if (isPermanentlyDenied) {
                        openAppSettings();
                      } else {
                        _checkAndRequestPermissionIfNeeded();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeocercasList(UserProvider userProvider, List<Geocerca> geocercas) {
    final position = userProvider.userPosition!;
    final isIOS = Platform.isIOS;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: geocercas.length,
      itemBuilder: (context, index) {
        final geocerca = geocercas[index];
        final distance = geocerca.distanceTo(
          position.latitude, 
          position.longitude
        ) / 1000; // Convertir a kilómetros
        
        if (isIOS) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey6,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showGeocercaOptions(context, geocerca, userProvider),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            geocerca.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Distancia: ${distance.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.location,
                      color: CupertinoColors.activeBlue,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                'Distancia: ${distance.toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(
                Icons.location_on,
                color: Colors.blue,
              ),
              onTap: () => _showGeocercaOptions(context, geocerca, userProvider),
            ),
          );
        }
      },
    );
  }

  void _showGeocercaOptions(BuildContext context, Geocerca geocerca, UserProvider userProvider) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(geocerca.name),
          actions: [
            CupertinoActionSheetAction(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.map, color: CupertinoColors.activeBlue),
                  SizedBox(width: 10),
                  Text('Abrir en mapa'),
                ],
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await MapService.openMapWithGeocerca(
                    geocerca,
                    currentPosition: userProvider.userPosition,
                  );
                } catch (e) {
                  if (context.mounted) {
                    PlatformAlert.showNotification(
                      context: context,
                      message: 'No se pudo abrir el mapa: $e',
                      isError: true,
                    );
                  }
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.info, color: CupertinoColors.activeBlue),
                  SizedBox(width: 10),
                  Text('Ver detalles'),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                // Aquí podrías navegar a una pantalla de detalles de la geocerca
              },
            ),
            CupertinoActionSheetAction(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, color: CupertinoColors.activeBlue),
                  SizedBox(width: 10),
                  Text('Compartir ubicación'),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
                // Implementar funcionalidad para compartir
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              Text(
                geocerca.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.map, color: Theme.of(context).colorScheme.primary),
                title: const Text('Abrir en mapa'),
                onTap: () async {
                  Navigator.pop(context); // Cerrar el modal
                  try {
                    await MapService.openMapWithGeocerca(
                      geocerca,
                      currentPosition: userProvider.userPosition,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      PlatformAlert.showNotification(
                        context: context,
                        message: 'No se pudo abrir el mapa: $e',
                        isError: true,
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                title: const Text('Ver detalles'),
                onTap: () {
                  Navigator.pop(context);
                  // Aquí podrías navegar a una pantalla de detalles de la geocerca
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                title: const Text('Compartir ubicación'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar funcionalidad para compartir
                },
              ),
            ],
          ),
        ),
      );
    }
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
                PlatformButton(
                  text: _requestingPermission
                      ? 'Solicitando...'
                      : isPermanentlyDenied 
                          ? 'Abrir configuración' 
                          : 'Activar ubicación',
                  isPrimary: true,
                  icon: _requestingPermission
                      ? Icons.hourglass_empty
                      : isPermanentlyDenied 
                          ? Icons.settings 
                          : Icons.location_on,
                  onPressed: _requestingPermission
                      ? null
                      : () {
                          if (isPermanentlyDenied) {
                            openAppSettings();
                          } else {
                            _checkAndRequestPermissionIfNeeded();
                          }
                        },
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
              onTap: () => _showGeocercaOptions(context, geocerca, userProvider),
            ),
          );
        },
        childCount: geocercas.length,
      ),
    );
  }
}