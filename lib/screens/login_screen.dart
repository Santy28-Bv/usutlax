import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:usutlax/chofer_tracking.dart';
import '../main_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioCorreoController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _mostrarContrasena = false;
  bool _cargando = false;

  DocumentSnapshot? _usuarioEncontrado;

  String generarHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Dialogo reutilizable de Términos & Condiciones (devuelve true si acepta)
  Future<bool> _mostrarDialogoTerminos() async {
    final acepto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text("Términos y Condiciones"),
            content: const SingleChildScrollView(
              child: Text(
                "Al usar esta aplicación aceptas que:\n\n"
                "- La app podrá acceder a tu ubicación para mejorar el servicio.\n"
                "- Podrá acceder a tus archivos para almacenar tickets de viaje.\n"
                "- El uso indebido puede resultar en suspensión de tu cuenta.\n"
                "- Tus datos estarán sujetos a la política de privacidad.\n",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Rechazar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Aceptar"),
              ),
            ],
          ),
    );
    return acepto == true;
  }

  // Aviso cuando no acepta los términos (solo botón Cerrar)
  Future<void> _mostrarDialogoDebeAceptar() async {
    await showDialog<void>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Aviso"),
            content: const Text(
              "Debes aceptar los Términos y Condiciones para usar la app.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
    );
  }

  Future<void> _iniciarSesion() async {
    final input = _usuarioCorreoController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor, completa todos los campos');
      return;
    }

    setState(() => _cargando = true);
    final hashIngresado = generarHash(password);

    try {
      // Buscar por usuario o por correo
      QuerySnapshot query =
          await FirebaseFirestore.instance
              .collection('gestion_usuarios')
              .where('nombre_de_usuario', isEqualTo: input)
              .get();

      if (query.docs.isEmpty) {
        query =
            await FirebaseFirestore.instance
                .collection('gestion_usuarios')
                .where('email', isEqualTo: input)
                .get();
      }

      if (query.docs.isEmpty) {
        _mostrarMensaje('Usuario o correo no encontrado');
        setState(() => _cargando = false);
        return;
      }

      _usuarioEncontrado = query.docs.first;
      final data = _usuarioEncontrado!.data() as Map<String, dynamic>;
      final passwordAlmacenada = data['password'];

      // ✅ Validar contraseña (plain o hash)
      if (passwordAlmacenada == password ||
          passwordAlmacenada == hashIngresado) {
        final rol = data['rol']?.toString().toLowerCase();
        final yaAcepto = data['terminos_aceptados'] == true;

        // 🔹 Si no ha aceptado, mostrar diálogo con Aceptar/Cancelar
        if (!yaAcepto) {
          final acepto = await _mostrarDialogoTerminos();
          if (!acepto) {
            await _mostrarDialogoDebeAceptar(); // ← ahora es un AlertDialog con botón Cerrar
            _usuarioCorreoController.clear();
            _passwordController.clear();
            setState(() => _cargando = false);
            return;
          }

          // ✅ Si aceptó, marcar en Firestore
          await _usuarioEncontrado!.reference.update({
            "terminos_aceptados": true,
          });
        }

        // 🔹 Guardar datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("nombre", data['nombre'] ?? 'Usuario');
        await prefs.setString(
          "username",
          data['nombre_de_usuario'] ?? 'username',
        );
        await prefs.setString("correo", data['email'] ?? '');
        await prefs.setString("rol", rol ?? '');
        await prefs.setString("uid", _usuarioEncontrado!.id);
        await prefs.setString("usuarioId", _usuarioEncontrado!.id);
        await prefs.setBool("logueado", true); // ← útil para tu main

        if (rol == 'chofer') {
          await prefs.setString(
            "tipo_operador",
            data['tipo_operador'] ?? 'No especificado',
          );
        }

        // Navegar al menú principal
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaPrincipal(rol: rol ?? ''),
            ),
          );
        }
      } else {
        _mostrarMensaje("Contraseña incorrecta");
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error en login: $e');
      _mostrarMensaje('Error al iniciar sesión');
    }

    if (mounted) setState(() => _cargando = false);
  }

  // Botón "Ver Términos y Condiciones" (solo informativo, no guarda nada)
  void _mostrarTerminos() {
    _mostrarDialogoTerminos(); // reutilizamos el mismo diálogo con Aceptar/Cancelar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Urbanos y Suburbanos de Tlaxcala.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'INICIO DE SESIÓN',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                const Icon(
                  Icons.account_circle,
                  size: 120,
                  color: Colors.purple,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _usuarioCorreoController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario o correo electrónico',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_mostrarContrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarContrasena
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(
                            () => _mostrarContrasena = !_mostrarContrasena,
                          ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // 👇 Ver Términos (informativo)
                TextButton(
                  onPressed: _mostrarTerminos,
                  child: const Text(
                    'Ver Términos y Condiciones',
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ],
            ),
          ),
          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
