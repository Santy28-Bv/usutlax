import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usutlax/main_menu.dart';
import '../widgets/drawer.dart';
import '../widgets/bottom_menu.dart';
import 'detalle_unidad.dart';

class GestionDeUnidadesScreen extends StatefulWidget {
  final String rol;

  const GestionDeUnidadesScreen({
    super.key,
    required this.rol, // ✅ esto inicializa 'rol'
  });

  @override
  State<GestionDeUnidadesScreen> createState() =>
      _GestionDeUnidadesScreenState();
}

class _GestionDeUnidadesScreenState extends State<GestionDeUnidadesScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UNIDADES'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaPrincipal(rol: widget.rol),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const DashboardDrawer(),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaController,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _busqueda = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por número de unidad...',
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
                      .collection('gestion_unidades')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final unidades =
                    snapshot.data!.docs.where((doc) {
                        final numero = doc['numero_unidad'].toString();
                        return numero.contains(_busqueda);
                      }).toList()
                      ..sort((a, b) {
                        int numA =
                            int.tryParse(
                              a['numero_unidad'].toString().replaceAll(
                                RegExp(r'\D'),
                                '',
                              ),
                            ) ??
                            0;
                        int numB =
                            int.tryParse(
                              b['numero_unidad'].toString().replaceAll(
                                RegExp(r'\D'),
                                '',
                              ),
                            ) ??
                            0;
                        return numA.compareTo(numB);
                      });

                return ListView.builder(
                  itemCount: unidades.length,
                  itemBuilder: (context, index) {
                    final unidad = unidades[index];
                    final numero = unidad['numero_unidad'];
                    final placas = unidad['placas'];
                    final color = unidad['color'] ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _obtenerColor(color),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text('UNIDAD $numero'),
                        subtitle: Text('Placas: $placas'),
                        leading: const Icon(Icons.remove_red_eye),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.indigo,
                              ),
                              onPressed: () => _editarUnidad(unidad),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarUnidad(unidad.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DetalleUnidadScreen(unidad: numero),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _mostrarFormularioUnidad,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomMenu(rol: widget.rol), // ✅ se pasa el rol aquí
    );
  }

  void _mostrarFormularioUnidad({DocumentSnapshot? unidadExistente}) {
    final _colorController = TextEditingController(
      text: unidadExistente?['color'] ?? '',
    );
    final _numeroController = TextEditingController(
      text: unidadExistente?['numero_unidad'] ?? '',
    );
    final _placasController = TextEditingController(
      text: unidadExistente?['placas'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              unidadExistente == null ? 'Agregar Unidad' : 'Editar Unidad',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _numeroController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de unidad',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _placasController,
                  decoration: const InputDecoration(labelText: 'Placas'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _colorController,
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final color = _colorController.text.trim();
                  final numero = _numeroController.text.trim();
                  final placas = _placasController.text.trim();

                  if (numero.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El número de unidad es obligatorio'),
                      ),
                    );
                    return;
                  }

                  if (!RegExp(r'^[1-9][0-9]*$').hasMatch(numero)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'El número de unidad no debe comenzar con 0',
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    if (unidadExistente == null) {
                      // Crear nueva unidad
                      await FirebaseFirestore.instance
                          .collection('gestion_unidades')
                          .add({
                            'color': color,
                            'numero_unidad': numero,
                            'placas': placas,
                          });
                    } else {
                      // Actualizar unidad
                      await FirebaseFirestore.instance
                          .collection('gestion_unidades')
                          .doc(unidadExistente.id)
                          .update({
                            'color': color,
                            'numero_unidad': numero,
                            'placas': placas,
                          });

                      // Actualizar historial
                      final historialDocs =
                          await FirebaseFirestore.instance
                              .collection('historial')
                              .where('unidad', isEqualTo: numero)
                              .get();

                      for (var doc in historialDocs.docs) {
                        await doc.reference.update({'placas': placas});
                      }
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unidad guardada correctamente'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _editarUnidad(DocumentSnapshot unidad) {
    _mostrarFormularioUnidad(unidadExistente: unidad);
  }

  void _eliminarUnidad(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar Unidad'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta unidad?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('gestion_unidades')
          .doc(docId)
          .delete();
    }
  }

  Color _obtenerColor(String color) {
    switch (color.toLowerCase()) {
      case 'rojo':
        return Colors.red.withOpacity(0.2);
      case 'verde':
        return Colors.green.withOpacity(0.2);
      case 'amarillo':
        return Colors.yellow.withOpacity(0.2);
      case 'azul':
        return Colors.blue.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }
}
