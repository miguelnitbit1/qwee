import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../widgets/platform_alert.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_text_field.dart';

/// Pantalla de ejemplo que muestra los componentes adaptados a cada plataforma
class PlatformExampleScreen extends StatefulWidget {
  const PlatformExampleScreen({super.key});

  @override
  State<PlatformExampleScreen> createState() => _PlatformExampleScreenState();
}

class _PlatformExampleScreenState extends State<PlatformExampleScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _obscureText = true;
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _buildCupertinoLayout()
        : _buildMaterialLayout();
  }
  
  /// Construye el layout para iOS
  Widget _buildCupertinoLayout() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ejemplos de Plataforma'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                'Ejemplos de Componentes iOS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              _buildSection('Campos de Texto'),
              const SizedBox(height: 16),
              PlatformTextField(
                controller: _textController,
                placeholder: 'Nombre de usuario',
                prefixIcon: CupertinoIcons.person,
              ),
              const SizedBox(height: 16),
              PlatformTextField(
                placeholder: 'Contraseña',
                prefixIcon: CupertinoIcons.lock,
                suffixIcon: _obscureText 
                    ? CupertinoIcons.eye 
                    : CupertinoIcons.eye_slash,
                onSuffixIconPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                obscureText: _obscureText,
              ),
              
              const SizedBox(height: 24),
              _buildSection('Botones'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Botón Normal',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Botón Primario',
                      isPrimary: true,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Eliminar',
                      isDestructive: true,
                      icon: CupertinoIcons.delete,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildSection('Diálogos y Alertas'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Mostrar Alerta',
                      onPressed: () {
                        PlatformAlert.showAlert(
                          context: context,
                          title: 'Alerta',
                          message: 'Este es un mensaje de alerta.',
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Mostrar Confirmación',
                      isPrimary: true,
                      onPressed: () async {
                        final result = await PlatformAlert.showConfirmDialog(
                          context: context,
                          title: 'Confirmación',
                          message: '¿Estás seguro de realizar esta acción?',
                          confirmText: 'Sí, continuar',
                          cancelText: 'No, cancelar',
                        );
                        
                        if (context.mounted) {
                          PlatformAlert.showNotification(
                            context: context,
                            message: result 
                                ? 'Acción confirmada' 
                                : 'Acción cancelada',
                            isError: !result,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Mostrar Carga',
                      onPressed: () {
                        PlatformAlert.showLoadingDialog(
                          context: context,
                          future: Future.delayed(
                            const Duration(seconds: 2), 
                            () => 'Operación completada'
                          ),
                          message: 'Procesando...',
                        ).then((result) {
                          if (context.mounted) {
                            PlatformAlert.showNotification(
                              context: context,
                              message: result,
                            );
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PlatformButton(
                      text: 'Mostrar Notificación',
                      isPrimary: true,
                      onPressed: () {
                        PlatformAlert.showNotification(
                          context: context,
                          message: 'Esta es una notificación de ejemplo',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construye el layout para Android
  Widget _buildMaterialLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplos de Plataforma'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Ejemplos de Componentes Material',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            _buildSection('Campos de Texto'),
            const SizedBox(height: 16),
            PlatformTextField(
              controller: _textController,
              label: 'Nombre de usuario',
              placeholder: 'Ingresa tu nombre de usuario',
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            PlatformTextField(
              label: 'Contraseña',
              placeholder: 'Ingresa tu contraseña',
              prefixIcon: Icons.lock,
              suffixIcon: _obscureText ? Icons.visibility : Icons.visibility_off,
              onSuffixIconPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              obscureText: _obscureText,
            ),
            
            const SizedBox(height: 24),
            _buildSection('Botones'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Botón Normal',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Botón Primario',
                    isPrimary: true,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Eliminar',
                    isDestructive: true,
                    icon: Icons.delete,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSection('Diálogos y Alertas'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Mostrar Alerta',
                    onPressed: () {
                      PlatformAlert.showAlert(
                        context: context,
                        title: 'Alerta',
                        message: 'Este es un mensaje de alerta.',
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Mostrar Confirmación',
                    isPrimary: true,
                    onPressed: () async {
                      final result = await PlatformAlert.showConfirmDialog(
                        context: context,
                        title: 'Confirmación',
                        message: '¿Estás seguro de realizar esta acción?',
                        confirmText: 'Sí, continuar',
                        cancelText: 'No, cancelar',
                      );
                      
                      if (context.mounted) {
                        PlatformAlert.showNotification(
                          context: context,
                          message: result 
                              ? 'Acción confirmada' 
                              : 'Acción cancelada',
                          isError: !result,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Mostrar Carga',
                    onPressed: () {
                      PlatformAlert.showLoadingDialog(
                        context: context,
                        future: Future.delayed(
                          const Duration(seconds: 2), 
                          () => 'Operación completada'
                        ),
                        message: 'Procesando...',
                      ).then((result) {
                        if (context.mounted) {
                          PlatformAlert.showNotification(
                            context: context,
                            message: result,
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PlatformButton(
                    text: 'Mostrar Notificación',
                    isPrimary: true,
                    onPressed: () {
                      PlatformAlert.showNotification(
                        context: context,
                        message: 'Esta es una notificación de ejemplo',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye un título de sección
  Widget _buildSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
} 