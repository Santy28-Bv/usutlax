import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({super.key});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  String _nombre = "Usuario";
  String _username = "username";
  String? _correo;
  String? _tipoOperador; // ✅ corregido: debe coincidir con el login
  String _rol = "invitado";

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nombre = prefs.getString("nombre") ?? "Usuario";
      _username = prefs.getString("username") ?? "username";
      _correo = prefs.getString("correo");
      _tipoOperador = prefs.getString("tipo_operador"); // 👈 igual que en login
      _rol = prefs.getString("rol") ?? "invitado";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 🔹 HEADER
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 76, 0, 255),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.purple),
            ),
            accountName: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
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
                              ? "Chofer (${_tipoOperador!.trim()})"
                              : "Chofer")
                          : _rol,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_correo != null && _correo!.isNotEmpty)
                  Text(
                    _correo!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  "@$_username",
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
          _item(Icons.person, "Mi perfil", () {}),
          _item(Icons.gps_fixed, "Monitoreo GPS", () {}),
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
            Icons.person_add,
            "Añadir Choferes",
            () => Navigator.pushNamed(context, '/gestion_chofer'),
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
            Icons.message,
            "Mensajes",
            () => Navigator.pushNamed(context, '/mensajes'),
          ),
          _item(Icons.qr_code_scanner, "Escaneo QR", () {}),
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
