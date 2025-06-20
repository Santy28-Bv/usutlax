import 'package:flutter/material.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Menú Principal'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
      ),

      // 👉 Drawer lateral
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(127, 126, 85, 223),
              ), //Color dashboard
              child: Text(
                'Menú lateral',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi perfil'),
              onTap: () {
                Navigator.pop(context);
                // Puedes agregar navegación si tienes esa ruta
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      // 👉 Cuerpo principal
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

      // 👉 Barra inferior de navegación
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(
          127,
          126,
          85,
          223,
        ), //Color icono casa inicio
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Inicio
        onTap: (index) {
          // Aquí podrías implementar navegación si lo deseas
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }

  // Tarjeta de botón del menú
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
        color: const Color.fromARGB(127, 126, 85, 223), //botones
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
