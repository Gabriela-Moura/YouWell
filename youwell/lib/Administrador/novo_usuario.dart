import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/main.dart';
import 'package:youwell/login_screen.dart';
import 'package:youwell/Administrador/criar_setor.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/admin.dart';

class NovoUsuario extends StatefulWidget {
  final String nomeAdmin;
  final String nomeSetor;
  final String? fotoPerfil;

  const NovoUsuario({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
    this.fotoPerfil,
  });

  @override
  State<NovoUsuario> createState() => _NovoUsuarioState();
}

class _NovoUsuarioState extends State<NovoUsuario> {
  final nomeUsuarioController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final String baseUrl = 'https://devsbee.com.br/You-Well/controllers/';

  // Mesma regra de caractere especial usada no PHP.
  static final RegExp _regexEspecial = RegExp(
    r'[@#$%^&*()_+\-=\[\]{};":\\|,.<>/?]',
  );
  static final RegExp _regexMaiuscula = RegExp(r'[A-Z]');

  String papelSelecionado = 'gerente';

  bool cadastrando = false;
  bool senhaVisivel = false;
  bool confirmarVisivel = false;

  // REQUISITOS DA SENHA (iguais aos do servidor)
  bool get _temTamanho => senhaController.text.length > 7;
  bool get _temMaiuscula => _regexMaiuscula.hasMatch(senhaController.text);
  bool get _temEspecial => _regexEspecial.hasMatch(senhaController.text);
  bool get _senhaValida => _temTamanho && _temMaiuscula && _temEspecial;

  // PEDE A SENHA DO ADMINISTRADOR ANTES DE CRIAR O USUÁRIO
  Future<String?> _pedirSenhaAdmin() async {
    final controller = TextEditingController();
    bool visivel = false;

    final senha = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Confirme sua identidade'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para criar um usuário, digite a senha do '
                    'administrador ${widget.nomeAdmin}.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    obscureText: !visivel,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Sua senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          visivel ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            visivel = !visivel;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (valor) =>
                        Navigator.of(dialogContext).pop(valor),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 10, 85, 64),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(controller.text),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (senha == null || senha.isEmpty) return null;
    return senha;
  }

  // CADASTRAR NOVO USUÁRIO
  Future<void> novoUsuario() async {
    final nome = nomeUsuarioController.text.trim();
    final senha = senhaController.text;
    final confirmar = confirmarSenhaController.text;

    if (nome.isEmpty || senha.isEmpty || confirmar.isEmpty) {
      mostrarMensagem('Preencha o nome, a senha e a confirmação da senha.');
      return;
    }

    if (!_senhaValida) {
      mostrarMensagem('A senha ainda não atende a todos os requisitos.');
      return;
    }

    if (senha != confirmar) {
      mostrarMensagem('As senhas não coincidem.');
      return;
    }

    final senhaAdmin = await _pedirSenhaAdmin();
    if (senhaAdmin == null) return;

    setState(() {
      cadastrando = true;
    });

    try {
      final resposta = await http
          .post(
            Uri.parse('${baseUrl}cadastrar_usuario.php'),
            body: {
              // Quem está cadastrando (confirmado no servidor).
              'admin_nome': widget.nomeAdmin,
              'admin_senha': senhaAdmin,

              // Novo usuário.
              'nome': nome,
              'senha': senha,
              'confirmar_senha': confirmar,
              'papel': papelSelecionado,
            },
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('STATUS CADASTRO: ${resposta.statusCode}');
      debugPrint('RESPOSTA CADASTRO: ${resposta.body}');

      // O PHP responde JSON mesmo nos erros (400, 401, 409...).
      Map? dados;
      try {
        final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (decodificado is Map) dados = decodificado;
      } catch (_) {
        dados = null;
      }

      if (dados == null) {
        mostrarMensagem(
          resposta.body.trim().isEmpty
              ? 'O servidor respondeu vazio (HTTP ${resposta.statusCode}). '
                    'Verifique o cadastrar_usuario.php no servidor.'
              : 'Resposta inesperada do servidor (HTTP ${resposta.statusCode}).',
        );
      } else if (dados['success'] == true) {
        nomeUsuarioController.clear();
        senhaController.clear();
        confirmarSenhaController.clear();

        setState(() {});

        mostrarMensagem(dados['mensagem']?.toString() ?? 'Usuário criado!');
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível cadastrar o usuário.',
        );
      }
    } catch (e) {
      debugPrint('ERRO AO CADASTRAR USUÁRIO: $e');
      mostrarMensagem('Erro de conexão ao cadastrar usuário.');
    } finally {
      if (mounted) {
        setState(() {
          cadastrando = false;
        });
      }
    }
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color.fromARGB(255, 10, 85, 64);
    const fundo = Color(0xFFF4F7F5);

    return Scaffold(
      backgroundColor: fundo,

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: verde),
              child: Text(
                'Olá, ${widget.nomeAdmin}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminScreen(
                      idSetor: null,
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
                      fotoPerfil: widget.fotoPerfil,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.window),
              title: const Text('Geral'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetorScreen(
                      nomeSetor: widget.nomeSetor,
                      nomeUsuario: widget.nomeAdmin,
                      fotoPerfil: widget.fotoPerfil,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Criar Setor'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriarSetor(
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
                      fotoPerfil: widget.fotoPerfil,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Novo Usuário'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NovoUsuario(
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
                      fotoPerfil: widget.fotoPerfil,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),
              title: const Text('Alertas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertaScreen(
                      nomeSetor: widget.nomeSetor,
                      idSetor: null,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Histórico Geral (PDF)'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoricoScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(nomeSetor: widget.nomeSetor),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Painel administrativo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Olá, ${widget.nomeAdmin}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      widget.fotoPerfil != null && widget.fotoPerfil!.isNotEmpty
                      ? MemoryImage(base64Decode(widget.fotoPerfil!))
                      : null,
                  child: widget.fotoPerfil == null || widget.fotoPerfil!.isEmpty
                      ? const Icon(Icons.person, color: verde)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Gerencie seu ambiente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: verde,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Gerencie os setores e os usuários do YouWell.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),

            const SizedBox(height: 24),

            _tituloSecao(Icons.person_add_alt_1, 'Criar usuário', verde),

            const SizedBox(height: 12),

            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NOME
                    TextField(
                      controller: nomeUsuarioController,
                      decoration: InputDecoration(
                        labelText: 'Nome do usuário',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SENHA
                    TextField(
                      controller: senhaController,
                      obscureText: !senhaVisivel,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            senhaVisivel
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              senhaVisivel = !senhaVisivel;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // REQUISITOS DA SENHA
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _requisito(_temTamanho, 'Mínimo de 8 caracteres'),
                          _requisito(_temMaiuscula, 'Uma letra maiúscula'),
                          _requisito(
                            _temEspecial,
                            'Um caractere especial (@, #, !, etc.)',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CONFIRMAR SENHA
                    TextField(
                      controller: confirmarSenhaController,
                      obscureText: !confirmarVisivel,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmarVisivel
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              confirmarVisivel = !confirmarVisivel;
                            });
                          },
                        ),
                        errorText:
                            confirmarSenhaController.text.isNotEmpty &&
                                confirmarSenhaController.text !=
                                    senhaController.text
                            ? 'As senhas não coincidem'
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // PAPEL
                    DropdownButtonFormField<String>(
                      value: papelSelecionado,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Papel do usuário',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'gerente',
                          child: Text('Gerente'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() {
                            papelSelecionado = valor;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    // ACESSO AOS SETORES DO PAPEL ESCOLHIDO
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: verde.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: verde.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment, color: verde),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Acesso aos setores',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: verde,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  papelSelecionado == 'admin'
                                      ? 'Todos os setores'
                                      : 'Os setores do gerente são definidos em '
                                            '"Criar Setor", escolhendo este '
                                            'gerente como responsável.',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // CADASTRAR
                    ElevatedButton.icon(
                      onPressed: cadastrando ? null : novoUsuario,
                      icon: cadastrando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(
                        cadastrando ? 'Cadastrando...' : 'Cadastrar usuário',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: verde,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _requisito(bool atendido, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            atendido ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: atendido ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12.5,
              color: atendido ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(IconData icone, String titulo, Color cor) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(width: 10),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nomeUsuarioController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }
}
