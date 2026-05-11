// lib/api_config.dart
class ApiConfig {
  // Tu URL de Railway (sin la barra final /)
  static const String baseUrl =
      "https://servitec-backend-production.up.railway.app";

  // Rutas de la API
  static String get login => "$baseUrl/api/login";
  static String get registroEmpresa => "$baseUrl/api/registro-empresa";
  static String get productos => "$baseUrl/api/productos";
}
