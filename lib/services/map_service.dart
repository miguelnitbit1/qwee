import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../models/geocerca_model.dart';

class MapService {
  /// Abre el mapa del sistema con la ubicación especificada
  static Future<bool> openMap(double latitude, double longitude, {String? label}) async {
    final String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude${label != null ? '&query_place_id=$label' : ''}';
    final Uri uri = Uri.parse(googleUrl);
    
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el mapa';
    }
  }

  /// Abre el mapa del sistema con indicaciones desde la ubicación actual hasta el destino
  static Future<bool> openMapWithDirections(double destinationLat, double destinationLng, {Position? currentPosition, String? destinationName}) async {
    String googleUrl;
    
    if (currentPosition != null) {
      googleUrl = 'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$destinationLat,$destinationLng&travelmode=driving';
    } else {
      googleUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving';
    }
    
    if (destinationName != null && destinationName.isNotEmpty) {
      googleUrl += '&destination_place_id=${Uri.encodeComponent(destinationName)}';
    }
    
    final Uri uri = Uri.parse(googleUrl);
    
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el mapa con direcciones';
    }
  }
  
  /// Abre el mapa con una geocerca específica
  static Future<bool> openMapWithGeocerca(Geocerca geocerca, {Position? currentPosition}) async {
    return openMapWithDirections(
      geocerca.latitude, 
      geocerca.longitude,
      currentPosition: currentPosition,
      destinationName: geocerca.name
    );
  }
} 