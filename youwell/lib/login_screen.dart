import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/main.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/gerente.dart';
import 'package:youwell/services/api_service.dart';
import 'package:youwell/services/monitor_alertas.dart';

class LoginScreen extends StatefulWidget {
  final String nomeSetor;

  const LoginScreen({super.key, required this.nomeSetor});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final logincontrollerForm = TextEditingController();
  final senhacontrollerForm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool carregando = false;
  bool ocultarSenha = true;

  @override
  void initState() {
    super.initState();

    MonitorAlertas.parar();
    testarAPI();
  }

  Future<void> testarAPI() async {
    try {
      final resultado = await ApiService.testarConexao();

      debugPrint('RESULTADO DA API: $resultado');
    } catch (e) {
      debugPrint('ERRO AO CONECTAR COM A API: $e');
    }
  }

  static const String urlLogin =
      'https://devsbee.com.br/You-Well/controllers/login.php';

  Future<void> fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => carregando = true);

    try {
      final resposta = await http
          .post(
            Uri.parse(urlLogin),
            headers: {'Accept': 'application/json'},
            body: {
              'nome': logincontrollerForm.text.trim(),
              'senha': senhacontrollerForm.text,
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('STATUS LOGIN: ${resposta.statusCode}');
      debugPrint('RESPOSTA LOGIN: ${resposta.body}');

      if (!mounted) return;

      if (resposta.statusCode != 200) {
        mostrarMensagem('Erro no servidor (${resposta.statusCode}).');
        return;
      }

      final Map<String, dynamic> dados =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;

      if (dados['success'] != true) {
        mostrarMensagem(
          dados['mensagem']?.toString() ?? 'Nome ou senha inválidos.',
        );
        return;
      }

      final String nome = dados['nome'].toString();
      final String? fotoPerfil = dados['foto_perfil']?.toString();
      final String papel = dados['papel'].toString().trim().toLowerCase();

      // ID do usuário que realizou o login
      final dynamic usuarioRecebido = dados['id_usuario'];

      final int? idUsuario = usuarioRecebido == null
          ? null
          : int.tryParse(usuarioRecebido.toString());

      debugPrint('Dados recebidos no login: $dados');
      debugPrint('Papel do usuário: $papel');

      if (papel == 'gerente') {
        if (idUsuario == null) {
          mostrarMensagem('Não foi possível identificar o usuário.');
          return;
        }

        debugPrint('ID DO GERENTE: $idUsuario');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GerenteScreen(
              nomeGerente: nome,
              idUsuario: idUsuario,
              fotoPerfil: fotoPerfil,
            ),
          ),
        );
      } else if (papel == 'admin') {
        if (idUsuario == null) {
          mostrarMensagem('Não foi possível identificar o usuário.');
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminScreen(
              nomeAdmin: nome,
              nomeSetor: 'null',
              idSetor: null,
              idUsuario: idUsuario,
              fotoPerfil: fotoPerfil,
            ),
          ),
        );
      } else {
        mostrarMensagem(
          'Login válido, mas o papel "$papel" ainda não possui '
          'uma tela configurada.',
        );
      }
    } on FormatException {
      if (!mounted) return;
      mostrarMensagem(
        'A resposta do servidor não está em formato JSON válido.',
      );
    } catch (e) {
      if (!mounted) return;
      mostrarMensagem(
        'Não foi possível acessar a API. '
        'Verifique a rede e o servidor PHP.',
      );
      debugPrint('Erro no login: $e');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  Future<String?> buscarNomeSetor(int idSetor) async {
    try {
      final resposta = await http
          .post(
            Uri.parse(
              'https://devsbee.com.br/You-Well/controllers/buscar_setor.php',
            ),
            headers: {'Accept': 'application/json'},
            body: {'id_setor': idSetor.toString()},
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Status buscar setor: ${resposta.statusCode}');
      debugPrint('Resposta buscar setor: ${resposta.body}');

      if (resposta.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> dados =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;

      if (dados['success'] != true) {
        debugPrint('Mensagem PHP: ${dados['mensagem']}');
        return null;
      }

      final nomeSetor = dados['nome_setor']?.toString().trim();

      if (nomeSetor == null || nomeSetor.isEmpty) {
        return null;
      }

      return nomeSetor;
    } catch (e) {
      debugPrint('Erro ao consultar setor: $e');
      return null;
    }
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  void dispose() {
    logincontrollerForm.dispose();
    senhacontrollerForm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 85, 64),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(163, 220, 220, 220),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Login:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    TextFormField(
                      controller: logincontrollerForm,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Senha:',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    TextFormField(
                      controller: senhacontrollerForm,
                      obscureText: ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              ocultarSenha = !ocultarSenha;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: carregando ? null : fazerLogin,
                      child: carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: carregando
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MyApp()),
                              );
                            },
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
