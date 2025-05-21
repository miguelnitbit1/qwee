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
import '../widgets/platform_scaffold.dart';
import '../utils/adaptive_colors.dart';

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
        
        // Usar PlatformScaffold para construir la pantalla
        return PlatformScaffold(
          title: 'Perfil',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildProfileContent(userProvider, themeProvider),
          ),
        );
      },
    );
  }
  
  // Widget central con el contenido común para ambas plataformas
  Widget _buildProfileContent(UserProvider userProvider, ThemeProvider themeProvider) {
    // Usamos la extensión de contexto para acceder a los colores adaptativos
    final colors = context.colors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen de perfil
        Center(
          child: _buildProfileImage(userProvider, colors),
        ),
        const SizedBox(height: 24),
        
        // Información personal
        _buildSectionTitle('Información Personal', colors),
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
                prefixIcon: Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
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
                prefixIcon: Platform.isIOS ? CupertinoIcons.person : Icons.person_outline,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Información de contacto
        _buildSectionTitle('Información de Contacto', colors),
        const SizedBox(height: 16),
        
        _buildContactInfo(userProvider, colors),
        
        const SizedBox(height: 32),
        
        // Preferencias
        _buildSectionTitle('Preferencias', colors),
        const SizedBox(height: 16),
        
        _buildPreferences(themeProvider, colors),
        
        const SizedBox(height: 32),
        
        // Botones de acción
        _buildActionButtons(),
      ],
    );
  }
  
  // Widget para el título de sección
  Widget _buildSectionTitle(String title, AdaptiveColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }
  
  // Widget para la imagen de perfil
  Widget _buildProfileImage(UserProvider userProvider, AdaptiveColors colors) {
    final isCupertino = Platform.isIOS;
    
    return Stack(
      children: [
        Hero(
          tag: 'profile_image',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.cardBorder,
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
              backgroundColor: colors.secondary,
              child: _imageFile == null && userProvider.userData?['profileImageUrl'] == null
                  ? Text(
                      userProvider.userData?['firstName']?.isNotEmpty == true
                          ? userProvider.userData?['firstName']?[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colors.onSecondary,
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
              color: colors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isCupertino
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      CupertinoIcons.camera,
                      color: colors.onPrimary,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                  )
                : IconButton(
                    icon: Icon(
                      Icons.camera_alt,
                      color: colors.onPrimary,
                      size: 20,
                    ),
                    onPressed: _pickImage,
                  ),
          ),
        ),
      ],
    );
  }
  
  // Widget para la información de contacto
  Widget _buildContactInfo(UserProvider userProvider, AdaptiveColors colors) {
    if (Platform.isIOS) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Platform.isIOS ? CupertinoIcons.mail : Icons.email_outlined,
              'Correo electrónico',
              userProvider.userData?['email'] ?? 'No disponible',
              colors,
            ),
            Divider(color: colors.divider),
            _buildInfoRow(
              Platform.isIOS ? CupertinoIcons.phone : Icons.phone_outlined,
              'Teléfono',
              userProvider.userData?['phone'] ?? 'No disponible',
              colors,
            ),
          ],
        ),
      );
    } else {
      return Card(
        color: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: colors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow(
                Icons.email_outlined,
                'Correo electrónico',
                userProvider.userData?['email'] ?? 'No disponible',
                colors,
              ),
              Divider(color: colors.divider),
              _buildInfoRow(
                Icons.phone_outlined,
                'Teléfono',
                userProvider.userData?['phone'] ?? 'No disponible',
                colors,
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // Widget para las preferencias
  Widget _buildPreferences(ThemeProvider themeProvider, AdaptiveColors colors) {
    final isCupertino = Platform.isIOS;
    
    if (isCupertino) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              themeProvider.isDarkMode
                  ? CupertinoIcons.moon_fill
                  : CupertinoIcons.sun_max_fill,
              color: colors.icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Oscuro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    themeProvider.isDarkMode
                        ? 'Cambiar a modo claro'
                        : 'Cambiar a modo oscuro',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
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
              activeColor: colors.primary,
            ),
          ],
        ),
      );
    } else {
      return Card(
        color: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: colors.cardBorder,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: colors.icon,
                ),
                title: Text(
                  'Modo Oscuro',
                  style: TextStyle(color: colors.textPrimary),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? 'Cambiar a modo claro'
                      : 'Cambiar a modo oscuro',
                  style: TextStyle(color: colors.textSecondary),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                  activeColor: colors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // Widget para los botones de acción
  Widget _buildActionButtons() {
    return Column(
      children: [
        PlatformButton(
          text: 'Actualizar perfil',
          isPrimary: true,
          onPressed: _updateProfile,
        ),
        
        const SizedBox(height: 16),
        
        PlatformButton(
          text: 'Cerrar sesión',
          isDestructive: true,
          icon: Platform.isIOS ? CupertinoIcons.power : Icons.logout,
          onPressed: _confirmSignOut,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AdaptiveColors colors) {
    if (Platform.isIOS) {
      return Row(
        children: [
          Icon(icon, color: colors.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return ListTile(
        leading: Icon(icon, color: colors.icon),
        title: Text(label, style: TextStyle(color: colors.textSecondary)),
        subtitle: Text(value, style: TextStyle(color: colors.textPrimary)),
      );
    }
  }
} 