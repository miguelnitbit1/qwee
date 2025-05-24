import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/geocerca_provider.dart';
import '../utils/adaptive_colors.dart';
import '../screens/geocerca_users_screen.dart';

/// Widget que muestra un indicador cuando el usuario está dentro de una geocerca
class GeocercaIndicator extends StatelessWidget {
  const GeocercaIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final geocercaProvider = Provider.of<GeocercaProvider>(context);
    final currentGeocerca = geocercaProvider.currentGeocerca;
    final currentUser = geocercaProvider.currentUser;
    final colors = context.colors;
    
    // Solo mostrar si el usuario está dentro de una geocerca y tiene perfil temporal
    if (currentGeocerca == null || currentUser == null) {
      return const SizedBox.shrink();
    }
    
    // Calcular cuántas solicitudes pendientes tiene
    final pendingRequests = geocercaProvider.currentUserChatRequests
        .where((req) => !req.accepted)
        .length;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GeocercaUsersScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(
                Platform.isIOS ? CupertinoIcons.location_fill : Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'En ${currentGeocerca.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (pendingRequests > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingRequests',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Platform.isIOS ? CupertinoIcons.chevron_right : Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 