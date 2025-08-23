import 'package:flutter/material.dart';

class ConfiguracionProvider extends ChangeNotifier {
  bool _modoOscuro = false;
  String _tamanoTexto = "Mediano";

  bool get modoOscuro => _modoOscuro;
  String get tamanoTexto => _tamanoTexto;

  void toggleModoOscuro(bool value) {
    _modoOscuro = value;
    notifyListeners(); // 🔔 Notificar a toda la app
  }

  void cambiarTamanoTexto(String nuevo) {
    _tamanoTexto = nuevo;
    notifyListeners(); // 🔔 Notificar a toda la app
  }

  // Ajustar tamaño real de fuente
  double get fontSize {
    switch (_tamanoTexto) {
      case "Pequeño":
        return 14;
      case "Grande":
        return 20;
      default:
        return 16;
    }
  }
}
