import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalleUnidadScreen extends StatefulWidget {
  final String unidad;

  const DetalleUnidadScreen({super.key, required this.unidad});

  @override
  State<DetalleUnidadScreen> createState() => _DetalleUnidadScreenState();
}

class _DetalleUnidadScreenState extends State<DetalleUnidadScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UNIDAD ${widget.unidad}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() => _busqueda = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('historial_unidades')
                      .where('unidad', isEqualTo: widget.unidad)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final historial =
                    snapshot.data!.docs.where((doc) {
                      final chofer = doc['chofer'].toString().toLowerCase();
                      return chofer.contains(_busqueda);
                    }).toList();

                if (historial.isEmpty) {
                  return const Center(child: Text('No hay historial.'));
                }

                return ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final data = historial[index];
                    return Card(
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chofer: ${data['chofer']}'),
                            Text('Fecha: ${data['fecha']}'),
                            Text('Hora: ${data['hora']}'),
                            Text('Correo: ${data['correo']}'),
                            Text('Teléfono: ${data['telefono']}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
