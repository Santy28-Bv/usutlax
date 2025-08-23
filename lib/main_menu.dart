import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/drawer.dart';
import 'widgets/bottom_menu.dart';
import '../providers/configuracion_provider.dart';

// Pantalla Principal
class PantallaPrincipal extends StatelessWidget {
  final String rol;

  const PantallaPrincipal({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      // ✅ El fondo ahora depende del tema
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // APPBAR
      appBar: AppBar(
        title: const Text('Menú Principal'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),

      // DASHBOARD (Drawer)
      drawer: const DashboardDrawer(),

      // CUERPO PRINCIPAL
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Imagen logo
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/img/usublanco.png' // 🌙 modo oscuro
                  : 'assets/img/usu.png', // ☀️ modo claro
              width: 235,
              height: 125,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),

            // ✅ Texto bienvenida adaptado al tema
            Text(
              'BIENVENIDO A\nLA APP DE USU',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: config.fontSize, // 🔎 Usa tamaño dinámico
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color, // ✅ Color según tema
              ),
            ),
            const SizedBox(height: 20),

            // Grid dinámico
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: _getOpcionesPorRol(context),
              ),
            ),
          ],
        ),
      ),

      // MENU DE ABAJO
      bottomNavigationBar: BottomMenu(rol: rol),
    );
  }

  // Filtrar opciones por rol
  List<Widget> _getOpcionesPorRol(BuildContext context) {
    switch (rol) {
      case 'admin':
        return [
          _adminCard(
            context,
            Icons.people_alt_outlined,
            'Gestión de choferes',
            '/gestion_chofer',
          ),
          _adminCard(
            context,
            Icons.directions_bus_rounded,
            'Unidades de Transporte',
            '/unidades_transporte',
          ),
          _adminCard(context, Icons.map, 'Monitoreo GPS', '/monitoreo_gps'),
          _adminCard(
            context,
            Icons.settings,
            'Configuración',
            '/configuracion',
          ),
        ];

      case 'despachador':
        return [
          _adminCard(
            context,
            Icons.person_add,
            'Añadir Choferes',
            '/anadir_chofer',
          ),
          _adminCard(
            context,
            Icons.settings,
            'Configuración',
            '/configuracion',
          ),
        ];

      case 'chofer':
        return [
          _adminCard(context, Icons.qr_code, 'QR', '/qr'),
          _adminCard(context, Icons.message, 'Mensajes', '/mensajes'),
          _adminCard(
            context,
            Icons.settings,
            'Configuración',
            '/configuracion',
          ),
        ];

      default:
        return [];
    }
  }

  // Widget tarjeta de botón
  Widget _adminCard(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: const Color.fromARGB(127, 126, 85, 223),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
