import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'profile_screen.dart';
import 'chats_screen.dart';
import 'geocercas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _error;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const GeocercasScreen(),
    const ChatsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'No hay usuario autenticado';
        });
        return;
      }

      print('Inicializando datos para usuario: ${user.uid}');
      final userData = await _getUserData(user.uid);
      
      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al inicializar datos: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      print('Intentando obtener datos para el usuario: $uid');
      
      final docFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
          
      final doc = await docFuture.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('La conexión tardó demasiado');
        },
      );
      
      print('Documento obtenido, existe: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data();
        print('Datos obtenidos: $data');
        return data;
      } else {
        print('El documento no existe, creando uno nuevo...');
        final userData = {
          'firstName': 'Usuario',
          'lastName': '',
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'phone': '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        print('Creando documento con datos: $userData');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);
            
        final newDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
            
        return newDoc.data();
      }
    } catch (e, stackTrace) {
      print('Error al obtener datos: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeUserData();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Geocercas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Fecha no disponible';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 