import 'package:flutter/material.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Fondo blanco
      appBar: AppBar(
        title: const Text('Menú Principal'),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(200, 0, 255, 1), // Morado
        foregroundColor: Colors.white, // Texto blanco
      ),
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
    );
  }

  // Nuevo estilo tipo tarjeta para los botones
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
        color: const Color.fromRGBO(200, 0, 255, 0.9), // Morado suave
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
