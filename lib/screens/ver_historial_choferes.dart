import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VerHistorialChoferes extends StatelessWidget {
  final String nombreChofer;

  const VerHistorialChoferes({super.key, required this.nombreChofer});

  String formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de $nombreChofer'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('historial') // ← colección nueva
                .where('nombre_de_usuario', isEqualTo: nombreChofer)
                .orderBy('fecha_inicio_sesion', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay historial disponible.'));
          }

          final historial = snapshot.data!.docs;

          return ListView.builder(
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final datos = historial[index].data() as Map<String, dynamic>;
              final unidad = datos['unidad'] ?? 'Desconocida';
              final placas = datos['placas'] ?? 'Sin placas';
              final fecha = datos['fecha_inicio_sesion'] as Timestamp;

              return ListTile(
                title: Text('Unidad: $unidad'),
                subtitle: Text(
                  'Placas: $placas\nInicio: ${formatearFecha(fecha)}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
