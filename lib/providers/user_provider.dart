import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/notification_message.dart';

class UserProvider with ChangeNotifier {
  User? _firebaseUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  NotificationMessage? _notification;

  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  NotificationMessage? get notification => _notification;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // Escuchar cambios en el estado de autenticación
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserData();
      } else {
        _userData = null;
      }
      _isLoading = false;
      notifyListeners();
    });
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
}