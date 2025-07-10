import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class GestionChoferScreen extends StatefulWidget {
  const GestionChoferScreen({super.key});

  @override
  State<GestionChoferScreen> createState() => _GestionChoferScreenState();
}

class _GestionChoferScreenState extends State<GestionChoferScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _edadController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _esPosturero = false;

  void _mostrarFormulario() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Añadir Chofer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _campoConIcono(
                  Icons.person,
                  'Nombre y Apellidos',
                  _nombreController,
                ),
                _campoConIcono(
                  Icons.phone,
                  'Teléfono',
                  _telefonoController,
                  teclado: TextInputType.phone,
                ),
                _campoConIcono(
                  Icons.location_on,
                  'Dirección',
                  _direccionController,
                ),
                _campoConIcono(
                  Icons.cake,
                  'Edad',
                  _edadController,
                  teclado: TextInputType.number,
                ),
                _campoConIcono(Icons.email, 'Email', _correoController),
                _campoConIcono(
                  Icons.lock,
                  'Contraseña',
                  _contrasenaController,
                  oculto: true,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _esPosturero,
                      onChanged: (val) {
                        setState(() {
                          _esPosturero = val ?? false;
                        });
                      },
                    ),
                    const Expanded(child: Text('¿Es chofer posturero?')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _guardarChofer,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Widget _campoConIcono(
    IconData icono,
    String label,
    TextEditingController controller, {
    TextInputType teclado = TextInputType.text,
    bool oculto = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: oculto,
        keyboardType: teclado,
        decoration: InputDecoration(
          prefixIcon: Icon(icono),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _guardarChofer() async {
    try {
      await FirebaseFirestore.instance.collection('gestion_choferes').add({
        'nombre': _nombreController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'edad': int.tryParse(_edadController.text) ?? 0,
        'correo': _correoController.text,
        'contrasena': _contrasenaController.text,
        'tipo_operador': _esPosturero ? 'Posturero' : 'Planta',
      });

      _nombreController.clear();
      _telefonoController.clear();
      _direccionController.clear();
      _edadController.clear();
      _correoController.clear();
      _contrasenaController.clear();
      _esPosturero = false;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chofer guardado correctamente')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _eliminarChofer(String docId) async {
    await FirebaseFirestore.instance
        .collection('gestion_choferes')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Choferes'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('gestion_choferes')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final chofer = docs[index];
                    final nombre = chofer['nombre'];
                    final direccion = chofer['direccion'];
                    final correo = chofer['correo_electronico']; // ✅ correcto

                    final edad = chofer['edad'];
                    final telefono = chofer['telefono'];
                    final tipo =
                        chofer['tipo de operador']; // 👈 exacto como está en Firestore

                    final unidad = 'Unidad ${index + 1}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chofer: $unidad',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(nombre),
                            Text('Dirección: $direccion'),
                            Text('Correo: $correo'),
                            Text('Edad: $edad'),
                            Text('Teléfono: $telefono'),
                            Text('Tipo de operador: $tipo'),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Ver historial'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.indigo,
                                  ),
                                  onPressed: () {
                                    // Aquí puedes implementar la edición
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _eliminarChofer(chofer.id),
                                ),
                              ],
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
        onPressed: _mostrarFormulario,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
