import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usutlax/screens/gestion_usuarios.dart';
import 'package:usutlax/screens/gestion_de_unidades.dart';
import 'package:usutlax/screens/login_screen.dart';
import 'firebase_options.dart';
import 'main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  // ✅ Verifica si hay sesión y obtiene rol
  Future<Map<String, dynamic>> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final logueado = prefs.getBool('logueado') ?? false;
    final rol = prefs.getString('rol') ?? ''; // Recuperar rol guardado
    return {'logueado': logueado, 'rol': rol};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _verificarSesion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final logueado = snapshot.data!['logueado'] as bool;
        final rol = snapshot.data!['rol'] as String;

        return MaterialApp(
          title: 'Urbanos y Suburbanos de Tlaxcala S.A. de C.V.',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(200, 0, 255, 1),
            ),
            useMaterial3: true,
          ),
          home:
              logueado
                  ? PantallaPrincipal(
                    rol: rol,
                  ) // 🔹 Pasamos el rol al menú principal
                  : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/menu_principal': (context) => PantallaPrincipal(rol: rol),
            '/gestion_chofer': (context) => GestionUsuariosScreen(rol: rol),
            '/unidades_transporte':
                (context) => GestionDeUnidadesScreen(rol: rol),
            '/crear_despachador':
                (context) => const PlaceholderScreen('Crear Despachador'),
            '/ver_rutas': (context) => const PlaceholderScreen('Ver Rutas'),
            '/mensajes': (context) => const PlaceholderScreen('Mensajes'),
            '/mapa_choferes':
                (context) => const PlaceholderScreen('Mapa Choferes'),
          },
        );
      },
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String titulo;

  const PlaceholderScreen(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(child: Text('Pantalla: $titulo')),
    );
  }
}
