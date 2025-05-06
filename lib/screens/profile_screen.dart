import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;


  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _firstNameController.text = userProvider.userData?['firstName'] ?? '';
    _lastNameController.text = userProvider.userData?['lastName'] ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile.jpg');

      try {
        await storageRef.putString('');
      } catch (e) {
        print('Error al crear directorio: $e');
      }

      final uploadTask = await storageRef.putFile(
        _imageFile!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        imageFile: _imageFile,
      );
    } catch (e) {
      // El provider ya maneja la notificación de error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Mostrar notificación si existe
        if (userProvider.notification != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userProvider.notification!.message),
                backgroundColor: userProvider.notification!.isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            );
          });
        }

        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final themeProvider = Provider.of<ThemeProvider>(context);
        final theme = Theme.of(context);

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
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Stack(
                            children: [
                              Hero(
                                tag: 'profile_image',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _imageFile != null
                                        ? FileImage(_imageFile!)
                                        : userProvider.userData?['profileImageUrl'] != null
                                            ? NetworkImage(userProvider.userData?['profileImageUrl']!)
                                            : null as ImageProvider?,
                                    backgroundColor: theme.colorScheme.secondary,
                                    child: _imageFile == null && userProvider.userData?['profileImageUrl'] == null
                                        ? Text(
                                            userProvider.userData?['firstName']?.isNotEmpty == true
                                                ? userProvider.userData?['firstName']?[0].toUpperCase()
                                                : '?',
                                            style: theme.textTheme.headlineLarge?.copyWith(
                                              color: theme.colorScheme.onSecondary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: theme.colorScheme.onSecondary,
                                    ),
                                    onPressed: _pickImage,
                                  ),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información Personal',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: theme.iconTheme.color,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su apellido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Información de Contacto',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.email_outlined,
                                  'Correo electrónico',
                                  userProvider.userData?['email'] ?? 'No disponible',
                                ),
                                const Divider(),
                                _buildInfoRow(
                                  Icons.phone_outlined,
                                  'Teléfono',
                                  userProvider.userData?['phone'] ?? 'No disponible',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Preferencias',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: theme.colorScheme.primary,
                                  ),
                                  title: Text(
                                    'Modo Oscuro',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  subtitle: Text(
                                    themeProvider.isDarkMode
                                        ? 'Cambiar a modo claro'
                                        : 'Cambiar a modo oscuro',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (bool value) {
                                      themeProvider.setThemeMode(
                                        value ? ThemeMode.dark : ThemeMode.light,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _updateProfile,
                            child: const Text('Actualizar perfil'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text('Cerrar sesión'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 