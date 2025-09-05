import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/drawer.dart';
import 'widgets/bottom_menu.dart';
import '../providers/configuracion_provider.dart';

class PantallaPrincipal extends StatelessWidget {
  final String rol;

  const PantallaPrincipal({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        centerTitle: true,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth, // ocupa todo el ancho disponible
              child: const Text(
                'Menú Principal',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible, // evita los "..."
              ),
            );
          },
        ),
        actions: _getAppBarActions(context, rol),
      ),

      drawer: const DashboardDrawer(),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/img/usublanco.png'
                  : 'assets/img/usu.png',
              width: 235,
              height: 125,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),

            Text(
              'BIENVENIDO A\nLA APP DE USU',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: config.fontSize,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 20),

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

      bottomNavigationBar: BottomMenu(rol: rol),
    );
  }

  /// 🔹 Acciones dinámicas en el AppBar
  List<Widget> _getAppBarActions(BuildContext context, String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => Navigator.pushNamed(context, '/mensajes'),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/monitoreo_gps'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {}, // 🚧 notificaciones pendiente
          ),
        ];

      case 'despachador':
        return [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/ver_rutas'),
          ),
          IconButton(
            icon: const Icon(Icons.gps_fixed),
            onPressed: () => Navigator.pushNamed(context, '/monitoreo_gps'),
          ),
        ];

      case 'chofer':
        return [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => Navigator.pushNamed(context, '/mensajes'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.pushNamed(context, '/qr'),
          ),
        ];

      default:
        return [];
    }
  }

  /// 🔹 Opciones en el grid central
  List<Widget> _getOpcionesPorRol(BuildContext context) {
    switch (rol.toLowerCase()) {
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
            '/gestion_chofer',
          ),
          _adminCard(context, Icons.map, 'Ver Rutas', '/ver_rutas'),
          _adminCard(
            context,
            Icons.settings,
            'Configuración',
            '/configuracion',
          ),
        ];

      case 'chofer':
        return [
          _adminCard(context, Icons.qr_code, 'Escanear QR', '/qr'),
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
