import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usutlax/screens/mapa_chofer_screen.dart';

class ListaChoferesScreen extends StatelessWidget {
  const ListaChoferesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitoreo GPS")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("gestion_usuarios")
                .where("rol", isEqualTo: "chofer")
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay choferes disponibles"));
          }

          final choferes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: choferes.length,
            itemBuilder: (context, index) {
              final chofer = choferes[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Chofer: ${chofer['nombre']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Usuario: ${chofer['nombre_de_usuario']}"),
                      Text("Teléfono: ${chofer['telefono']}"),
                      Text("Unidad: ${chofer['unidad']}"),
                      Text("Tipo: ${chofer['tipo de operador']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_red_eye),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MapaChoferScreen(
                                choferId: chofer.id,
                                nombre: chofer['nombre'],
                                correo:
                                    chofer['nombre_de_usuario'], // 👈 puse el username
                                telefono: chofer['telefono'],
                              ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
