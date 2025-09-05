import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usutlax/screens/chat_users_screen.dart';
import 'package:usutlax/screens/configuracion_screen.dart';
import 'package:usutlax/screens/gestion_usuarios.dart';
import 'package:usutlax/screens/gestion_de_unidades.dart';
import 'package:usutlax/screens/lista_choferes.dart';
import 'package:usutlax/screens/login_screen.dart';
import 'package:usutlax/screens/perfil_screen.dart'; // ✅ Import PerfilScreen
import 'firebase_options.dart';
import 'main_menu.dart';
import 'package:provider/provider.dart';
import 'providers/configuracion_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConfiguracionProvider(),
      child: const MiApp(),
    ),
  );
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  Future<Map<String, dynamic>> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final logueado = prefs.getBool('logueado') ?? false;
    final rol = prefs.getString('rol') ?? '';
    return {'logueado': logueado, 'rol': rol};
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

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
          title: 'Urbanos y Sub Urbanos de Tlaxcala S.A. de C.V.',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
          locale: const Locale('es', 'ES'),

          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Times New Roman',
                color: Colors.black,
              ),
              iconTheme: IconThemeData(color: Colors.black),
            ),
            textTheme: TextTheme(
              bodySmall: TextStyle(fontSize: config.fontSize),
              bodyMedium: TextStyle(fontSize: config.fontSize),
              bodyLarge: TextStyle(fontSize: config.fontSize),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Times New Roman',
                color: Colors.white,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            textTheme: TextTheme(
              bodySmall: TextStyle(fontSize: config.fontSize),
              bodyMedium: TextStyle(fontSize: config.fontSize),
              bodyLarge: TextStyle(fontSize: config.fontSize),
            ),
          ),
          themeMode: config.modoOscuro ? ThemeMode.dark : ThemeMode.light,

          home: logueado ? PantallaPrincipal(rol: rol) : const LoginScreen(),

          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/menu_principal':
                return MaterialPageRoute(
                  builder: (_) => PantallaPrincipal(rol: rol),
                );
              case '/perfil': // ✅ Ruta añadida para PerfilScreen
                return MaterialPageRoute(builder: (_) => const PerfilScreen());
              case '/gestion_chofer':
                return MaterialPageRoute(
                  builder: (_) => GestionUsuariosScreen(rol: rol),
                );
              case '/unidades_transporte':
                return MaterialPageRoute(
                  builder: (_) => GestionDeUnidadesScreen(rol: rol),
                );
              case '/crear_despachador':
                return MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen('Crear Despachador'),
                );
              case '/ver_rutas':
                return MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen('Ver Rutas'),
                );
              case '/mensajes':
                return MaterialPageRoute(
                  builder:
                      (_) => FutureBuilder<String?>(
                        future: SharedPreferences.getInstance().then(
                          (prefs) => prefs.getString("usuarioId"),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return ChatUsersScreen(currentUserId: snapshot.data!);
                        },
                      ),
                );
              case '/monitoreo_gps':
                return MaterialPageRoute(
                  builder: (_) => const ListaChoferesScreen(),
                );
              case '/configuracion':
                return MaterialPageRoute(
                  builder: (_) => const ConfiguracionScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const PlaceholderScreen('No encontrada'),
                );
            }
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
