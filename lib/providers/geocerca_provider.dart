import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../models/geocerca_model.dart';
import '../models/user_temporal_model.dart';
import '../mocks/geocercas_mocks.dart';
import '../mocks/chat_mocks.dart';

/// Provider para manejar la lógica de las geocercas
class GeocercaProvider with ChangeNotifier {
  // Propiedades principales
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  List<Geocerca> _geocercas = [];
  Map<String, UserTemporal> _temporaryUsers = {};
  Geocerca? _currentGeocerca;
  bool _isNavigating = false; // Bandera para controlar navegación
  
  // Usuario actual (si está dentro de una geocerca)
  UserTemporal? _currentUser;
  
  // Propiedades para solicitudes de chat
  final Map<String, List<ChatRequest>> _chatRequests = {};
  
  // Getters
  bool get isMonitoring => _isMonitoring;
  List<Geocerca> get geocercas => _geocercas;
  Geocerca? get currentGeocerca => _currentGeocerca;
  UserTemporal? get currentUser => _currentUser;
  bool get isNavigating => _isNavigating;
  
  // Setter para controlar navegación
  set isNavigating(bool value) {
    _isNavigating = value;
    notifyListeners();
  }
  
  // Obtener usuarios dentro de la geocerca actual
  List<UserTemporal> get usersInCurrentGeocerca {
    if (_currentGeocerca == null) return [];
    return _temporaryUsers.values
        .where((user) => user.geocercaId == _currentGeocerca!.id)
        .toList();
  }
  
  // Obtener solicitudes de chat para el usuario actual
  List<ChatRequest> get currentUserChatRequests {
    if (_currentUser == null) return [];
    return _chatRequests[_currentUser!.id] ?? [];
  }
  
  // Constructor
  GeocercaProvider() {
    _loadMockData();
  }
  
  // Método para simular entrada a una geocerca
  void simulateGeocercaEntry(Geocerca geocerca) {
    _currentGeocerca = geocerca;
    notifyListeners();
  }
  
  // Obtener un usuario temporal por ID
  UserTemporal? getUserById(String userId) {
    return _temporaryUsers[userId];
  }
  
  // Cargar datos mock
  void _loadMockData() {
    // Cargar geocercas
    _geocercas = getMockGeocercas();
    
    // Cargar algunos usuarios temporales mock
    final mockUsers = _generateMockTemporaryUsers();
    _temporaryUsers = {for (var user in mockUsers) user.id: user};
    
    // Inicializar mapa de solicitudes de chat
    for (var user in mockUsers) {
      _chatRequests[user.id] = [];
    }
    
    notifyListeners();
  }
  
  // Generar usuarios temporales mock
  List<UserTemporal> _generateMockTemporaryUsers() {
    // Utilizar datos de chat mock como base
    final permanentUsers = ChatMocks.permanentUsers;
    final List<UserTemporal> tempUsers = [];
    
    for (var i = 0; i < permanentUsers.length; i++) {
      final user = permanentUsers[i];
      
      // Asignar a una geocerca aleatoria
      final geocercaIndex = math.Random().nextInt(_geocercas.length);
      
      tempUsers.add(
        UserTemporal(
          id: 'temp_${user['id']}',
          firstName: user['firstName'],
          lastName: user['lastName'],
          profileImageUrl: user['imageUrl'],
          description: 'Descripción temporal de ${user['firstName']}',
          geocercaId: _geocercas[geocercaIndex].id,
          entryTime: DateTime.now().subtract(Duration(hours: math.Random().nextInt(5))),
        ),
      );
    }
    
    return tempUsers;
  }
  
  // Iniciar monitoreo de ubicación
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Simular actualizaciones de ubicación cada 10 segundos
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkGeocercas();
    });
    
    notifyListeners();
  }
  
  // Detener monitoreo
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    notifyListeners();
  }
  
  // Verificar si el usuario está dentro de alguna geocerca
  Future<void> _checkGeocercas() async {
    // En un caso real, obtendríamos la posición actual del usuario
    // Para mock, simulamos aleatoriamente entrada a geocercas
    if (_currentGeocerca == null && math.Random().nextInt(10) == 0) {
      // Reducimos la probabilidad (1 en 10) para hacer menos frecuentes las entradas aleatorias
      // Entrar a una geocerca aleatoria
      final geocercaIndex = math.Random().nextInt(_geocercas.length);
      _currentGeocerca = _geocercas[geocercaIndex];
      print('Usuario entró a la geocerca: ${_currentGeocerca!.name}');
      notifyListeners();
    }
  }
  
  // Crear perfil temporal al entrar a una geocerca
  Future<bool> createTemporaryProfile(String description, File selfieImage) async {
    if (_currentGeocerca == null) return false;
    
    try {
      // En un caso real, subiríamos la imagen a storage
      // Para mock, simplemente creamos el perfil
      _currentUser = UserTemporal(
        id: 'current_user_${DateTime.now().millisecondsSinceEpoch}',
        firstName: 'Usuario',
        lastName: 'Actual',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg', // URL de ejemplo
        description: description,
        geocercaId: _currentGeocerca!.id,
        entryTime: DateTime.now(),
      );
      
      // Agregar al mapa de usuarios temporales
      _temporaryUsers[_currentUser!.id] = _currentUser!;
      
      // Inicializar lista de solicitudes para este usuario
      _chatRequests[_currentUser!.id] = [];
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error al crear perfil temporal: $e');
      return false;
    }
  }
  
  // Enviar solicitud de chat a otro usuario
  Future<bool> sendChatRequest(String toUserId, String message) async {
    if (_currentUser == null) return false;
    
    try {
      final request = ChatRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        fromUserId: _currentUser!.id,
        toUserId: toUserId,
        message: message,
        timestamp: DateTime.now(),
      );
      
      // Agregar a la lista de solicitudes del destinatario
      if (_chatRequests.containsKey(toUserId)) {
        _chatRequests[toUserId]!.add(request);
      } else {
        _chatRequests[toUserId] = [request];
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error al enviar solicitud de chat: $e');
      return false;
    }
  }
  
  // Aceptar una solicitud de chat
  Future<bool> acceptChatRequest(String requestId) async {
    if (_currentUser == null) return false;
    
    try {
      final requests = _chatRequests[_currentUser!.id] ?? [];
      final requestIndex = requests.indexWhere((req) => req.id == requestId);
      
      if (requestIndex >= 0) {
        final request = requests[requestIndex];
        request.accepted = true;
        
        // En un caso real, crearíamos un chat en Firestore
        // La creación del chat ahora se maneja en ChatProvider
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al aceptar solicitud de chat: $e');
      return false;
    }
  }
  
  // Rechazar una solicitud de chat
  Future<bool> rejectChatRequest(String requestId) async {
    if (_currentUser == null) return false;
    
    try {
      final requests = _chatRequests[_currentUser!.id] ?? [];
      final requestIndex = requests.indexWhere((req) => req.id == requestId);
      
      if (requestIndex >= 0) {
        // Eliminar la solicitud
        requests.removeAt(requestIndex);
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al rechazar solicitud de chat: $e');
      return false;
    }
  }
  
  // Simular salida de geocerca
  void exitCurrentGeocerca() {
    // Solo notificar si realmente hay algo que limpiar
    if (_currentGeocerca != null || _currentUser != null || _isNavigating) {
      _currentGeocerca = null;
      _currentUser = null;
      _isNavigating = false;
      print('Saliendo de geocerca - Limpiando estado de navegación');
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

/// Clase para representar una solicitud de chat
class ChatRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String message;
  final DateTime timestamp;
  bool accepted;
  
  ChatRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.timestamp,
    this.accepted = false,
  });
  
  // Para serialización/deserialización
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'accepted': accepted,
    };
  }
  
  factory ChatRequest.fromMap(Map<String, dynamic> map) {
    return ChatRequest(
      id: map['id'],
      fromUserId: map['fromUserId'],
      toUserId: map['toUserId'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      accepted: map['accepted'] ?? false,
    );
  }
} 