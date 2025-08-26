import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usutlax/providers/configuracion_provider.dart';

import '../widgets/drawer.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // 👈 siempre centrado
        title: Text(
          "Configuración",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Times New Roman',
            fontSize: 20,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: config.modoOscuro ? Colors.black87 : Colors.white,

        // 🔙 Flecha a la izquierda
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // ☰ Menú a la derecha
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: config.modoOscuro ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
        ],
      ),

      // 👇 Drawer integrado
      drawer: const DashboardDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Cuenta",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: config.modoOscuro ? Colors.white70 : Colors.grey,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: config.modoOscuro ? Colors.white : Colors.black,
            ),
            title: Text(
              "Información Personal",
              style: TextStyle(
                color: config.modoOscuro ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: config.modoOscuro ? Colors.white70 : Colors.black54,
            ),
            onTap: () {},
          ),
          const SizedBox(height: 20),

          const Text(
            "Apariencia",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          // ✅ Switch de modo oscuro
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text("Modo Oscuro"),
            value: config.modoOscuro,
            onChanged: (value) {
              config.toggleModoOscuro(value);
            },
          ),

          // ✅ Tamaño del Texto (sin tipografía)
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text("Tamaño de texto"),
            subtitle: Text("${config.tamanoTexto}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _mostrarDialogoTamanoTexto(context, config);
            },
          ),

          const SizedBox(height: 20),

          const Text(
            "OTROS AJUSTES",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          // ✅ Nuevo switch formato de hora
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text("Formato de hora (24h / 12h)"),
            trailing: Switch(
              value: config.formato24hrs,
              onChanged: (value) {
                config.toggleFormatoHora(value);
              },
            ),
          ),

          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Avisos de Privacidad"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text("Notificaciones"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Ayuda y Soporte"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.comment_outlined),
            title: const Text("Comentarios"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // 🔹 Modal solo con el slider de tamaño
  void _mostrarDialogoTamanoTexto(
    BuildContext context,
    ConfiguracionProvider config,
  ) {
    double tempSize = config.tamanoTextoPx;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          config.modoOscuro
              ? const Color.fromARGB(221, 0, 0, 0) // oscuro -> negro
              : Colors.white, // claro -> blanco
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tamaño de letra",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: config.modoOscuro ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Slider(
                    value: tempSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    label: "${tempSize.toInt()}",
                    activeColor: const Color.fromARGB(255, 25, 0, 255),
                    onChanged: (value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        config.cambiarTamanoTextoPx(tempSize);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Aplicar",
                        style: TextStyle(
                          color:
                              config.modoOscuro ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
