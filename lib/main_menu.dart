import 'package:flutter/material.dart';
import 'widgets/drawer.dart';
import 'widgets/bottom_menu.dart';
import 'screens/gestion_de_unidades.dart'; // ✅ Asegúrate de que el archivo exista y esté en esa ruta

// Pantalla Principal
class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      //APPBAR
      appBar: AppBar(
        title: const Text('Menú Principal'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
      ),

      //DASHBOARD (Drawer)
      drawer: const DashboardDrawer(),

      //CUERPO PRINCIPAL
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
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
          ],
        ),
      ),

      //MENU DE ABAJO
      bottomNavigationBar: const BottomMenu(),
    );
  }

  // Widget Tarjeta de Botón
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
