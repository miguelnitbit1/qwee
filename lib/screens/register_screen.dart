import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/platform_text_field.dart';
import '../widgets/platform_button.dart';
import '../widgets/platform_alert.dart';
import '../widgets/platform_scaffold.dart';
import '../utils/adaptive_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Crear usuario en Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          // Crear documento en Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          // Mostrar mensaje de éxito
          PlatformAlert.showNotification(
            context: context,
            message: '¡Bienvenido a Nitbit!',
            isError: false,
          );

          // Cerrar sesión y redirigir al login
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Ocurrió un error al crear la cuenta';
        if (e.code == 'weak-password') {
          message = 'La contraseña es muy débil';
        } else if (e.code == 'email-already-in-use') {
          message = 'El correo ya está registrado';
        }
        if (mounted) {
          PlatformAlert.showNotification(
            context: context,
            message: message,
            isError: true,
          );
        }
      } catch (e) {
        if (mounted) {
          PlatformAlert.showNotification(
            context: context,
            message: 'Error: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIOS = Platform.isIOS;
    
    return PlatformScaffold(
      title: '',
      showBackButton: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Únete a nuestra comunidad',
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                PlatformTextField(
                  controller: _firstNameController,
                  label: 'Nombre',
                  prefixIcon: isIOS ? CupertinoIcons.person : Icons.person_outline,
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
                  prefixIcon: isIOS ? CupertinoIcons.person : Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PlatformTextField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  prefixIcon: isIOS ? CupertinoIcons.mail : Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su correo';
                    }
                    if (!value.contains('@')) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PlatformTextField(
                  controller: _passwordController,
                  label: 'Contraseña',
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
                const SizedBox(height: 16),
                PlatformTextField(
                  controller: _phoneController,
                  label: 'Número de teléfono',
                  prefixIcon: isIOS ? CupertinoIcons.phone : Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su número de teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PlatformButton(
                  text: _isLoading ? 'Procesando...' : 'Registrarse',
                  isPrimary: true,
                  onPressed: _isLoading ? null : _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
} 