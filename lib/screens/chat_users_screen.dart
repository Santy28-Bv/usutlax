import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatUsersScreen extends StatefulWidget {
  final String currentUserId;

  const ChatUsersScreen({super.key, required this.currentUserId});

  @override
  State<ChatUsersScreen> createState() => _ChatUsersScreenState();
}

class _ChatUsersScreenState extends State<ChatUsersScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mensajería",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch<String?>(
                context: context,
                delegate: UsuarioSearchDelegate(),
              );
              if (query != null) {
                setState(() {
                  searchQuery = query;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('gestion_usuarios')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users =
              snapshot.data!.docs
                  .where((doc) => doc.id != widget.currentUserId)
                  .toList();

          // 🔍 Filtro de búsqueda
          if (searchQuery.isNotEmpty) {
            users =
                users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre =
                      (data['nombre'] ?? "").toString().toLowerCase();
                  return nombre.contains(searchQuery.toLowerCase());
                }).toList();
          }

          if (users.isEmpty) {
            return Center(
              child: Text(
                "No hay usuarios disponibles",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            );
          }

          // 🔹 Ordenar: primero los que tienen mensajes sin leer
          users.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aUnread = aData['unread_${widget.currentUserId}'] ?? 0;
            final bUnread = bData['unread_${widget.currentUserId}'] ?? 0;
            return bUnread.compareTo(aUnread);
          });

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              final nombre = user['nombre'] ?? "Usuario sin nombre";
              final rol = (user['rol'] ?? "").toLowerCase();
              final unidad = user['unidad'];
              final unread = user['unread_${widget.currentUserId}'] ?? 0;

              // Subtítulo dinámico según rol
              String subtitulo = "";
              if (rol == "chofer" && unidad != null) {
                subtitulo = "Chofer - Unidad $unidad";
              } else if (rol == "admin") {
                subtitulo =
                    "Jefes de Urbanos y Sub Urbanos de Tlaxcala S.A. de C.V.";
              } else if (rol == "despachador") {
                subtitulo =
                    "Despachadores de Urbanos y Sub Urbanos de Tlaxcala S.A. de C.V.";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                color: theme.cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        isDark ? Colors.blueGrey : Colors.blueAccent,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    subtitulo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  trailing:
                      unread > 0
                          ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unread.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : Icon(
                            Icons.chat_bubble_outline,
                            color: isDark ? Colors.white70 : Colors.blueGrey,
                          ),
                  onTap: () async {
                    // 🔴 Resetear los mensajes sin leer al entrar al chat
                    await FirebaseFirestore.instance
                        .collection("gestion_usuarios")
                        .doc(widget.currentUserId)
                        .update({"unread_$userId": 0});

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatScreen(
                              currentUserId: widget.currentUserId,
                              otherUserId: userId,
                              otherUserName: nombre,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 🔎 Delegate para búsqueda
class UsuarioSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(context, query);
    });
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
