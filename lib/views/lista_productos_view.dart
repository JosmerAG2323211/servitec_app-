import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EquipoDefectuoso {
  final int id;
  final String nombre;
  final String tipoServicio;
  final String descripcion;
  final Uint8List? fotoInicial;
  final String nombreCliente;
  final String cedulaCliente;
  String estatus;
  Uint8List? fotoActual;

  EquipoDefectuoso({
    required this.id,
    required this.nombre,
    required this.tipoServicio,
    required this.descripcion,
    this.fotoInicial,
    required this.nombreCliente,
    required this.cedulaCliente,
    this.estatus = "Pendiente",
    this.fotoActual,
  });

  factory EquipoDefectuoso.fromJson(Map<String, dynamic> json) {
    return EquipoDefectuoso(
      id: json['id'],
      // Mapeo exacto de los nombres que devuelve tu Backend
      nombre: json['nombre_equipo'] ?? "Sin equipo",
      tipoServicio: json['tipo_servicio'] ?? "General",
      descripcion: json['descripcion'] ?? "",
      nombreCliente: json['nombre_cliente'] ?? "N/A",
      cedulaCliente: json['cedula_cliente'] ?? "N/A",
      estatus: json['estatus'] ?? "Pendiente",
      fotoInicial: json['foto_inicial'] != null
          ? base64Decode(json['foto_inicial'])
          : null,
      fotoActual: json['foto_actual'] != null
          ? base64Decode(json['foto_actual'])
          : null,
    );
  }
}

class ListaProductosView extends StatefulWidget {
  const ListaProductosView({super.key});

  @override
  State<ListaProductosView> createState() => _ListaProductosViewState();
}

class _ListaProductosViewState extends State<ListaProductosView> {
  List<EquipoDefectuoso> _allEquipos = [];
  List<EquipoDefectuoso> _filteredEquipos = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _statusFilter = "Todos";

  // URL base centralizada para evitar errores de localhost
  final String baseUrl =
      "https://servitec-backend-production.up.railway.app/api";

  @override
  void initState() {
    super.initState();
    _fetchServicios();
  }

  Future<void> _fetchServicios() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/servicios'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allEquipos = data.map((e) => EquipoDefectuoso.fromJson(e)).toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error extrayendo datos: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEstatus(int id, String nuevoEstatus) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/actualizar-estatus',
        ), // Asegúrate de que esta ruta exista en tu Node.js
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "estatus": nuevoEstatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Estatus actualizado correctamente")),
        );
      }
    } catch (e) {
      debugPrint("❌ Error actualizando estatus: $e");
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEquipos = _allEquipos.where((equipo) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            equipo.nombre.toLowerCase().contains(query) ||
            equipo.cedulaCliente.contains(query) ||
            equipo.nombreCliente.toLowerCase().contains(query);
        final matchesStatus =
            _statusFilter == "Todos" || equipo.estatus == _statusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Servicios"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchServicios,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchServicios,
                    child: _filteredEquipos.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text("No hay registros disponibles"),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemCount: _filteredEquipos.length,
                            itemBuilder: (context, index) =>
                                _buildEquipoCard(_filteredEquipos[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE INTERFAZ (UI) ---

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: "Buscar por producto, cliente o cédula...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: const InputDecoration(
              labelText: "Filtrar por Estatus",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              "Todos",
              "Pendiente",
              "En proceso",
              "Trabajo tomado",
              "Servicio terminado",
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              _statusFilter = val!;
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEquipoCard(EquipoDefectuoso equipo) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                equipo.fotoInicial != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          equipo.fotoInicial!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          color: Colors.blueGrey,
                        ),
                      ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipo.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Cliente: ${equipo.nombreCliente}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        "C.I: ${equipo.cedulaCliente}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(equipo.estatus),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Text(
              "🔧 ${equipo.tipoServicio}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              equipo.descripcion,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: equipo.estatus,
                    items:
                        [
                              "Pendiente",
                              "En proceso",
                              "Trabajo tomado",
                              "Servicio terminado",
                            ]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() => equipo.estatus = val!);
                      _updateEstatus(equipo.id, val!);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed: () {
                    /* Lógica futura para foto actual */
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == "Servicio terminado") color = Colors.green;
    if (status == "En proceso") color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
