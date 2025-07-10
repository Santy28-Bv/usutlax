import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase Core
import 'firebase_options.dart'; // ✅ Configuración generada
import 'package:usutlax/screens/gestion_chofer_screen.dart';
import 'main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Necesario para inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Administrador',
      debugShowCheckedModeBanner: false, // ✅ Elimina el banner de debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(200, 0, 255, 1),
        ),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
      routes: {
        '/gestion_chofer': (context) => const GestionChoferScreen(),
        '/crear_despachador':
            (context) => const PlaceholderScreen('Crear Despachador'),
        '/ver_rutas': (context) => const PlaceholderScreen('Ver Rutas'),
        '/mensajes': (context) => const PlaceholderScreen('Mensajes'),
        '/mapa_choferes': (context) => const PlaceholderScreen('Mapa Choferes'),
        '/login': (context) => const PlaceholderScreen('Login'),
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
