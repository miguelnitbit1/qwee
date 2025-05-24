import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/platform_example_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/geocerca_provider.dart';
import 'providers/chat_provider.dart';
import 'middlewares/auth_middleware.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Inicializar App Check en modo debug
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    
    // Crear instancia de GeocercaProvider para poder acceder a ella desde los listeners del ciclo de vida
    final geocercaProvider = GeocercaProvider();
    
    // Configurar listener para cuando la app se cierra o se suspende
    final lifecycleObserver = AppLifecycleObserver(geocercaProvider);
    WidgetsBinding.instance.addObserver(lifecycleObserver);
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider.value(value: geocercaProvider),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: MyApp(lifecycleObserver: lifecycleObserver),
      ),
    );
  } catch (e) {
    print('Error inicializando Firebase: $e');
    runApp(const ErrorApp());
  }
}

/// Clase para observar los cambios de estado del ciclo de vida de la aplicación
class AppLifecycleObserver with WidgetsBindingObserver {
  final GeocercaProvider geocercaProvider;
  
  AppLifecycleObserver(this.geocercaProvider);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state: $state');
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // La app se está poniendo en segundo plano o cerrando
      print('Deteniendo monitoreo de geocercas');
      geocercaProvider.stopMonitoring();
    } else if (state == AppLifecycleState.resumed) {
      // La app vuelve a primer plano
      print('Reiniciando monitoreo de geocercas');
      geocercaProvider.startMonitoring();
    } else if (state == AppLifecycleState.detached) {
      // La app se está cerrando completamente
      print('App detached - limpiando recursos');
      geocercaProvider.stopMonitoring();
      geocercaProvider.exitCurrentGeocerca();
    }
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
              const Text(
                'Error de conexión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No se pudo conectar con el servidor',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Firebase.initializeApp(
                      options: DefaultFirebaseOptions.currentPlatform,
                    );
                    
                    // Crear instancia de GeocercaProvider para el lifecycleObserver
                    final geocercaProvider = GeocercaProvider();
                    final themeProvider = ThemeProvider();
                    final userProvider = UserProvider();
                    final lifecycleObserver = AppLifecycleObserver(geocercaProvider);
                    
                    // Añadir observer
                    WidgetsBinding.instance.addObserver(lifecycleObserver);
                    
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider.value(value: themeProvider),
                              ChangeNotifierProvider.value(value: userProvider),
                              ChangeNotifierProvider.value(value: geocercaProvider),
                            ],
                            child: MyApp(lifecycleObserver: lifecycleObserver),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Mantener la pantalla de error
                  }
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AppLifecycleObserver lifecycleObserver;
  
  const MyApp({super.key, required this.lifecycleObserver});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Limpiar el observer cuando se cierre la app
    WidgetsBinding.instance.removeObserver(widget.lifecycleObserver);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Usar Cupertino para iOS, Material para otras plataformas
    if (Platform.isIOS) {
      final isDark = themeProvider.themeMode == ThemeMode.dark;
      
      return CupertinoApp(
        title: 'Nitbit',
        theme: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primaryColor: const Color(0xFF1E88E5),
          barBackgroundColor: isDark 
              ? const Color(0xFF121212) 
              : CupertinoColors.white,
          scaffoldBackgroundColor: isDark 
              ? const Color(0xFF121212) 
              : CupertinoColors.white,
          textTheme: CupertinoTextThemeData(
            navLargeTitleTextStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            navTitleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            textStyle: TextStyle(
              fontSize: 16,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            actionTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
            tabLabelTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          primaryContrastingColor: Colors.white,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const AuthMiddleware(child: HomeScreen()),
          '/examples': (context) => const PlatformExampleScreen(),
        },
      );
    } else {
      return MaterialApp(
        title: 'Nitbit',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            primary: const Color(0xFF1E88E5),
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ).copyWith(
            secondary: const Color(0xFF03DAC6),
            tertiary: const Color(0xFF3700B3),
          ),
          // Tema de AppBar mejorado
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          // Tema de inputs mejorado
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          // Tema de botones mejorado
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
          ),
          // Tema de texto mejorado
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              letterSpacing: 0.15,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              letterSpacing: 0.25,
            ),
          ),
          // Tema de cards mejorado
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          // Tema de iconos mejorado
          iconTheme: const IconThemeData(
            color: Color(0xFF1E88E5),
            size: 24,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.dark,
          ).copyWith(
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFF03DAC6),
            tertiary: const Color(0xFF3700B3),
            surface: const Color(0xFF1E1E1E),
            onSurface: Colors.white,
            onSurfaceVariant: Colors.grey[300],
            surfaceContainerHighest: const Color(0xFF2C2C2C),
            outline: Colors.grey[700],
            onPrimary: Colors.white,
            error: const Color(0xFFD32F2F),
            onError: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            floatingLabelStyle: const TextStyle(color: Colors.white),
            labelStyle: TextStyle(color: Colors.grey[400]),
            prefixIconColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return Colors.white;
              }
              return Colors.grey[400]!;
            }),
            suffixIconColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.focused)) {
                return Colors.white;
              }
              return Colors.grey[400]!;
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              letterSpacing: 0.15,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              letterSpacing: 0.25,
              color: Colors.white,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              letterSpacing: 0.25,
              color: Colors.grey,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.grey[800]!,
                width: 0.5,
              ),
            ),
            color: const Color(0xFF1E1E1E),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF1E88E5),
            size: 24,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          dialogTheme: DialogTheme(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            modalBarrierColor: Colors.black.withOpacity(0.5),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF1E1E1E),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        themeMode: themeProvider.themeMode,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const AuthMiddleware(child: HomeScreen()),
          '/examples': (context) => const PlatformExampleScreen(),
        },
      );
    }
  }
}