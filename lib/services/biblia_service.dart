import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BibliaService {
  static String baseUrl = dotenv.env['BASE_URL']!;
  static String token = dotenv.env['API_TOKEN']!;

  static Map<String, String> headers = {
    "Authorization": "Bearer $token",
    "Accept": "application/json",
  };

  /// 📖 Buscar livros
  static Future<List> getLivros() async {
    final response = await http.get(
      Uri.parse("$baseUrl/books"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar livros");
    }

    return json.decode(response.body);
  }

  /// 📖 Buscar versículos
  static Future<Map> getVersiculos(
    String versao,
    String livro,
    String capitulo,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/verses/$versao/$livro/$capitulo"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception("Erro ao buscar versículos");
    }

    return json.decode(response.body);
  }
}
