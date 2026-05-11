import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'archivo.dart'; // Importante para la navegación al Dashboard

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Servitec App',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

enum AuthMode { login, createCompany, joinCompany }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;

  // --- MEJORA: URL DE RAILWAY ---
  final String urlBase =
      "https://servitec-backend-production.up.railway.app/api";

  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _processAuth() async {
    setState(() => _isLoading = true);

    String endpoint;
    if (_authMode == AuthMode.login) {
      endpoint = "/login";
    } else {
      endpoint = _authMode == AuthMode.createCompany
          ? "/registro-empresa"
          : "/unirme-empresa";
    }

    try {
      final response = await http
          .post(
            Uri.parse(urlBase + endpoint),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: json.encode({
              'email': _emailController.text.trim(),
              'correo': _emailController.text.trim(),
              'password': _passwordController.text,
              'nombre_empresa': _companyController.text.trim(),
              'usuario': _userController.text.trim(),
              'cedula': _cedulaController.text.trim(),
              'telefono': _phoneController.text.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Un poco más de tiempo para la nube

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 'success') {
          if (!mounted) return;
          if (_authMode == AuthMode.login) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(user: data['user']),
              ),
            );
          } else {
            setState(() => _authMode = AuthMode.login);
            _showMessage(
              "Registro exitoso. Ya puedes iniciar sesión.",
              Colors.green,
            );
          }
        } else {
          _showError(data['message']);
        }
      } else {
        _showError(data['message'] ?? "Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError(
        "No se pudo conectar con Servitec Cloud. Verifica tu internet.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ... El resto de tus widgets (_showError, _showMessage, build, etc.) se mantienen igual
  void _showError(String message) {
    _showMessage(message, Colors.redAccent);
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://inkscape.app/wp-content/uploads/imagen-vectorial.webp',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.blue.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Center(
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.black26,
                      child: Icon(Icons.biotech, color: Colors.white, size: 35),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      _buildTabItem(
                        "Entrar",
                        _authMode == AuthMode.login,
                        () => setState(() => _authMode = AuthMode.login),
                      ),
                      const SizedBox(width: 40),
                      _buildTabItem(
                        "Registro",
                        _authMode != AuthMode.login,
                        () =>
                            setState(() => _authMode = AuthMode.createCompany),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (_authMode != AuthMode.login) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _selectionChip("Crear Empresa", AuthMode.createCompany),
                        const SizedBox(width: 10),
                        _selectionChip("Unirme", AuthMode.joinCompany),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      "Nombre Empresa",
                      controller: _companyController,
                      icon: Icons.business,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      "Usuario",
                      controller: _userController,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      "Cédula",
                      controller: _cedulaController,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildInputField(
                      "Teléfono",
                      controller: _phoneController,
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(height: 15),
                  ],
                  _buildInputField(
                    "Correo",
                    controller: _emailController,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildInputField(
                    "Contraseña",
                    isPassword: true,
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _authMode == AuthMode.login
                                  ? 'INICIAR SESIÓN'
                                  : 'FINALIZAR REGISTRO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionChip(String label, AuthMode mode) {
    bool isSelected = _authMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _authMode = mode);
      },
      selectedColor: Colors.blue[600],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white60,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTabItem(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.blue[400] : Colors.white38,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 5),
              height: 2,
              width: 35,
              color: Colors.blue[400],
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    bool isPassword = false,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
