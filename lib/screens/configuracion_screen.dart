import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usutlax/providers/configuracion_provider.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Obtenemos el provider
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "ACCOUNT",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Información Personal"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const SizedBox(height: 20),

          const Text(
            "APPEARANCE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),

          // ✅ Switch de Modo Oscuro usando provider
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text("Modo Oscuro"),
            value: config.modoOscuro,
            onChanged: (value) {
              config.toggleModoOscuro(value);
            },
          ),

          // ✅ Tamaño del Texto usando provider
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text("Tamaño del Texto"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(config.tamanoTexto),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              _mostrarDialogoTamanoTexto(context, config);
            },
          ),

          const SizedBox(height: 20),

          const Text(
            "OTROS AJUSTES",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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

  void _mostrarDialogoTamanoTexto(
    BuildContext context,
    ConfiguracionProvider config,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tamaño del Texto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _opcionTexto("Pequeño", config, context),
              _opcionTexto("Mediano", config, context),
              _opcionTexto("Grande", config, context),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionTexto(
    String opcion,
    ConfiguracionProvider config,
    BuildContext context,
  ) {
    return RadioListTile<String>(
      title: Text(opcion),
      value: opcion,
      groupValue: config.tamanoTexto,
      onChanged: (value) {
        config.cambiarTamanoTexto(value!); // 👈 Corrección aquí
        Navigator.pop(context);
      },
    );
  }
}
