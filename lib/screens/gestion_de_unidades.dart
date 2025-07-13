import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/drawer.dart';
import '../widgets/bottom_menu.dart';
import 'detalle_unidad.dart';
import '/main_menu.dart';

class GestionDeUnidadesScreen extends StatefulWidget {
  const GestionDeUnidadesScreen({super.key});

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
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Menú principal',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
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
                  FirebaseFirestore.instance.collection('unidades').snapshots(),
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
                        final numA =
                            int.tryParse(
                              a['numero_unidad'].toString().replaceAll(
                                RegExp(r'\D'),
                                '',
                              ),
                            ) ??
                            0;
                        final numB =
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
                    final id = unidad.id;
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            DetalleUnidadScreen(unidad: numero),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editarUnidad(unidad),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _eliminarUnidad(id),
                            ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _mostrarFormularioUnidad,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomMenu(),
    );
  }

  // Mostrar formulario para agregar unidad
  void _mostrarFormularioUnidad() {
    final _colorController = TextEditingController();
    final _numeroController = TextEditingController();
    final _placasController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar Unidad'),
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
                  decoration: const InputDecoration(
                    labelText: 'Color (rojo, verde, etc.)',
                  ),
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

                  try {
                    await FirebaseFirestore.instance.collection('unidades').add(
                      {
                        'color': color,
                        'numero_unidad': numero,
                        'placas': placas,
                      },
                    );
                    Navigator.pop(context);
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

  // Mostrar formulario para editar unidad
  void _editarUnidad(QueryDocumentSnapshot unidad) {
    final _colorController = TextEditingController(text: unidad['color']);
    final _numeroController = TextEditingController(
      text: unidad['numero_unidad'],
    );
    final _placasController = TextEditingController(text: unidad['placas']);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar Unidad'),
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
                  try {
                    await FirebaseFirestore.instance
                        .collection('unidades')
                        .doc(unidad.id)
                        .update({
                          'color': _colorController.text.trim(),
                          'numero_unidad': _numeroController.text.trim(),
                          'placas': _placasController.text.trim(),
                        });
                    Navigator.pop(context);
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al editar: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  // Eliminar unidad
  void _eliminarUnidad(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('¿Eliminar unidad?'),
            content: const Text('Esta acción no se puede deshacer.'),
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
      await FirebaseFirestore.instance.collection('unidades').doc(id).delete();
    }
  }

  // Color translúcido
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
