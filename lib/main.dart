import 'package:flutter/material.dart';
import 'main_menu.dart';

void main() {
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
        useMaterial3: true, // Opcional, para estilo moderno
      ),
      home: const PantallaPrincipal(),
      routes: {
        '/crear_chofer': (context) => const PlaceholderScreen('Gestión'),
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
