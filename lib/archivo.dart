import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Importamos main.dart para acceder a LoginScreen si está allí
import 'main.dart';

// Asegúrate de que estas rutas sean las correctas en tu proyecto
import 'views/registrar_producto_view.dart';
import 'views/lista_productos_view.dart';
import 'views/almacen_view.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _viewTitle = "Dashboard";
  late Widget _currentWidget;

  @override
  void initState() {
    super.initState();
    _currentWidget = _buildWelcomeView();
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 80,
            color: Colors.blue.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            "Bienvenido, ${widget.user['usuario'] ?? 'Usuario'}\nSistema de Control Servitec",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _updateView(String title, Widget viewWidget) {
    // Cerramos el drawer primero para evitar errores de contexto
    Navigator.pop(context);

    if (_viewTitle == title) return;

    setState(() {
      _viewTitle = title;
      _currentWidget = viewWidget;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _viewTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      // endDrawer es el menú lateral derecho
      endDrawer: CustomRightDrawer(
        user: widget.user,
        onViewSelected: _updateView,
        currentTitle: _viewTitle,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: KeyedSubtree(
          key: ValueKey<String>(_viewTitle),
          child: _currentWidget,
        ),
      ),
    );
  }
}

class CustomRightDrawer extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function(String, Widget) onViewSelected;
  final String currentTitle;

  const CustomRightDrawer({
    super.key,
    required this.user,
    required this.onViewSelected,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          bottomLeft: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF263238)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(
                (user['usuario'] ?? "U")[0].toUpperCase(),
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
            accountName: Text(user['usuario'] ?? "Usuario"),
            accountEmail: Text(user['correo'] ?? "correo@empresa.com"),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sectionLabel("OPERACIONES"),
                _buildMenuItem(
                  context,
                  icon: Icons.add_box_rounded,
                  title: "Registro",
                  onTap: () =>
                      onViewSelected("Registro", const RegistrarProductoView()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: "Catálogo",
                  onTap: () =>
                      onViewSelected("Catálogo", const ListaProductosView()),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.warehouse_rounded,
                  title: "Stock",
                  onTap: () => onViewSelected("Stock", const AlmacenView()),
                ),
                const SizedBox(height: 20),
                _sectionLabel("ADMINISTRACIÓN"),
                _buildMenuItem(
                  context,
                  icon: Icons.group_rounded,
                  title: "Usuarios",
                  onTap: () => onViewSelected(
                    "Usuarios",
                    UsuariosView(empresaId: user['empresa_id'] ?? 0),
                  ),
                ),
                const Divider(color: Colors.white10),
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: "Cerrar Sesión",
                  color: Colors.redAccent,
                  onTap: () {
                    // Importante: Asegúrate de que LoginScreen esté definida en main.dart
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()),
                      (r) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 15, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final bool isSelected = currentTitle == title;
    return ListTile(
      selected: isSelected,
      leading: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : (color ?? Colors.white54),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : (color ?? Colors.white),
        ),
      ),
      onTap: onTap,
    );
  }
}

class UsuariosView extends StatefulWidget {
  final int empresaId;
  const UsuariosView({super.key, required this.empresaId});
  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  Future<List<dynamic>> obtenerUsuarios() async {
    try {
      // URL de tu API
      String urlBase = 'https://servitec-backend-production.up.railway.app/api';
      final res = await http.get(
        Uri.parse("$urlBase/usuarios/empresa/${widget.empresaId}"),
      );

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Equipo de Trabajo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: obtenerUsuarios(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(
                  child: Text("No hay compañeros registrados"),
                );

              final usuarios = snapshot.data!;
              return ListView.builder(
                itemCount: usuarios.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(
                    child: Text(usuarios[i]['usuario'][0].toUpperCase()),
                  ),
                  title: Text(usuarios[i]['usuario']),
                  subtitle: Text(
                    "${usuarios[i]['rol']} - ${usuarios[i]['correo']}",
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
