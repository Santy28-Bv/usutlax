import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? usuarioId;
  String rol = "";
  String? fotoUrl;

  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    usuarioId = prefs.getString("usuarioId");
    rol = prefs.getString("rol") ?? "";

    if (usuarioId == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection("gestion_usuarios")
            .doc(usuarioId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nombreController.text = data['nombre'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _edadController.text = data['edad']?.toString() ?? '';
        _emailController.text = data['email'] ?? '';
        fotoUrl = data['fotoUrl']; // 👈 Cargar la foto si existe
      });
    }
  }

  Future<void> _subirFoto() async {
    if (usuarioId == null || usuarioId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: usuarioId es nulo o vacío")),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen == null) return;

    try {
      final ref = FirebaseStorage.instance.ref().child(
        "perfiles/$usuarioId.jpg",
      );

      print("📌 Subiendo a: perfiles/$usuarioId.jpg");

      final uploadTask = await ref.putFile(File(imagen.path));

      final url = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("gestion_usuarios")
          .doc(usuarioId)
          .update({"fotoUrl": url});

      setState(() {
        fotoUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto actualizada con éxito")),
      );
    } on FirebaseException catch (e) {
      print("❌ Error Firebase: ${e.code} - ${e.message}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error Firebase: ${e.message}")));
    } catch (e) {
      print("❌ Error inesperado: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final esChofer = rol.toLowerCase() == "chofer";
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📸 Foto de perfil
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage:
                      fotoUrl != null
                          ? NetworkImage(fotoUrl!)
                          : const AssetImage("assets/img/profile.png")
                              as ImageProvider,
                  backgroundColor:
                      esOscuro ? Colors.grey[800] : Colors.grey[200],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: esOscuro ? Colors.grey[700] : Colors.white,
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        color: esOscuro ? Colors.white : Colors.black,
                      ),
                      onPressed: _subirFoto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📝 Campos
            _buildField(
              "Nombre y Apellidos",
              _nombreController,
              !esChofer,
              esOscuro,
            ),
            _buildField("Teléfono", _telefonoController, !esChofer, esOscuro),
            _buildField("Dirección", _direccionController, !esChofer, esOscuro),
            _buildField("Edad", _edadController, !esChofer, esOscuro),
            _buildField("Email", _emailController, !esChofer, esOscuro),

            if (!esChofer)
              _buildField(
                "Contraseña",
                _passwordController,
                true,
                esOscuro,
                obscure: true,
              ),

            const SizedBox(height: 20),

            // 👮 Botones solo si NO es chofer
            if (!esChofer)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _guardarCambios,
                    child: const Text("Aceptar"),
                  ),
                ],
              ),

            if (esChofer)
              Text(
                "Los choferes no pueden editar su perfil. Si hay algún problema con tu información contacta a un administrador.",
                style: TextStyle(
                  color: esOscuro ? Colors.grey[400] : Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool editable,
    bool esOscuro, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        enabled: editable,
        obscureText: obscure,
        style: TextStyle(color: esOscuro ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: esOscuro ? Colors.white70 : Colors.black87,
          ),
          filled: true,
          fillColor: esOscuro ? Colors.grey[850] : Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: esOscuro ? Colors.white54 : Colors.black54,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: esOscuro ? Colors.lightBlueAccent : Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCambios() async {
    if (usuarioId == null) return;

    await FirebaseFirestore.instance
        .collection("gestion_usuarios")
        .doc(usuarioId)
        .update({
          "nombre": _nombreController.text,
          "telefono": _telefonoController.text,
          "direccion": _direccionController.text,
          "edad": int.tryParse(_edadController.text) ?? 0,
          "email": _emailController.text,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Datos actualizados")));
  }
}
