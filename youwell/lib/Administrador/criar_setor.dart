import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/admin.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/Administrador/novo_usuario.dart';
import 'package:youwell/Administrador/setor_screen.dart';

class CriarSetor extends StatefulWidget {
  final String nomeAdmin;
  final String nomeSetor;
  final int? idSetor;

  const CriarSetor({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
    this.idSetor,
  });

  @override
  State<CriarSetor> createState() => _CriarSetorState();
}

class _CriarSetorState extends State<CriarSetor> {
  static const String baseUrl = 'https://devsbee.com.br/You-Well/controllers/';

  final nomeSetorController = TextEditingController();

  List<Map<String, dynamic>> gerentes = [];

  int? gerenteSelecionado;

  bool carregandoGerentes = true;
  bool salvando = false;

  @override
  void initState() {
    super.initState();
    buscarGerentes();
  }

  // BUSCAR GERENTES NO BANCO REAL
  Future<void> buscarGerentes() async {
    setState(() {
      carregandoGerentes = true;
    });

    try {
      final resposta = await http.get(
        Uri.parse('${baseUrl}listar_gerentes.php'),
      );

      final dados = jsonDecode(resposta.body);

      if (resposta.statusCode == 200 && dados['success'] == true) {
        final List lista = dados['gerentes'];

        if (!mounted) return;

        setState(() {
          gerentes = lista.map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();

          if (!gerentes.any((g) => g['id_usuario'] == gerenteSelecionado)) {
            gerenteSelecionado = null;
          }

          carregandoGerentes = false;
        });
      } else {
        throw Exception(dados['message'] ?? 'Erro ao buscar gerentes.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoGerentes = false;
      });

      mostrarMensagem('Não foi possível carregar os gerentes.');
    }
  }

  // CADASTRAR SETOR NO BANCO REAL

  Future<void> criarSetor() async {
    final nome = nomeSetorController.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem('Digite o nome do setor.');
      return;
    }

    if (gerenteSelecionado == null) {
      mostrarMensagem('Selecione um gerente responsável.');
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final url = Uri.parse('${baseUrl}criar_setor.php');

      debugPrint('ENVIANDO CADASTRO DE SETOR...');
      debugPrint('URL: $url');
      debugPrint('Nome: $nome');
      debugPrint('ID gerente: $gerenteSelecionado');

      final resposta = await http.post(
        url,
        body: {'nome': nome, 'id_gerente': gerenteSelecionado.toString()},
      );

      debugPrint('STATUS HTTP: ${resposta.statusCode}');
      debugPrint('RESPOSTA PHP: ${resposta.body}');

      final dados = jsonDecode(resposta.body);

      if (resposta.statusCode == 200 && dados['success'] == true) {
        nomeSetorController.clear();

        setState(() {
          gerenteSelecionado = null;
        });

        mostrarMensagem('Setor criado com sucesso!');
      } else {
        mostrarMensagem(dados['message'] ?? 'Não foi possível criar o setor.');
      }
    } catch (e, stackTrace) {
      debugPrint('ERRO AO CRIAR SETOR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      mostrarMensagem('Erro de comunicação com o servidor.');
    } finally {
      if (mounted) {
        setState(() {
          salvando = false;
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
                      idSetor: widget.idSetor,
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
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
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Criar Setor'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Novo Usuário'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NovoUsuario(
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
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
                      idSetor: widget.idSetor,
                      nomeSetor: widget.nomeSetor,
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
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: verde),
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

            _tituloSecao(Icons.add_business, 'Criar setor', verde),

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
                    TextField(
                      controller: nomeSetorController,
                      decoration: InputDecoration(
                        labelText: 'Nome do setor',
                        hintText: 'Ex.: Recursos Humanos',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // LISTA DE GERENTES
                    if (carregandoGerentes)
                      const Center(child: CircularProgressIndicator())
                    else if (gerentes.isEmpty)
                      Column(
                        children: [
                          const Text(
                            'Nenhum gerente encontrado.',
                            style: TextStyle(color: Colors.red),
                          ),
                          TextButton.icon(
                            onPressed: buscarGerentes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: gerenteSelecionado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Gerente responsável',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        hint: const Text('Selecione um gerente'),
                        items: gerentes.map((gerente) {
                          return DropdownMenuItem<int>(
                            value: int.parse(gerente['id_usuario'].toString()),
                            child: Text(gerente['nome'].toString()),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            gerenteSelecionado = valor;
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed:
                          salvando || carregandoGerentes || gerentes.isEmpty
                          ? null
                          : criarSetor,
                      icon: salvando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(salvando ? 'Criando...' : 'Criar setor'),
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
          ],
        ),
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
    nomeSetorController.dispose();
    super.dispose();
  }
}
