import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaChoferScreen extends StatefulWidget {
  final String choferId;
  final String nombre;
  final String correo;
  final String telefono;

  const MapaChoferScreen({
    super.key,
    required this.choferId,
    required this.nombre,
    required this.correo,
    required this.telefono,
  });

  @override
  State<MapaChoferScreen> createState() => _MapaChoferScreenState();
}

class _MapaChoferScreenState extends State<MapaChoferScreen> {
  LatLng? ubicacionChofer;
  GoogleMapController? mapController;

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
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("gestion_usuarios")
                      .doc(widget.choferId)
                      .collection("ubicaciones")
                      .doc("actual") // 👈 aquí guardas la última ubicación
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error al obtener la ubicación"),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text("Esperando ubicación del chofer..."),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                if (data.containsKey("lat") && data.containsKey("lng")) {
                  final lat = (data["lat"] as num).toDouble();
                  final lng = (data["lng"] as num).toDouble();
                  ubicacionChofer = LatLng(lat, lng);

                  // Mover cámara cuando cambie
                  if (mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLng(ubicacionChofer!),
                    );
                  }
                }

                return ubicacionChofer == null
                    ? const Center(child: Text("Esperando ubicación..."))
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
                    );
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
