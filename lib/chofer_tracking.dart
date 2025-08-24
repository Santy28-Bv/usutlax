import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChoferTrackingScreen extends StatefulWidget {
  final String choferId; // 👈 el ID del chofer en Firestore

  const ChoferTrackingScreen({super.key, required this.choferId});

  @override
  State<ChoferTrackingScreen> createState() => _ChoferTrackingScreenState();
}

class _ChoferTrackingScreenState extends State<ChoferTrackingScreen> {
  StreamSubscription<Position>? _positionStream;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _iniciarEnvioUbicacion();
  }

  Future<void> _iniciarEnvioUbicacion() async {
    bool permisoConcedido = await _verificarPermisos();
    if (!permisoConcedido) return;

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 👈 cada 10 metros actualiza
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      setState(() => _enviando = true);

      // Guardar en subcolección "ubicaciones"
      await FirebaseFirestore.instance
          .collection("gestion_usuarios")
          .doc(widget.choferId)
          .collection("ubicaciones")
          .doc("actual") // 👈 siempre sobreescribe la última
          .set({
            "lat": position.latitude,
            "lng": position.longitude,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
          });

      setState(() => _enviando = false);
    });
  }

  Future<bool> _verificarPermisos() async {
    bool habilitado = await Geolocator.isLocationServiceEnabled();
    if (!habilitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activa el GPS para continuar")),
      );
      return false;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return false;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El permiso de ubicación está bloqueado")),
      );
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS Chofer")),
      body: Center(
        child:
            _enviando
                ? const Text("📡 Enviando ubicación en tiempo real...")
                : const Text("Esperando ubicación..."),
      ),
    );
  }
}
