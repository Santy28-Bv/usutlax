import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
  final _usuarioController = TextEditingController();
  final _unidadController = TextEditingController();
  bool _esPosturero = false;

  bool _modoFormulario = false;
  bool _modoEdicion = false;
  String _busqueda = '';
  String? _idEditar;

  String generarHash(String contrasena) {
    final bytes = utf8.encode(contrasena);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _toggleFormulario({bool edicion = false, DocumentSnapshot? chofer}) {
    setState(() {
      _modoFormulario = !_modoFormulario;
      _modoEdicion = edicion;
      if (edicion && chofer != null) {
        _idEditar = chofer.id;
        _nombreController.text = chofer['nombre'];
        _telefonoController.text = chofer['telefono'];
        _direccionController.text = chofer['direccion'];
        _edadController.text = chofer['edad'].toString();
        _correoController.text = chofer['correo_electronico'];
        _contrasenaController.text = ''; // Se vacía para no mostrar hash
        _usuarioController.text = chofer['nombre_de_usuario'];
        _unidadController.text = chofer['unidad'];
        _esPosturero = chofer['tipo de operador'] == 'Posturero';
      } else {
        _limpiarCampos();
      }
    });
  }

  void _limpiarCampos() {
    _idEditar = null;
    _nombreController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    _edadController.clear();
    _correoController.clear();
    _contrasenaController.clear();
    _usuarioController.clear();
    _unidadController.clear();
    _esPosturero = false;
  }

  bool _formularioValido() {
    return _nombreController.text.isNotEmpty &&
        _telefonoController.text.isNotEmpty &&
        _direccionController.text.isNotEmpty &&
        _edadController.text.isNotEmpty &&
        _correoController.text.isNotEmpty &&
        _contrasenaController.text.isNotEmpty &&
        _usuarioController.text.isNotEmpty &&
        _unidadController.text.isNotEmpty;
  }

  Future<void> _guardarChoferConfirmado() async {
    final datos = {
      'nombre': _nombreController.text,
      'telefono': _telefonoController.text,
      'direccion': _direccionController.text,
      'edad': int.tryParse(_edadController.text) ?? 0,
      'correo_electronico': _correoController.text,
      'contrasena': generarHash(_contrasenaController.text),
      'nombre_de_usuario': _usuarioController.text,
      'unidad': _unidadController.text,
      'tipo de operador': _esPosturero ? 'Posturero' : 'Planta',
    };

    try {
      if (_modoEdicion && _idEditar != null) {
        await FirebaseFirestore.instance
            .collection('gestion_choferes')
            .doc(_idEditar)
            .update(datos);
      } else {
        await FirebaseFirestore.instance
            .collection('gestion_choferes')
            .add(datos);
      }

      await FirebaseFirestore.instance.collection('historial_unidades').add({
        'nombre_de_usuario': _usuarioController.text,
        'unidad': _unidadController.text,
        'fecha': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion ? 'Chofer actualizado' : 'Chofer guardado',
          ),
        ),
      );

      _toggleFormulario();
    } catch (e) {
      _toggleFormulario();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _guardarChofer() {
    if (!_formularioValido()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, llena todos los campos')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmación'),
            content: const Text(
              '¿Estás seguro de que quieres guardar este chofer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _guardarChoferConfirmado();
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _eliminarChofer(String docId) async {
    await FirebaseFirestore.instance
        .collection('gestion_choferes')
        .doc(docId)
        .delete();
  }

  void _mostrarHistorial(String usuario) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('historial_unidades')
                  .where('nombre_de_usuario', isEqualTo: usuario)
                  .orderBy('fecha', descending: true)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('No hay historial disponible.')),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final unidad = data['unidad'];
                final fecha = (data['fecha'] as Timestamp).toDate();
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('Unidad: $unidad'),
                  subtitle: Text('Fecha: $fecha'),
                );
              },
            );
          },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _modoFormulario
              ? (_modoEdicion ? 'Editar Chofer' : 'Añadir Chofer')
              : 'Gestión de Choferes',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Times New Roman',
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body:
          _modoFormulario
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _campoConIcono(Icons.person, 'Nombre', _nombreController),
                    _campoConIcono(
                      Icons.phone,
                      'Teléfono',
                      _telefonoController,
                      teclado: TextInputType.number,
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
                    _campoConIcono(
                      Icons.account_circle,
                      'Nombre de usuario',
                      _usuarioController,
                    ),
                    _campoConIcono(
                      Icons.local_shipping,
                      'Unidad',
                      _unidadController,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleFormulario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _guardarChofer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Guardar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      onChanged: (valor) {
                        setState(() => _busqueda = valor.toLowerCase());
                      },
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs =
                            snapshot.data!.docs.where((doc) {
                              final nombre =
                                  doc['nombre'].toString().toLowerCase();
                              final usuario =
                                  doc['nombre_de_usuario']
                                      .toString()
                                      .toLowerCase();
                              return nombre.contains(_busqueda) ||
                                  usuario.contains(_busqueda);
                            }).toList();

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('No hay choferes registrados.'),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final chofer = docs[index];
                            final nombre = chofer['nombre'];
                            final direccion = chofer['direccion'];
                            final correo = chofer['correo_electronico'];
                            final edad = chofer['edad'];
                            final telefono = chofer['telefono'];
                            final tipo = chofer['tipo de operador'];
                            final unidad = chofer['unidad'];
                            final usuario = chofer['nombre_de_usuario'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chofer: Unidad $unidad',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(nombre),
                                    Text('Usuario: $usuario'),
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
                                          onPressed:
                                              () => _mostrarHistorial(usuario),
                                          child: const Text('Ver historial'),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.indigo,
                                          ),
                                          onPressed:
                                              () => _toggleFormulario(
                                                edicion: true,
                                                chofer: chofer,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _eliminarChofer(chofer.id),
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
      floatingActionButton:
          _modoFormulario
              ? null
              : FloatingActionButton(
                onPressed: () => _toggleFormulario(edicion: false),
                backgroundColor: Colors.black,
                child: const Icon(Icons.add, color: Colors.white),
              ),
    );
  }
}
