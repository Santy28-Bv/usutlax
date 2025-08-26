import 'package:flutter/material.dart';

class BottomMenu extends StatefulWidget {
  final String? rol; // opcional

  const BottomMenu({super.key, this.rol});

  @override
  State<BottomMenu> createState() => _BottomMenuState();
}

class _BottomMenuState extends State<BottomMenu> {
  int _selectedIndex = 2; // inicio seleccionado por defecto

  @override
  Widget build(BuildContext context) {
    List<BottomNavigationBarItem> items = const [
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

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color.fromRGBO(15, 21, 255, 1), // azul
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      selectedFontSize: 12, // tamaño fijo para evitar que se corte
      unselectedFontSize: 12,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: items,
    );
  }
}
