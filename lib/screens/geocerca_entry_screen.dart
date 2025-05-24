import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/geocerca_provider.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_scaffold.dart';
import '../widgets/platform_alert.dart';
import '../utils/adaptive_colors.dart';
import 'geocerca_users_screen.dart';

class GeocercaEntryScreen extends StatefulWidget {
  const GeocercaEntryScreen({super.key});

  @override
  State<GeocercaEntryScreen> createState() => _GeocercaEntryScreenState();
}

class _GeocercaEntryScreenState extends State<GeocercaEntryScreen> {
  final _descriptionController = TextEditingController();
  File? _selfieImage;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _takeSelfie() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selfieImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error al tomar selfie: $e');
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al tomar la selfie: $e',
          isError: true,
        );
      }
    }
  }
  
  Future<void> _createTemporaryProfile() async {
    if (_selfieImage == null) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Por favor, toma una selfie primero',
        isError: true,
      );
      return;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      PlatformAlert.showNotification(
        context: context,
        message: 'Por favor, añade una descripción',
        isError: true,
      );
      return;
    }
    
    if (_descriptionController.text.length > 140) {
      PlatformAlert.showNotification(
        context: context,
        message: 'La descripción no puede superar los 140 caracteres',
        isError: true,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final geocercaProvider = Provider.of<GeocercaProvider>(context, listen: false);
      final success = await geocercaProvider.createTemporaryProfile(
        _descriptionController.text.trim(),
        _selfieImage!,
      );
      
      if (success && mounted) {
        // Navegar a la pantalla de usuarios en la geocerca
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GeocercaUsersScreen()),
        );
      } else if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error al crear el perfil temporal',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        PlatformAlert.showNotification(
          context: context,
          message: 'Error: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final geocercaProvider = Provider.of<GeocercaProvider>(context);
    final currentGeocerca = geocercaProvider.currentGeocerca;
    final colors = context.colors;
    final isIOS = Platform.isIOS;
    
    if (currentGeocerca == null) {
      // Si no hay geocerca, volver a la pantalla anterior
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).maybePop().then((success) {
            // Si no se pudo hacer pop (no hay navegación), volver a home
            if (!success && context.mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      });
      return const SizedBox.shrink();
    }
    
    return WillPopScope(
      onWillPop: () async {
        // Limpiar estado si el usuario decide volver atrás
        geocercaProvider.exitCurrentGeocerca();
        return true;
      },
      child: PlatformScaffold(
        title: currentGeocerca.name,
        body: Column(
          children: [
            // Contenido principal con scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Instrucciones
                    Text(
                      'Para conectar con otros usuarios en ${currentGeocerca.name}, crea un perfil temporal:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Selfie
                    GestureDetector(
                      onTap: _takeSelfie,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.cardBorder,
                          ),
                        ),
                        child: _selfieImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selfieImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isIOS ? CupertinoIcons.camera : Icons.camera_alt,
                                    size: 48,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Toca para tomar una selfie',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Campo de descripción
                    PlatformTextField(
                      controller: _descriptionController,
                      label: 'Descripción',
                      placeholder: 'Escribe algo sobre ti (máximo 140 caracteres)',
                      maxLength: 140,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones fijos en la parte inferior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón para crear perfil
                  PlatformButton(
                    text: _isLoading ? 'Creando perfil...' : 'Ingresar',
                    isPrimary: true,
                    onPressed: _isLoading ? null : _createTemporaryProfile,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón para cancelar
                  PlatformButton(
                    text: 'Cancelar',
                    isPrimary: false,
                    onPressed: () {
                      // Limpiar estado al cancelar
                      geocercaProvider.exitCurrentGeocerca();
                      // Navegación segura
                      if (context.mounted) {
                        Navigator.of(context).maybePop().then((success) {
                          // Si no se pudo hacer pop, volver a home
                          if (!success && context.mounted) {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 