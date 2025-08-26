import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaChoferScreen extends StatefulWidget {
  final String choferId;
  final String nombre;
  final String correo;
  final String telefono;

  // 👉 Puedes pasar la ubicación inicial desde afuera si quieres
  final double? lat;
  final double? lng;

  const MapaChoferScreen({
    super.key,
    required this.choferId,
    required this.nombre,
    required this.correo,
    required this.telefono,
    this.lat,
    this.lng,
  });

  @override
  State<MapaChoferScreen> createState() => _MapaChoferScreenState();
}

class _MapaChoferScreenState extends State<MapaChoferScreen> {
  GoogleMapController? mapController;
  LatLng? ubicacionChofer;

  @override
  void initState() {
    super.initState();

    // ✅ Si pasaste coordenadas al abrir la pantalla, las usamos
    if (widget.lat != null && widget.lng != null) {
      ubicacionChofer = LatLng(widget.lat!, widget.lng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitoreo GPS")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chofer: ${widget.nombre}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Correo: ${widget.correo}"),
                Text("Teléfono: ${widget.telefono}"),
              ],
            ),
          ),
          Expanded(
            child:
                ubicacionChofer == null
                    ? const Center(child: Text("No hay ubicación disponible"))
                    : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: ubicacionChofer!,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId("chofer"),
                          position: ubicacionChofer!,
                          infoWindow: InfoWindow(title: widget.nombre),
                        ),
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text("Regresar"),
            ),
          ),
        ],
      ),
    );
  }
}
