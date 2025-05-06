import 'package:geolocator/geolocator.dart';

class Geocerca {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // Radio de la geocerca en metros

  Geocerca({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  // Método para calcular la distancia a otra geocerca
  double distanceTo(double userLatitude, double userLongitude) {
    // Implementar la fórmula de Haversine o usar un paquete como geolocator
    // para calcular la distancia entre dos puntos geográficos
    // Aquí puedes usar Geolocator para calcular la distancia
    return Geolocator.distanceBetween(userLatitude, userLongitude, latitude, longitude);
  }
}