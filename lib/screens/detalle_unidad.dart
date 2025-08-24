import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:usutlax/widgets/drawer.dart' show DashboardDrawer;

import '../providers/configuracion_provider.dart';

class DetalleUnidadScreen extends StatefulWidget {
  final String unidad;

  const DetalleUnidadScreen({super.key, required this.unidad});

  @override
  State<DetalleUnidadScreen> createState() => _DetalleUnidadScreenState();
}

class _DetalleUnidadScreenState extends State<DetalleUnidadScreen> {
  String _busqueda = '';

  String formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // 👈 centramos el título
        title: Text(
          'UNIDAD ${widget.unidad}',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: config.modoOscuro ? Colors.black87 : Colors.white,

        // 🔙 Flecha de regresar
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        // ☰ Menú que abre el Drawer
        actions: [
          Builder(
            builder:
                (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: config.modoOscuro ? Colors.white : Colors.black,
                  ),
                  onPressed:
                      () => Scaffold.of(ctx).openDrawer(), // 👈 abre el drawer
                ),
          ),
        ],
      ),

      // 👇 Drawer conectado
      drawer: const DashboardDrawer(),

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
                      .collection('historial')
                      .where('unidad', isEqualTo: widget.unidad)
                      .orderBy('fecha_inicio_sesion', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final historial =
                    snapshot.data!.docs.where((doc) {
                      final chofer =
                          (doc['chofer'] ?? '').toString().toLowerCase();
                      return chofer.contains(_busqueda);
                    }).toList();

                if (historial.isEmpty) {
                  return const Center(child: Text('No hay historial.'));
                }

                return ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final data =
                        historial[index].data() as Map<String, dynamic>;
                    final fecha = formatearFecha(data['fecha_inicio_sesion']);

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
                            Text('Placas: ${data['placas'] ?? 'N/D'}'),
                            Text('Fecha y hora: $fecha'),
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
