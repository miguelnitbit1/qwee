import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../models/geocerca_model.dart';
import '../mocks/geocercas_mocks.dart';
import '../providers/user_provider.dart';
import '../services/map_service.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_modal.dart';
import '../widgets/platform_scaffold.dart';

class GeocercasScreen extends StatefulWidget {
  const GeocercasScreen({super.key});

  @override
  State<GeocercasScreen> createState() => _GeocercasScreenState();
}

class _GeocercasScreenState extends State<GeocercasScreen> {
  @override
  void initState() {
    super.initState();
    // Verificar si necesitamos solicitar permiso al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('GeocercasScreen: Iniciando verificación de permisos en postFrameCallback');
      _checkAndRequestPermissionIfNeeded();
    });
  }

  Future<void> _checkAndRequestPermissionIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Si ya tenemos permiso y posición, no hacer nada
    if (userProvider.hasLocationPermission && userProvider.userPosition != null) {
      return;
    }
    
    // Solicitar permiso usando el método centralizado
    await userProvider.requestLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

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
    final hasPosition = userProvider.userPosition != null;
    final isPermanentlyDenied = userProvider.isPermanentlyDenied();

    return PlatformScaffold(
      title: 'Geocercas',
      hasGradientHeader: false,
      gradientColor: Platform.isIOS ? CupertinoColors.systemBlue : null,
      gradientSubtitle: 'Explora zonas cercanas a tu ubicación',
      body: hasPosition
          ? _buildGeocercasList(userProvider, geocercas)
          : _buildPermissionRequiredContent(userProvider, isPermanentlyDenied),
    );
  }
  
  // Widget para solicitar permisos de ubicación
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
              text: userProvider.isRequestingPermission
                  ? 'Solicitando...'
                  : isPermanentlyDenied 
                      ? 'Abrir configuración' 
                      : 'Activar ubicación',
              isPrimary: true,
              icon: userProvider.isRequestingPermission
                  ? (isIOS ? CupertinoIcons.hourglass : Icons.hourglass_empty)
                  : isPermanentlyDenied 
                      ? (isIOS ? CupertinoIcons.settings : Icons.settings)
                      : (isIOS ? CupertinoIcons.location : Icons.location_on),
              onPressed: userProvider.isRequestingPermission
                  ? null
                  : () async {
                      if (isPermanentlyDenied) {
                        await userProvider.openLocationSettings();
                      } else {
                        await userProvider.requestLocationPermission();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para mostrar la lista de geocercas
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
        
        return _buildGeocercaItem(context, geocerca, distance, userProvider);
      },
    );
  }
  
  // Widget para cada elemento de geocerca
  Widget _buildGeocercaItem(BuildContext context, Geocerca geocerca, double distance, UserProvider userProvider) {
    final isIOS = Platform.isIOS;
    
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
  }

  // Dialogo de opciones para una geocerca
  void _showGeocercaOptions(BuildContext context, Geocerca geocerca, UserProvider userProvider) {
    final List<ModalAction> actions = [
      ModalAction(
        title: 'Abrir en mapa',
        icon: Platform.isIOS ? CupertinoIcons.map : Icons.map,
        onPressed: () async {
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
      ModalAction(
        title: 'Ver detalles',
        icon: Platform.isIOS ? CupertinoIcons.info : Icons.info_outline,
        onPressed: () {
          // Aquí podrías navegar a una pantalla de detalles de la geocerca
        },
      ),
      ModalAction(
        title: 'Compartir ubicación',
        icon: Platform.isIOS ? CupertinoIcons.share : Icons.share,
        onPressed: () {
          // Implementar funcionalidad para compartir
        },
      ),
    ];
    
    PlatformModal.showActionsModal(
      context: context,
      title: geocerca.name,
      actions: actions,
      cancelText: 'Cancelar',
    );
  }
}