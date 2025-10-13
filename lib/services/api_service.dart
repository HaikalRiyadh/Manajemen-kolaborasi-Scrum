import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = "http://10.0.2.2:8000/api";
  static String? token;

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      body: {
        "name": name,
        "email": email,
        "password": password,
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      body: {
        "email": email,
        "password": password,
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      token = data['token'];
    }
    return data;
  }

  static Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      Uri.parse("$baseUrl/user"),
      headers: token != null ? {"Authorization": "Bearer $token"} : {},
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getPosts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/posts"),
      headers: token != null ? {"Authorization": "Bearer $token"} : {},
    );
    return jsonDecode(response.body);
  }
}
