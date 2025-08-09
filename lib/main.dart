import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase Core
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usutlax/screens/gestion_usuarios.dart';
import 'package:usutlax/screens/gestion_de_unidades.dart';
import 'package:usutlax/screens/login_screen.dart';
import 'firebase_options.dart'; // ✅ Configuración generada
import 'main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Necesario para inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  // ✅ Verifica si ya hay sesión guardada
  Future<bool> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('logueado') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _verificarSesion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          title: 'Urbanos y Suburbanos de Tlaxcala S.A. de C.V.',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(200, 0, 255, 1),
            ),
            useMaterial3: true,
          ),

          // ✅ Si está logueado -> menú principal, si no -> login
          home:
              snapshot.data! ? const PantallaPrincipal() : const LoginScreen(),

          routes: {
            '/login': (context) => const LoginScreen(), // ✅ Ruta real
            '/menu_principal': (context) => const PantallaPrincipal(),
            '/gestion_chofer': (context) => const GestionUsuariosScreen(),
            '/unidades_transporte':
                (context) => const GestionDeUnidadesScreen(),
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
