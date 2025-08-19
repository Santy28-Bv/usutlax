import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
  bool _aceptoTerminos = false;
  bool _mostrarContrasena = false;
  bool _cargando = false;
  bool _mostrarCheckbox = true;

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

      // Verifica si ya aceptó los términos
      final yaAcepto = data['terminos_aceptados'] == true;

      if (!yaAcepto && !_aceptoTerminos) {
        _mostrarMensaje('Debes aceptar los Términos y Condiciones');
        setState(() => _cargando = false);
        return;
      }

      if (passwordAlmacenada == password ||
          passwordAlmacenada == hashIngresado) {
        final rol = data['rol']?.toString().toLowerCase();
        if (rol == 'chofer') {
          final unidad = data['unidad'] ?? 'Desconocida';
          final nombreUsuario = data['nombre_de_usuario'] ?? 'Sin nombre';

          final unidadQuery =
              await FirebaseFirestore.instance
                  .collection('gestion_unidades')
                  .where('numero_unidad', isEqualTo: unidad)
                  .limit(1)
                  .get();
          final placas =
              unidadQuery.docs.isNotEmpty
                  ? unidadQuery.docs.first.data()['placas'] as String
                  : 'Desconocido';

          await FirebaseFirestore.instance.collection('historial').add({
            'chofer': nombreUsuario,
            'unidad': unidad,
            'placas': placas,
            'fecha_inicio_sesion': Timestamp.now(),
          });
        }

        // Guardar que ya aceptó los términos si no estaba registrado
        if (!yaAcepto) {
          await _usuarioEncontrado!.reference.update({
            'terminos_aceptados': true,
          });
        }
        // Guardar datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("nombre", data['nombre'] ?? 'Usuario');
        await prefs.setString(
          "username",
          data['nombre_de_usuario'] ?? 'username',
        );
        await prefs.setString("correo", data['email'] ?? '');
        await prefs.setString("rol", rol ?? '');

        // Si es chofer guardamos su tipo de operador (si existe en Firestore)
        if (rol == 'chofer') {
          await prefs.setString(
            "tipo_operador",
            data['tipo_operador'] ?? 'No especificado',
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PantallaPrincipal(rol: rol ?? '')),
        );
      } else {
        _mostrarMensaje('Contraseña incorrecta');
      }
    } catch (e) {
      print('Error en login: $e');
      _mostrarMensaje('Error al iniciar sesión');
    }

    setState(() => _cargando = false);
  }

  void _mostrarTerminos() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Términos y Condiciones'),
            content: const SingleChildScrollView(
              child: Text(
                'Al usar esta aplicación, aceptas que:\n\n'
                '- La app podrá acceder a tu ubicación para mejorar el servicio.\n'
                '- Podrá acceder a tus archivos para almacenar tickets de viaje.\n'
                '- El uso indebido puede resultar en suspensión de tu cuenta.\n'
                '- Tus datos estarán sujetos a la política de privacidad.\n',
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
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
                      onPressed: () {
                        setState(
                          () => _mostrarContrasena = !_mostrarContrasena,
                        );
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (_mostrarCheckbox)
                  Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _aceptoTerminos,
                            onChanged: (val) {
                              setState(() => _aceptoTerminos = val ?? false);
                            },
                          ),
                          const Expanded(
                            child: Text('Acepto Términos & Condiciones'),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _mostrarTerminos,
                          child: const Text('Ver Términos y Condiciones'),
                        ),
                      ),
                    ],
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
