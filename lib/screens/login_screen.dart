import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_alert.dart';
import '../utils/adaptive_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Verificamos si hay una sesión activa y la cerramos
    _checkAndSignOut();
  }

  Future<void> _checkAndSignOut() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Intentando iniciar sesión con email: ${_emailController.text.trim()}');
      
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('Login exitoso. Usuario: ${userCredential.user?.uid}');

      if (!mounted) {
        print('Widget no está montado después del login');
        return;
      }

      print('Navegando a la pantalla de inicio...');
      
      // Esperamos un momento para asegurar que Firebase Auth esté listo
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) {
        print('Widget no está montado después del delay');
        return;
      }

      // Verificamos que el usuario siga autenticado
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Error: Usuario no está autenticado después del login');
        throw Exception('No se pudo completar la autenticación');
      }

      print('Usuario actual: ${currentUser.uid}');
      
      // Navegamos a home
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (Route<dynamic> route) => false,
      );
      
      print('Navegación completada');
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');
      if (!mounted) return;

      String message = 'Error al iniciar sesión';
      if (e.code == 'user-not-found') {
        message = 'No existe una cuenta con este correo';
      } else if (e.code == 'wrong-password') {
        message = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        message = 'Correo electrónico inválido';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos fallidos. Por favor, intente más tarde';
      }
      
      PlatformAlert.showNotification(
        context: context,
        message: message,
        isError: true,
      );
    } catch (e) {
      print('Error general: $e');
      if (!mounted) return;
      
      PlatformAlert.showNotification(
        context: context,
        message: 'Error al iniciar sesión: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIOS = Platform.isIOS;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary,
              colors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo con efecto de sombra
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Image.asset(
                        'assets/images/nitbit_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Textos de bienvenida
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 50),
                // Formulario con fondo semi-transparente
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlatformTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          placeholder: 'Ingrese su correo',
                          prefixIcon: isIOS ? CupertinoIcons.mail : Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su correo';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PlatformTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          placeholder: 'Ingrese su contraseña',
                          prefixIcon: isIOS ? CupertinoIcons.lock : Icons.lock_outline,
                          suffixIcon: isIOS ? 
                              (_obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash) : 
                              (_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          obscureText: _obscurePassword,
                          onSuffixIconPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        PlatformButton(
                          text: _isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
                          isPrimary: true,
                          onPressed: _isLoading ? null : _login,
                        ),
                      ],
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: PlatformButton(
                    text: '¿No tienes cuenta? Regístrate',
                    isPrimary: false,
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    expandWidth: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 