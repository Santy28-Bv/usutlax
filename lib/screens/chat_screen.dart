import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:usutlax/providers/configuracion_provider.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _emojiVisible = false;
  String? _editingMessageId;
  final TextEditingController _editController = TextEditingController();

  String getChatId() {
    return widget.currentUserId.hashCode <= widget.otherUserId.hashCode
        ? "${widget.currentUserId}_${widget.otherUserId}"
        : "${widget.otherUserId}_${widget.currentUserId}";
  }

  void _enviarMensaje() async {
    if (_controller.text.trim().isEmpty) return;
    final chatId = getChatId();

    await FirebaseFirestore.instance
        .collection('mensajes')
        .doc(chatId)
        .collection('chat')
        .add({
          "emisorId": widget.currentUserId,
          "receptorId": widget.otherUserId,
          "texto": _controller.text.trim(),
          "timestamp": FieldValue.serverTimestamp(),
          "estado": "enviado",
          "editado": false,
          "eliminado": false,
          "tipo": "texto",
          "ocultoPara": [],
        });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _actualizarEstadoMensaje(DocumentSnapshot doc, String nuevoEstado) {
    final data = doc.data() as Map<String, dynamic>;
    final estadoActual = data.containsKey('estado') ? data['estado'] : null;

    if (estadoActual != nuevoEstado) {
      doc.reference.update({'estado': nuevoEstado});
    }
  }

  void _eliminarParaTodos(String messageId) async {
    final chatId = getChatId();
    await FirebaseFirestore.instance
        .collection("mensajes")
        .doc(chatId)
        .collection("chat")
        .doc(messageId)
        .update({"texto": "Mensaje eliminado", "eliminado": true});
  }

  void _eliminarParaMi(String messageId) async {
    final chatId = getChatId();
    await FirebaseFirestore.instance
        .collection("mensajes")
        .doc(chatId)
        .collection("chat")
        .doc(messageId)
        .update({
          "ocultoPara": FieldValue.arrayUnion([widget.currentUserId]),
        });
  }

  void _editarMensaje(String messageId, String oldText) {
    _editController.text = oldText;
    setState(() {
      _editingMessageId = messageId;
    });
  }

  void _guardarEdicion() async {
    if (_editController.text.trim().isEmpty) return;

    final chatId = getChatId();
    await FirebaseFirestore.instance
        .collection("mensajes")
        .doc(chatId)
        .collection("chat")
        .doc(_editingMessageId)
        .update({"texto": _editController.text.trim(), "editado": true});

    setState(() {
      _editingMessageId = null;
    });
    _editController.clear();
  }

  // ✅ Ahora vacía solo para mí (no borra mensajes de la otra persona)
  void _vaciarChat() async {
    final chatId = getChatId();
    final mensajes =
        await FirebaseFirestore.instance
            .collection("mensajes")
            .doc(chatId)
            .collection("chat")
            .get();

    for (var doc in mensajes.docs) {
      await doc.reference.update({
        "ocultoPara": FieldValue.arrayUnion([widget.currentUserId]),
      });
    }
  }

  String _formatearFecha(DateTime fecha, BuildContext context) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    if (DateFormat("yyyyMMdd").format(fecha) ==
        DateFormat("yyyyMMdd").format(hoy)) {
      return "Hoy";
    } else if (DateFormat("yyyyMMdd").format(fecha) ==
        DateFormat("yyyyMMdd").format(ayer)) {
      return "Ayer";
    } else {
      return DateFormat("EEEE d MMM", "es_ES").format(fecha);
    }
  }

  Widget _buildCheckMarks(String estado, bool isDark) {
    switch (estado) {
      case "enviado":
        return Icon(Icons.check, size: 16, color: Colors.grey);
      case "entregado":
        return Icon(Icons.done_all, size: 16, color: Colors.grey);
      case "leido":
        return Icon(
          Icons.done_all,
          size: 16,
          color: isDark ? Colors.white : Colors.black,
        );
      default:
        return Icon(Icons.access_time, size: 14, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatId = getChatId();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _vaciarChat,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage("assets/img/profile.png"),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: TextStyle(
                  fontSize: config.tamanoTextoPx,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🟦 MENSAJES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('mensajes')
                      .doc(chatId)
                      .collection('chat')
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                String? ultimaFecha;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    final esMio = msg['emisorId'] == widget.currentUserId;

                    final ocultoPara =
                        (msg['ocultoPara'] as List<dynamic>? ?? []);
                    if (ocultoPara.contains(widget.currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    if (!esMio && msg['estado'] != "leido") {
                      _actualizarEstadoMensaje(doc, "leido");
                    }

                    if (esMio && msg['estado'] == "enviado") {
                      _actualizarEstadoMensaje(doc, "entregado");
                    }

                    String? encabezado;
                    if (msg['timestamp'] != null) {
                      final fecha = (msg['timestamp'] as Timestamp).toDate();
                      final fechaFormateada = _formatearFecha(fecha, context);
                      if (ultimaFecha != fechaFormateada) {
                        ultimaFecha = fechaFormateada;
                        encabezado = fechaFormateada;
                      }
                    }

                    return Column(
                      children: [
                        if (encabezado != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              encabezado,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (_) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (esMio && msg['eliminado'] != true)
                                        ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text("Editar"),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _editarMensaje(
                                              doc.id,
                                              msg['texto'],
                                            );
                                          },
                                        ),
                                      if (esMio && msg['eliminado'] != true)
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            "Eliminar para todos",
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _eliminarParaTodos(doc.id);
                                          },
                                        ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete_sweep,
                                          color: Colors.orange,
                                        ),
                                        title: const Text("Eliminar para mí"),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _eliminarParaMi(doc.id);
                                        },
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment:
                                  esMio
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                              children: [
                                if (!esMio)
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundImage: AssetImage(
                                      "assets/img/profile.png",
                                    ),
                                  ),
                                if (!esMio) const SizedBox(width: 6),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient:
                                          esMio
                                              ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF4A90E2),
                                                  Color(0xFF357ABD),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                              : null,
                                      color:
                                          esMio
                                              ? null
                                              : (isDark
                                                  ? Colors.grey[850]
                                                  : Colors.white),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: Radius.circular(
                                          esMio ? 16 : 0,
                                        ),
                                        bottomRight: Radius.circular(
                                          esMio ? 0 : 16,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          msg['texto'] ?? '',
                                          style: TextStyle(
                                            fontSize:
                                                config.tamanoTextoPx * 0.9,
                                            fontStyle:
                                                msg['eliminado'] == true
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                            color:
                                                msg['eliminado'] == true
                                                    ? Colors.grey
                                                    : esMio
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white
                                                        : Colors.black87),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              msg['timestamp'] != null
                                                  ? (config.formato24hrs
                                                      ? DateFormat(
                                                        "HH:mm",
                                                      ).format(
                                                        (msg['timestamp']
                                                                as Timestamp)
                                                            .toDate(),
                                                      )
                                                      : DateFormat(
                                                        "hh:mm a",
                                                      ).format(
                                                        (msg['timestamp']
                                                                as Timestamp)
                                                            .toDate(),
                                                      ))
                                                  : "--:--",
                                              style: TextStyle(
                                                fontSize:
                                                    config.tamanoTextoPx * 0.7,
                                                color:
                                                    esMio
                                                        ? Colors.white70
                                                        : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // ✅ Palomitas SOLO en mis mensajes
                                            if (esMio)
                                              _buildCheckMarks(
                                                msg['estado'] ?? "enviado",
                                                isDark,
                                              ),
                                            if (msg['editado'] == true)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: Text(
                                                  "(editado)",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 🟦 INPUT MENSAJE
          SafeArea(
            child: Column(
              children: [
                if (_editingMessageId != null)
                  Container(
                    color: Colors.amber.withOpacity(0.2),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _editController,
                            decoration: const InputDecoration(
                              hintText: "Editar mensaje...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: _guardarEdicion,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _editingMessageId = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _emojiVisible = !_emojiVisible;
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Escribe un mensaje...",
                            filled: true,
                            fillColor: isDark ? Colors.grey[850] : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.attach_file,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Función de multimedia pronto 🔜"),
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _enviarMensaje,
                        ),
                      ),
                    ],
                  ),
                ),
                Offstage(
                  offstage: !_emojiVisible,
                  child: SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      textEditingController: _controller,
                      config: Config(
                        height: 250,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 28,
                          columns: 7,
                          backgroundColor:
                              isDark ? Colors.grey[900]! : Colors.white,
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor:
                              isDark ? Colors.grey[850]! : Colors.grey[200]!,
                        ),
                        skinToneConfig: const SkinToneConfig(enabled: true),
                        viewOrderConfig: const ViewOrderConfig(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
