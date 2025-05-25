import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<void> sendUserInput(String role, String location) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user-input'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role, 'location': location}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send user input');
    }
  }
}