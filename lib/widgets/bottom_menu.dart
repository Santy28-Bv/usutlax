import 'package:flutter/material.dart';

class BottomMenu extends StatelessWidget {
  final String rol;

  const BottomMenu({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items;

    switch (rol) {
      case 'admin':
        items = const [
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
        ];
        break;
      case 'despachador':
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ];
        break;
      case 'chofer':
        items = const [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ];
        break;
      default:
        items = const [];
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromARGB(127, 126, 85, 223),
      unselectedItemColor: Colors.grey,
      currentIndex: items.length > 1 ? 1 : 0,
      onTap: (index) {
        // Aquí puedes agregar navegación si lo deseas
      },
      items: items,
    );
  }
}
