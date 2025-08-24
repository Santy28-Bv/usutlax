import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:usutlax/main_menu.dart';
import '../widgets/drawer.dart';
import '../widgets/bottom_menu.dart';
import 'detalle_unidad.dart';
import '../providers/configuracion_provider.dart';

class GestionDeUnidadesScreen extends StatefulWidget {
  final String rol;

  const GestionDeUnidadesScreen({super.key, required this.rol});

  @override
  State<GestionDeUnidadesScreen> createState() =>
      _GestionDeUnidadesScreenState();
}

class _GestionDeUnidadesScreenState extends State<GestionDeUnidadesScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'UNIDADES',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: config.modoOscuro ? Colors.black87 : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: config.modoOscuro ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaPrincipal(rol: widget.rol),
              ),
            );
          },
        ),
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

      drawer: const DashboardDrawer(),
      backgroundColor: config.modoOscuro ? Colors.black : Colors.white,

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busquedaController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: config.modoOscuro ? Colors.white : Colors.black,
              ),
              onChanged: (value) => setState(() => _busqueda = value.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por número de unidad...',
                hintStyle: TextStyle(
                  color: config.modoOscuro ? Colors.white54 : Colors.black54,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: config.modoOscuro ? Colors.white : Colors.black,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: config.modoOscuro ? Colors.white54 : Colors.black54,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                        title: Text(
                          'UNIDAD $numero',
                          style: TextStyle(
                            color:
                                config.modoOscuro ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Placas: $placas',
                          style: TextStyle(
                            color:
                                config.modoOscuro
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                        leading: Icon(
                          Icons.remove_red_eye,
                          color:
                              config.modoOscuro ? Colors.white : Colors.black,
                        ),
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
      bottomNavigationBar: BottomMenu(rol: widget.rol),
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
                      // ✅ Verificar duplicados antes de agregar
                      final query =
                          await FirebaseFirestore.instance
                              .collection('gestion_unidades')
                              .where('numero_unidad', isEqualTo: numero)
                              .get();

                      if (query.docs.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ya existe una unidad con ese número',
                            ),
                          ),
                        );
                        return;
                      }

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
      // 🔴 Colores base
      case 'rojo':
        return Colors.red.withOpacity(0.2);
      case 'verde':
        return Colors.green.withOpacity(0.2);
      case 'amarillo':
        return Colors.yellow.withOpacity(0.2);
      case 'azul':
        return Colors.blue.withOpacity(0.2);
      case 'morado':
        return Colors.purple.withOpacity(0.2);
      case 'naranja':
        return Colors.orange.withOpacity(0.2);
      case 'rosa':
        return Colors.pink.withOpacity(0.2);
      case 'negro':
        return Colors.black.withOpacity(0.2);
      case 'blanco':
        return Colors.white.withOpacity(0.2);
      case 'gris':
        return Colors.grey.withOpacity(0.2);
      case 'cafe':
      case 'marrón':
        return Colors.brown.withOpacity(0.2);
      case 'cyan':
        return Colors.cyan.withOpacity(0.2);
      case 'lima':
        return Colors.lime.withOpacity(0.2);
      case 'turquesa':
      case 'teal':
        return Colors.teal.withOpacity(0.2);

      // 🌊 Tonos de azul
      case 'celeste':
      case 'azul claro':
      case 'azul cielo':
        return Colors.lightBlue.withOpacity(0.2);
      case 'azul marino':
      case 'azul oscuro':
        return Colors.indigo.withOpacity(0.2);

      // 🔴 Tonos de rojo
      case 'rojo oscuro':
      case 'vino':
      case 'guinda':
        return Colors.red.shade900.withOpacity(0.2);

      // 🟢 Tonos de verde
      case 'verde claro':
        return Colors.lightGreen.withOpacity(0.2);
      case 'verde oscuro':
        return Colors.green.shade900.withOpacity(0.2);

      // 🟡 Tonos amarillos/naranja
      case 'dorado':
        return Colors.amber.withOpacity(0.2);
      case 'mostaza':
        return Colors.yellow.shade700.withOpacity(0.2);

      // 🔮 Tonos morados
      case 'lila':
      case 'violeta':
        return Colors.deepPurple.withOpacity(0.2);

      default:
        return Colors.grey.withOpacity(0.1); // 🔘 fallback
    }
  }
}
