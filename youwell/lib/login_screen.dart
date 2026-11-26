import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 48 || constraints.maxHeight <= 0) {
            return const SizedBox.shrink();
          }

          final logoSize = math.min(
            constraints.maxWidth * 0.9,
            constraints.maxHeight * 0.42,
          );
          final contentWidth = math.min(constraints.maxWidth - 40, 440.0);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF78AA9B),
                        Color(0xFF46BE9F),
                        Color(0xFF20AC8D),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -logoSize * 0.22,
                left: (constraints.maxWidth - logoSize) / 2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  child: Image.asset(
                    'assets/images/logo_branco.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  builder: (context, scale, child) {
                    return Opacity(
                      opacity: scale,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x1F000000)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.health_and_safety_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'BEM-ESTAR NO TRABALHO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Acesse sua conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Entre com seu nome e senha',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: logincontrollerForm,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    decoration: _inputDecoration(
                                      label: 'Nome',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: senhacontrollerForm,
                                    obscureText: ocultarSenha,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) {
                                      if (!carregando) fazerLogin();
                                    },
                                    decoration: _inputDecoration(
                                      label: 'Senha',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        tooltip: ocultarSenha
                                            ? 'Mostrar senha'
                                            : 'Ocultar senha',
                                        icon: Icon(
                                          ocultarSenha
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        color: const Color(0xFF16866E),
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
                                  SizedBox(
                                    height: 60,
                                    child: ElevatedButton(
                                      onPressed: carregando ? null : fazerLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF16866E,
                                        ),
                                        elevation: 5,
                                        shadowColor: Colors.black.withValues(
                                          alpha: 0.16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            carregando
                                                ? 'Entrando...'
                                                : 'Entrar',
                                          ),
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(
                                              0xFFE5F5EF,
                                            ),
                                            child: carregando
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Color(
                                                            0xFF16866E,
                                                          ),
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 20,
                                                    color: Color(0xFF16866E),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 8,
                child: SafeArea(
                  child: IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF16866E)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF16866E), width: 2),
      ),
    );
  }
}
