import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({super.key});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  String _nombre = "Usuario";
  String _nombreDeUsuario = "username";
  String? _correo;
  String? _tipoOperador;
  String _rol = "invitado";
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("usuarioId");

    if (userId != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection("gestion_usuarios")
                .doc(userId)
                .get();

        if (doc.exists) {
          final data = doc.data()!;
          _nombre = data["nombre"] ?? "Usuario";
          _nombreDeUsuario = data["nombre_de_usuario"] ?? "username";
          _correo = data["email"]; // 🔹 aquí usamos el campo correcto de la BD
          _tipoOperador = data["tipo de operador"];
          _rol = data["rol"] ?? "invitado";
          _fotoUrl = data["fotoUrl"];

          await prefs.setString("nombre", _nombre);
          await prefs.setString("nombre_de_usuario", _nombreDeUsuario);
          if (_correo != null) await prefs.setString("correo", _correo!);
          if (_tipoOperador != null) {
            await prefs.setString("tipo_operador", _tipoOperador!);
          }
          await prefs.setString("rol", _rol);
          if (_fotoUrl != null) await prefs.setString("fotoUrl", _fotoUrl!);
        }
      } catch (e) {
        debugPrint("❌ Error al cargar Firestore: $e");
      }
    } else {
      _nombre = prefs.getString("nombre") ?? "Usuario";
      _nombreDeUsuario = prefs.getString("nombre_de_usuario") ?? "username";
      _correo = prefs.getString("correo");
      _tipoOperador = prefs.getString("tipo_operador");
      _rol = prefs.getString("rol") ?? "invitado";
      _fotoUrl = prefs.getString("fotoUrl");
    }

    if (mounted) setState(() {});
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("usuarioId");
      if (userId == null) return;

      final ref = FirebaseStorage.instance.ref().child("usuarios/$userId.jpg");
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("gestion_usuarios")
          .doc(userId)
          .update({"fotoUrl": url});

      await prefs.setString("fotoUrl", url);

      setState(() => _fotoUrl = url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Foto actualizada correctamente")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error al subir foto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 🔹 HEADER PERSONALIZADO
          Container(
            color: const Color.fromARGB(255, 76, 0, 255),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _cambiarFoto,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                        child:
                            _fotoUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.purple,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _rol.toLowerCase() == "chofer"
                                ? (_tipoOperador != null &&
                                        _tipoOperador!.trim().isNotEmpty
                                    ? "Chofer: ${_tipoOperador!.trim()}"
                                    : "Chofer")
                                : _rol,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 🔹 username y email en la misma línea
                Text(
                  "@$_nombreDeUsuario${_correo != null && _correo!.isNotEmpty ? ' $_correo' : ''}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 🔹 Opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [..._buildMenuOptions(context, _rol)],
            ),
          ),

          const Divider(),

          // 🔹 Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuOptions(BuildContext context, String rol) {
    switch (rol.toLowerCase()) {
      case "admin":
        return [
          _item(
            Icons.home,
            "Inicio",
            () => Navigator.pushNamed(context, '/menu_principal'),
          ),
          _item(
            Icons.person,
            "Mi perfil",
            () => Navigator.pushNamed(context, '/perfil'),
          ),
          _item(
            Icons.gps_fixed,
            "Monitoreo GPS",
            () => Navigator.pushNamed(context, '/monitoreo_gps'),
          ),
          _item(
            Icons.message,
            "Mensajes",
            () => Navigator.pushNamed(context, '/mensajes'),
          ),
          _item(Icons.notifications, "Notificaciones", () {}),
          _item(
            Icons.people,
            "Gestión choferes",
            () => Navigator.pushNamed(context, '/gestion_chofer'),
          ),
          _item(
            Icons.directions_bus,
            "Gestión de Unidades",
            () => Navigator.pushNamed(context, '/unidades_transporte'),
          ),
          _item(
            Icons.person_add,
            "Crear Despachador",
            () => Navigator.pushNamed(context, '/crear_despachador'),
          ),
          _item(
            Icons.map,
            "Ver Rutas",
            () => Navigator.pushNamed(context, '/ver_rutas'),
          ),
          _item(
            Icons.settings,
            "Configuración",
            () => Navigator.pushNamed(context, '/configuracion'),
          ),
        ];
      case "despachador":
        return [
          _item(
            Icons.home,
            "Inicio",
            () => Navigator.pushNamed(context, '/menu_principal'),
          ),
          _item(
            Icons.people,
            "Gestión choferes",
            () => Navigator.pushNamed(context, '/gestion_chofer'),
          ),
          _item(
            Icons.directions_bus,
            "Gestión de Unidades",
            () => Navigator.pushNamed(context, '/unidades_transporte'),
          ),
          _item(
            Icons.map,
            "Ver Rutas",
            () => Navigator.pushNamed(context, '/ver_rutas'),
          ),
          _item(
            Icons.message,
            "Mensajes",
            () => Navigator.pushNamed(context, '/mensajes'),
          ),
          _item(
            Icons.gps_fixed,
            "Monitoreo GPS",
            () => Navigator.pushNamed(context, '/monitoreo_gps'),
          ),
          _item(
            Icons.settings,
            "Configuración",
            () => Navigator.pushNamed(context, '/configuracion'),
          ),
        ];
      case "chofer":
        return [
          _item(
            Icons.home,
            "Inicio",
            () => Navigator.pushNamed(context, '/menu_principal'),
          ),
          _item(
            Icons.person,
            "Mi perfil",
            () => Navigator.pushNamed(context, '/perfil'),
          ),
          _item(
            Icons.message,
            "Mensajes",
            () => Navigator.pushNamed(context, '/mensajes'),
          ),
          _item(Icons.qr_code_scanner, "Escaneo QR", () {}),
          _item(
            Icons.map,
            "Ver Rutas",
            () => Navigator.pushNamed(context, '/ver_rutas'),
          ),
          _item(
            Icons.settings,
            "Configuración",
            () => Navigator.pushNamed(context, '/configuracion'),
          ),
        ];
      default:
        return [
          _item(
            Icons.home,
            "Inicio",
            () => Navigator.pushNamed(context, '/menu_principal'),
          ),
          _item(
            Icons.settings,
            "Configuración",
            () => Navigator.pushNamed(context, '/configuracion'),
          ),
        ];
    }
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
