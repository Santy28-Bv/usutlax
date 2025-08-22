import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class GestionUsuariosScreen extends StatefulWidget {
  final String rol; // <-- agregar esta propiedad

  const GestionUsuariosScreen({
    super.key,
    required this.rol,
  }); // <-- agregar parámetro requerido

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _unidadController = TextEditingController();
  final _edadController = TextEditingController(); // Ahora edad es TextField
  final TextEditingController _searchController = TextEditingController();

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

        // Leer datos de forma segura
        final data = (chofer.data() as Map<String, dynamic>?) ?? {};

        _nombreController.text = data['nombre']?.toString() ?? '';
        _telefonoController.text = data['telefono']?.toString() ?? '';
        _direccionController.text = data['direccion']?.toString() ?? '';
        _edadController.text = data['edad']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _passwordController.text = '';
        _usuarioController.text = data['nombre_de_usuario']?.toString() ?? '';
        _unidadController.text = data['unidad']?.toString() ?? '';
        _esPosturero =
            (data['tipo de operador']?.toString() ?? '') == 'Posturero';
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
    _emailController.clear();
    _passwordController.clear();
    _usuarioController.clear();
    _unidadController.clear();
    _edadController.clear();
    _esPosturero = false;
  }

  bool _formularioValido() {
    return _nombreController.text.isNotEmpty &&
        _direccionController.text.isNotEmpty &&
        _edadController.text.isNotEmpty &&
        // no hace falta_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _usuarioController.text.isNotEmpty &&
        _unidadController.text.isNotEmpty &&
        _telefonoController.text.isNotEmpty;
  }

  //aki
  Future<void> _guardarChoferConfirmado() async {
    final usuario = _usuarioController.text.trim();
    final emailInput = _emailController.text.trim();
    final String? email = emailInput.isEmpty ? null : emailInput;

    final edad = int.tryParse(_edadController.text);
    if (edad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edad inválida. Debe ser un número entero.'),
        ),
      );
      return;
    }

    // Consulta para nombre de usuario (siempre)
    final snapUsuario =
        await FirebaseFirestore.instance
            .collection('gestion_usuarios')
            .where('nombre_de_usuario', isEqualTo: usuario)
            .get();

    bool usuarioExiste = false;
    bool emailExiste = false;

    if (email != null) {
      // Solo consultamos correo si se proporcionó uno (evita comparar cadenas vacías)
      final snapEmail =
          await FirebaseFirestore.instance
              .collection('gestion_usuarios')
              .where('email', isEqualTo: email)
              .get();

      if (_modoEdicion && _idEditar != null) {
        usuarioExiste = snapUsuario.docs.any((doc) => doc.id != _idEditar);
        emailExiste = snapEmail.docs.any((doc) => doc.id != _idEditar);
      } else {
        usuarioExiste = snapUsuario.docs.isNotEmpty;
        emailExiste = snapEmail.docs.isNotEmpty;
      }
    } else {
      // No hay email proporcionado -> no considerar duplicado de email
      if (_modoEdicion && _idEditar != null) {
        usuarioExiste = snapUsuario.docs.any((doc) => doc.id != _idEditar);
      } else {
        usuarioExiste = snapUsuario.docs.isNotEmpty;
      }
      emailExiste = false;
    }

    // Casos de error combinados con mensajes claros:
    if (usuarioExiste && emailExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El correo y el usuario ya existen.')),
      );
      return;
    } else if (usuarioExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion
                ? 'No puedes cambiar el nombre de usuario porque ya lo tiene otro usuario.'
                : 'Este nombre de usuario ya existe, crea otro.',
          ),
        ),
      );
      return;
    } else if (emailExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion
                ? 'No puedes cambiar el correo porque ya lo tiene otro usuario.'
                : 'Este correo electrónico ya existe, crea otro.',
          ),
        ),
      );
      return;
    }

    // Armamos datos: no añadimos 'email' aquí aún
    final Map<String, dynamic> datos = {
      'nombre': _nombreController.text,
      'telefono': _telefonoController.text,
      'direccion': _direccionController.text,
      'edad': edad,
      'password': generarHash(_passwordController.text),
      'nombre_de_usuario': usuario,
      'unidad': _unidadController.text,
      'tipo de operador': _esPosturero ? 'Posturero' : 'Planta',
      'rol': 'chofer',
    };

    try {
      if (_modoEdicion && _idEditar != null) {
        // En edición: si se ingresó email lo actualizamos; si quedó vacío, lo eliminamos del documento
        if (email != null) {
          datos['email'] = email;
        } else {
          // elimina el campo 'email' en Firestore
          datos['email'] = FieldValue.delete();
        }

        await FirebaseFirestore.instance
            .collection('gestion_usuarios')
            .doc(_idEditar)
            .update(datos);
      } else {
        // Creación: solo añadimos email si fue proporcionado
        if (email != null) {
          datos['email'] = email;
        }
        await FirebaseFirestore.instance
            .collection('gestion_usuarios')
            .add(datos);
      }

      await FirebaseFirestore.instance.collection('historial').add({
        'chofer': usuario,
        'unidad': _unidadController.text,
        'fecha_inicio_sesion': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion ? 'Chofer actualizado' : 'Chofer guardado',
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion ? 'Chofer actualizado' : 'Chofer guardado',
          ),
        ),
      );

      // Cerrar formulario
      _toggleFormulario();

      // Limpiar búsqueda en el cuadro de texto
      _searchController.clear();

      // Limpiar filtro de búsqueda para que deje de mostrar solo el resultado anterior
      setState(() {
        _busqueda = '';
      });
    } catch (e) {
      _toggleFormulario();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _guardarChofer() {
    final unidad = _unidadController.text.trim();

    if (unidad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de unidad es obligatorio')),
      );
      return;
    }

    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(unidad)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El número de unidad no debe comenzar con 0'),
        ),
      );
      return;
    }

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
        .collection('gestion_usuarios')
        .doc(docId)
        .delete();
  }

  void _mostrarHistorial(String usuario) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('historial')
                    .where('chofer', isEqualTo: usuario) // CAMBIO AQUÍ
                    .orderBy('fecha_inicio_sesion', descending: true)
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
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final unidad = data['unidad'] ?? 'Sin unidad';
                  final placas = data['placas'] ?? 'Sin placas';
                  final fechaTimestamp =
                      data['fecha_inicio_sesion'] as Timestamp?;
                  final fecha =
                      fechaTimestamp != null
                          ? DateFormat(
                            'dd/MM/yyyy – HH:mm',
                          ).format(fechaTimestamp.toDate())
                          : 'Fecha desconocida';

                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text('Unidad: $unidad | Placas: $placas'),
                    subtitle: Text('Fecha: $fecha'),
                  );
                },
              );
            },
          ),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: oculto,
        keyboardType: teclado,
        inputFormatters: inputFormatters,
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
                      Icons.account_circle,
                      'Nombre de usuario',
                      _usuarioController,
                    ),
                    _campoConIcono(
                      Icons.email,
                      'Email (opcional si el chofer no tiene correo)',
                      _emailController,
                      teclado: TextInputType.emailAddress,
                    ),
                    _campoConIcono(
                      Icons.lock,
                      'Contraseña',
                      _passwordController,
                      oculto: true,
                    ),
                    // Edad con sólo números
                    _campoConIcono(
                      Icons.cake,
                      'Edad',
                      _edadController,
                      teclado: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    _campoConIcono(
                      Icons.location_on,
                      'Dirección',
                      _direccionController,
                    ),
                    _campoConIcono(
                      Icons.phone,
                      'Teléfono',
                      _telefonoController,
                      teclado: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    _campoConIcono(
                      Icons.local_shipping,
                      'Unidad',
                      _unidadController,
                      teclado: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _esPosturero,
                          onChanged:
                              (val) =>
                                  setState(() => _esPosturero = val ?? false),
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
                      controller: _searchController, // <-- aquí
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
                              .collection('gestion_usuarios')
                              .orderBy(
                                'nombre',
                              ) // <-- orden alfabético por campo 'nombre'
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['rol'] != 'chofer') return false;

                              final nombre =
                                  data['nombre'].toString().toLowerCase();
                              final usuario =
                                  data['nombre_de_usuario']
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
                            // Leer datos de forma segura como Map (evita excepción si no existe alguna clave)
                            final data =
                                (chofer.data() as Map<String, dynamic>?) ?? {};

                            final nombre = data['nombre']?.toString() ?? '';
                            final direccion =
                                data['direccion']?.toString() ?? '';
                            final email = data['email']?.toString() ?? '';
                            final edad = data['edad']?.toString() ?? '';
                            final telefono = data['telefono']?.toString() ?? '';
                            final tipo =
                                data['tipo de operador']?.toString() ?? '';
                            final unidad = data['unidad']?.toString() ?? '';
                            final usuario =
                                data['nombre_de_usuario']?.toString() ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chofer: Unidad Actual $unidad',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(nombre),
                                    Text('Usuario: $usuario'),
                                    Text('Dirección: $direccion'),
                                    Text(
                                      'Email: ${email.isEmpty ? "Sin email" : email}',
                                    ),
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
//YA FUNCIONA CON USUARIOS,
//crea otra collecion en historial

//fecha_inicio_sesion
//16 de julio de 2025, 1:58:19 p.m. UTC-6
//(marca de tiempo)


//nombre_de_usuario
//"GeraPZT"
//(cadena)


//unidad
//"2"