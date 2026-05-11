import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Producto {
  final int? id;
  final String nombre;
  final double precioDolar;
  final int cantidad;
  final Uint8List? fotoBytes;

  Producto({
    this.id,
    required this.nombre,
    required this.precioDolar,
    required this.cantidad,
    this.fotoBytes,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? "Sin nombre",
      // Conversión segura de tipos para evitar que la app se congele
      precioDolar: double.tryParse(json['precio_dolar'].toString()) ?? 0.0,
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      fotoBytes: json['foto'] != null ? base64Decode(json['foto']) : null,
    );
  }
}

class AlmacenView extends StatefulWidget {
  const AlmacenView({super.key});
  @override
  State<AlmacenView> createState() => _AlmacenViewState();
}

class _AlmacenViewState extends State<AlmacenView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Producto> _productos = [];
  bool _cargandoProductos = true;
  double _tasaDolar = 0.0;
  bool _cargandoTasa = true;

  // URL Inteligente: Detecta si es navegador o emulador
  final String apiUrl =
      "https://servitec-backend-production.up.railway.app/api";

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  Uint8List? _imageBytesSelected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _actualizarTasaBCV();
    _obtenerProductos();
  }

  Future<void> _obtenerProductos() async {
    setState(() => _cargandoProductos = true);
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/productos'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _productos = data.map((item) => Producto.fromJson(item)).toList();
          _cargandoProductos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoProductos = false);
      _mostrarSnackBar("Error al conectar con el servidor");
    }
  }

  Future<void> _registrarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (res) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final body = {
        "nombre": _nombreController.text,
        "precio_dolar": _precioController.text.replaceAll(',', '.'),
        "cantidad": _cantidadController.text,
        "empresa_id": 1,
        "foto": _imageBytesSelected != null
            ? base64Encode(_imageBytesSelected!)
            : null,
      };

      final response = await http.post(
        Uri.parse('$apiUrl/productos'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      Navigator.pop(context); // Cerrar loading

      if (response.statusCode == 200) {
        _limpiarFormulario();
        _tabController.animateTo(0);
        _obtenerProductos();
        _mostrarSnackBar("✅ Producto guardado");
      }
    } catch (e) {
      Navigator.pop(context);
      _mostrarSnackBar("❌ Error de red");
    }
  }

  Future<void> _actualizarTasaBCV() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.ateneasoftware.com/api/tasa_cambio/latest'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _tasaDolar = double.parse(json.decode(res.body)['bcv'].toString());
          _cargandoTasa = false;
        });
      }
    } catch (e) {
      setState(() {
        _tasaDolar = 36.50;
        _cargandoTasa = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytesSelected = bytes);
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _precioController.clear();
    _cantidadController.clear();
    setState(() => _imageBytesSelected = null);
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeaderTasa(),
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: "Stock"),
            Tab(icon: Icon(Icons.add), text: "Nuevo"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_vistaListaProductos(), _vistaFormularioRegistro()],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTasa() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Tasa BCV: ${_cargandoTasa ? '...' : 'Bs. $_tasaDolar'}",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _obtenerProductos,
          ),
        ],
      ),
    );
  }

  Widget _vistaListaProductos() {
    if (_cargandoProductos)
      return const Center(child: CircularProgressIndicator());
    if (_productos.isEmpty) return const Center(child: Text("Sin productos"));

    return ListView.builder(
      itemCount: _productos.length,
      itemBuilder: (context, i) {
        final p = _productos[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: p.fotoBytes != null
                ? Image.memory(
                    p.fotoBytes!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 50),
            title: Text(p.nombre),
            subtitle: Text("Stock: ${p.cantidad}"),
            trailing: Text(
              "\$${p.precioDolar.toStringAsFixed(2)}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _vistaFormularioRegistro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageBytesSelected != null
                    ? MemoryImage(_imageBytesSelected!)
                    : null,
                child: _imageBytesSelected == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre"),
              validator: (v) => v!.isEmpty ? "Falta nombre" : null,
            ),
            TextFormField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Precio \$"),
              validator: (v) => v!.isEmpty ? "Falta precio" : null,
            ),
            TextFormField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Cantidad"),
              validator: (v) => v!.isEmpty ? "Falta cantidad" : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _registrarProducto,
              child: const Text("GUARDAR PRODUCTO"),
            ),
          ],
        ),
      ),
    );
  }
}
