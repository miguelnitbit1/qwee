import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_alert.dart';

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
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al seleccionar imagen: $e',
          isError: true,
        );
      }
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
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al subir imagen: ${e.toString()}',
          isError: true,
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
      
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Perfil actualizado correctamente',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al actualizar perfil: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final bool confirmed = await PlatformAlert.showConfirmDialog(
      context: context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro que deseas cerrar tu sesión?',
      confirmText: 'Sí, cerrar sesión',
      cancelText: 'Cancelar',
    );

    if (confirmed && mounted) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Mostrar notificación si existe
        if (userProvider.notification != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PlatformAlert.showNotification(
              context: context,
              message: userProvider.notification!.message,
              isError: userProvider.notification!.isError,
            );
          });
        }

        if (userProvider.isLoading) {
          return Platform.isIOS
              ? const CupertinoPageScaffold(
                  child: Center(
                    child: CupertinoActivityIndicator(),
                  ),
                )
              : const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
        }

        final themeProvider = Provider.of<ThemeProvider>(context);
        final theme = Theme.of(context);

        return Platform.isIOS
            ? _buildCupertinoLayout(userProvider, themeProvider, theme)
            : _buildMaterialLayout(userProvider, themeProvider, theme);
      },
    );
  }

  Widget _buildCupertinoLayout(UserProvider userProvider, ThemeProvider themeProvider, ThemeData theme) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Perfil'),
            backgroundColor: CupertinoTheme.of(context).primaryColor.withOpacity(0.9),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen de perfil
                  Center(
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_image',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.systemGrey3,
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
                              backgroundColor: CupertinoColors.activeBlue,
                              child: _imageFile == null && userProvider.userData?['profileImageUrl'] == null
                                ? Text(
                                    userProvider.userData?['firstName']?.isNotEmpty == true
                                        ? userProvider.userData?['firstName']?[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.white,
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
                              color: CupertinoColors.activeBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.camera,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Información personal
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campos de texto
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PlatformTextField(
                          controller: _firstNameController,
                          label: 'Nombre',
                          placeholder: 'Ingrese su nombre',
                          prefixIcon: CupertinoIcons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        PlatformTextField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          placeholder: 'Ingrese su apellido',
                          prefixIcon: CupertinoIcons.person,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Información de contacto
                  const Text(
                    'Información de Contacto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          CupertinoIcons.mail,
                          'Correo electrónico',
                          userProvider.userData?['email'] ?? 'No disponible',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          CupertinoIcons.phone,
                          'Teléfono',
                          userProvider.userData?['phone'] ?? 'No disponible',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Preferencias
                  const Text(
                    'Preferencias',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modo Oscuro',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                themeProvider.isDarkMode
                                    ? 'Cambiar a modo claro'
                                    : 'Cambiar a modo oscuro',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            themeProvider.setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botones
                  PlatformButton(
                    text: 'Actualizar perfil',
                    isPrimary: true,
                    onPressed: _updateProfile,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  PlatformButton(
                    text: 'Cerrar sesión',
                    isDestructive: true,
                    icon: CupertinoIcons.power,
                    onPressed: _confirmSignOut,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialLayout(UserProvider userProvider, ThemeProvider themeProvider, ThemeData theme) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                        PlatformTextField(
                          controller: _firstNameController,
                          label: 'Nombre',
                          placeholder: 'Ingrese su nombre',
                          prefixIcon: Icons.person_outline,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PlatformTextField(
                          controller: _lastNameController,
                          label: 'Apellido',
                          placeholder: 'Ingrese su apellido',
                          prefixIcon: Icons.person_outline,
                          isRequired: true,
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
                        const SizedBox(height: 24),
                        PlatformButton(
                          text: 'Cerrar sesión',
                          isDestructive: true,
                          icon: Icons.logout,
                          onPressed: _confirmSignOut,
                        ),
                        const SizedBox(height: 60), // Espacio para el botón fijo
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Botón fijo en la parte inferior de la pantalla (solo para Material)
          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: PlatformButton(
              text: 'Actualizar perfil',
              isPrimary: true,
              onPressed: _updateProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Platform.isIOS 
        ? Row(
            children: [
              Icon(icon, color: CupertinoTheme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
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
          )
        : ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(label),
            subtitle: Text(value),
          );
  }
} 