import 'package:flutter/material.dart';

class ConfiguracionProvider extends ChangeNotifier {
  // 🔹 Estado
  bool _modoOscuro = false;
  String _tamanoTexto = "Mediano";
  double _tamanoTextoPx = 16.0;

  // ============================
  // Getters
  // ============================
  bool get modoOscuro => _modoOscuro;
  String get tamanoTexto => _tamanoTexto;
  double get tamanoTextoPx => _tamanoTextoPx;

  // Getter auxiliar: devuelve texto según px
  String get tamanoTextoEtiqueta {
    if (_tamanoTextoPx <= 14) return "Pequeño";
    if (_tamanoTextoPx <= 20) return "Mediano";
    return "Grande";
  }

  // ============================
  // Métodos
  // ============================
  void toggleModoOscuro(bool value) {
    _modoOscuro = value;
    notifyListeners();
  }

  // Mantengo método original (elige por texto)
  void cambiarTamanoTexto(String nuevo) {
    _tamanoTexto = nuevo;

    switch (nuevo) {
      case "Pequeño":
        _tamanoTextoPx = 14;
        break;
      case "Grande":
        _tamanoTextoPx = 20;
        break;
      default:
        _tamanoTextoPx = 16;
    }

    notifyListeners();
  }

  // Nuevo: cambia px directamente
  void cambiarTamanoTextoPx(double value) {
    _tamanoTextoPx = value;

    // Mantener sincronizado con etiqueta
    if (value <= 14) {
      _tamanoTexto = "Pequeño";
    } else if (value <= 20) {
      _tamanoTexto = "Mediano";
    } else {
      _tamanoTexto = "Grande";
    }

    notifyListeners();
  }

  // ============================
  // Ajustar tamaño real de fuente
  // ============================
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
