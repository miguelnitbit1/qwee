import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/notification_message.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class UserProvider with ChangeNotifier {
  User? _firebaseUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  NotificationMessage? _notification;
  Position? _userPosition;
  Timer? _locationTimer;
  bool _hasLocationPermission = false;
  PermissionStatus? _locationPermissionStatus;

  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  NotificationMessage? get notification => _notification;
  Position? get userPosition => _userPosition;
  bool get hasLocationPermission => _hasLocationPermission;
  PermissionStatus? get locationPermissionStatus => _locationPermissionStatus;

  UserProvider() {
    _initializeUser();
    // Registro para el ciclo de vida de la app
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  // Manejar reanudación de la app - solo actualizar la ubicación si ya tiene permiso
  void onAppResume() {
    print('App resumed - Actualizando estado de permisos y ubicación');
    _updatePermissionStatus();
  }

  Future<void> _initializeUser() async {
    try {
      // Solo verificar el estado del permiso, no solicitarlo
      await _updatePermissionStatus();
      
      // Escuchar cambios en el estado de autenticación
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        _firebaseUser = user;
        if (user != null) {
          await _loadUserData();
          // Si ya tiene permiso, obtener ubicación
          if (_hasLocationPermission) {
            await _getUserLocation();
          }
        } else {
          _userData = null;
          _stopLocationUpdates();
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print('Error al inicializar usuario: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Actualizar el estado del permiso sin solicitar
  Future<void> _updatePermissionStatus() async {
    try {
      final status = await Permission.location.status;
      _locationPermissionStatus = status;
      _hasLocationPermission = status.isGranted;
      
      print('Estado de permiso actualizado: ${status.name}');
      
      // Si tiene permiso, actualizar ubicación
      if (_hasLocationPermission && _userPosition == null) {
        await _getUserLocation();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error al verificar estado de permisos: $e');
    }
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(this));
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Intentando cargar datos del usuario: ${_firebaseUser?.uid}');

      if (_firebaseUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser?.uid)
          .get();


      print('Respuesta de Firestore: ${doc.exists ? 'Documento existe' : 'Documento no existe'}');
      print('Datos obtenidos: ${doc.data()}');

      if (doc.exists) {
        _userData = doc.data();
        print('Datos del usuario actualizados: $_userData');
      } else {
        print('Creando nuevo documento para el usuario');
        final userData = {
          'firstName': 'Usuario',
          'lastName': '',
          'email': _firebaseUser?.email ?? '',
          'phone': '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser?.uid)
            .set(userData);
            
        _userData = userData;
        print('Nuevo documento creado con datos: $_userData');
      }
      
      _error = null;
    } catch (e, stackTrace) {
      print('Error al cargar datos del usuario: $e');
      print('Stack trace: $stackTrace');
      _error = e.toString();
      showNotification('Error al cargar datos: $e', isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _userData = null;
    notifyListeners();
  }

  // Método para actualizar datos del usuario
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser?.uid)
          .update(newData);
      
      _userData = {...?_userData, ...newData};
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Método para mostrar notificaciones
  void showNotification(String message, {bool isError = false}) {
    _notification = NotificationMessage(message: message, isError: isError);
    notifyListeners();
    // Limpiar la notificación después de mostrarla
    Future.delayed(const Duration(seconds: 3), () {
      _notification = null;
      notifyListeners();
    });
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (_firebaseUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(_firebaseUser!.uid)
          .child('profile.jpg');

      try {
        await storageRef.putString('');
      } catch (e) {
        print('Error al crear directorio: $e');
      }

      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': _firebaseUser!.uid,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      if (uploadTask.state == TaskState.success) {
        final downloadURL = await uploadTask.ref.getDownloadURL();
        return downloadURL;
      } else {
        throw Exception('Error al subir la imagen: ${uploadTask.state}');
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      showNotification('Error al subir la imagen: ${e.toString()}', isError: true);
      return null;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firebaseUser == null) {
        throw Exception('Usuario no autenticado');
      }

      String? newImageUrl = _userData?['profileImageUrl'];
      if (imageFile != null) {
        newImageUrl = await uploadProfileImage(imageFile);
      }

      final updateData = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update(updateData);

      _userData = {...?_userData, ...updateData};
      showNotification('Perfil actualizado correctamente');
    } catch (e) {
      showNotification('Error al actualizar perfil: $e', isError: true);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getUserLocation() async {
    if (!_hasLocationPermission) return;
    
    try {
      print('Obteniendo ubicación actual...');
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      print('Ubicación obtenida: ${_userPosition?.latitude}, ${_userPosition?.longitude}');
      _error = null;
      
      // Iniciar actualizaciones periódicas
      _startPeriodicLocationUpdates();
      
      notifyListeners();
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      _error = 'Error al obtener la ubicación: $e';
      notifyListeners();
    }
  }

  void _startPeriodicLocationUpdates() {
    if (_locationTimer != null) return;
    
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_hasLocationPermission) {
        print('Actualización periódica de ubicación');
        await _getUserLocation();
      } else {
        timer.cancel();
        _locationTimer = null;
      }
    });
  }

  // Método para forzar una actualización de ubicación (para botón en UI)
  Future<void> refreshLocation() async {
    try {
      if (!_hasLocationPermission) {
        print('No hay permisos para actualizar ubicación');
        return;
      }
      
      _isLoading = true;
      notifyListeners();
      
      await _getUserLocation();
    } catch (e) {
      _error = 'Error al actualizar ubicación: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Para uso desde GeocercasScreen
  Future<bool> handleLocationPermission() async {
    try {
      // Verificar primero el estado actual
      await _updatePermissionStatus();
      
      // Si ya tiene permiso, simplemente actualizar la ubicación
      if (_hasLocationPermission) {
        await _getUserLocation();
        return true;
      }
      
      // No solicitar permiso aquí, dejarlo a la pantalla
      return false;
    } catch (e) {
      print('Error en handleLocationPermission: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Este método se llamará después de que la pantalla solicite y obtenga el permiso
  Future<void> onPermissionGranted() async {
    try {
      _hasLocationPermission = true;
      await _getUserLocation();
      // Iniciar actualizaciones periódicas
      _startPeriodicLocationUpdates();
      notifyListeners();
    } catch (e) {
      print('Error en onPermissionGranted: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
}

// Clase para observar el ciclo de vida de la app
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final UserProvider provider;
  
  _AppLifecycleObserver(this.provider);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      provider.onAppResume();
    }
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AppLifecycleObserver && other.provider == provider;
  }
  
  @override
  int get hashCode => provider.hashCode;
}