import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RegistrarProductoView extends StatefulWidget {
  const RegistrarProductoView({super.key});

  @override
  State<RegistrarProductoView> createState() => _RegistrarProductoViewState();
}

class _RegistrarProductoViewState extends State<RegistrarProductoView> {
  final _formKey = GlobalKey<FormState>();

  // Usamos Uint8List para compatibilidad total (Web y Móvil)
  Uint8List? _imageBytes;
  final _picker = ImagePicker();
  bool _isUploading = false;

  // Controladores para capturar el texto
  final _nombreEquipoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nombreClienteController = TextEditingController();
  final _cedulaClienteController = TextEditingController();

  String _tipoServicio = 'Mantenimiento'; // Valor por defecto

  // Función para capturar la imagen
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Comprimimos para no saturar la base de datos
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error al capturar imagen: $e");
    }
  }

  // Función para enviar a la base de datos
  Future<void> _enviarADatabase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, agregue una foto del equipo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Convertir bytes a cadena Base64 para el JSON
      String base64Image = base64Encode(_imageBytes!);

      // 2. Preparar el cuerpo de la solicitud
      final data = {
        "cedula_cliente": _cedulaClienteController.text,
        "nombre_cliente": _nombreClienteController.text,
        "empresa_id": 1, // Ajustar según el ID de tu empresa logueada
        "nombre_equipo": _nombreEquipoController.text,
        "tipo_servicio": _tipoServicio,
        "descripcion": _descripcionController.text,
        "foto_inicial": base64Image,
      };

      // 3. Petición POST
      // Nota: En Web usa 'localhost', en emulador Android usa '10.0.2.2'
      final url = Uri.parse(
        'https://servitec-backend-production.up.railway.app/api',
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200 && resData['status'] == 'success') {
        _limpiarCampos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro guardado exitosamente en la DB!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(resData['message'] ?? 'Error al guardar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _limpiarCampos() {
    _nombreEquipoController.clear();
    _descripcionController.clear();
    _nombreClienteController.clear();
    _cedulaClienteController.clear();
    setState(() {
      _imageBytes = null;
    });
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Servicio Técnico")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nuevo Reporte",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Selector de Imagen (Compatible con Web y Móvil)
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.5),
                      ),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(height: 10),
                              Text("Tocar para agregar foto del equipo"),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- SECCIÓN CLIENTE ---
              const Text(
                "Datos del Cliente",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreClienteController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cedulaClienteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese la cédula' : null,
              ),

              const SizedBox(height: 25),

              // --- SECCIÓN EQUIPO ---
              const Text(
                "Datos del Equipo",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreEquipoController,
                decoration: const InputDecoration(
                  labelText: 'Equipo / Producto',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese nombre del equipo' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tipoServicio,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Servicio',
                  prefixIcon: Icon(Icons.settings),
                  border: OutlineInputBorder(),
                ),
                items:
                    ['Mantenimiento', 'Reparación', 'Instalación', 'Garantía']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _tipoServicio = value!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del problema',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Botón Guardar con estado de carga
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _enviarADatabase,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isUploading ? "PROCESANDO..." : "GUARDAR EN BASE DE DATOS",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
