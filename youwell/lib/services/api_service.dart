import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://devsbee.com.br/You-Well/Api/index.php';

  static Future<Map<String, dynamic>> testarConexao() async {
    final url = Uri.parse('$baseUrl?rota=status');

    final resposta = await http.get(url);

    print('STATUS API: ${resposta.statusCode}');
    print('RESPOSTA API: ${resposta.body}');

    if (resposta.statusCode != 200) {
      throw Exception(
        'Servidor retornou ${resposta.statusCode}: ${resposta.body}',
      );
    }

    return jsonDecode(resposta.body) as Map<String, dynamic>;
  }
}