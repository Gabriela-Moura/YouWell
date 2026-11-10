
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Administrador/criar_setor.dart';
import 'package:youwell/Administrador/novo_usuario.dart';
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class AdminScreen extends StatefulWidget {
  final String nomeAdmin;
  final String nomeSetor;
  final int? idSetor;

  const AdminScreen({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
    required this.idSetor,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final nomeSetorController = TextEditingController();
  final nomeUsuarioController = TextEditingController();
  final senhaController = TextEditingController();

  String papelSelecionado = 'usuario';
  int? setorSelecionado;

  // Lista de setores recebidos do banco de dados real
  List<Map<String, dynamic>> listaSetores = [];

  bool carregandoSetores = true;
  String? erroSetores;

  // Endereço da API
  final String urlBuscarSetores =
      'https://devsbee.com.br/You-Well/controllers/buscar_setor.php';

  @override
  void initState() {
    super.initState();
    buscarSetores();
  }

  // BUSCAR TODOS OS SETORES NO BANCO DE DADOS
  Future<void> buscarSetores() async {
    setState(() {
      carregandoSetores = true;
      erroSetores = null;
    });

    try {
      final resposta = await http.post(
        Uri.parse(urlBuscarSetores),
      );

      debugPrint('Status setores: ${resposta.statusCode}');
      debugPrint('Resposta setores: ${resposta.body}');

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (dados['success'] == true) {
          final List setoresRecebidos = dados['setores'] ?? [];

          setState(() {
            listaSetores = setoresRecebidos.map((setor) {
              return {
                'id_setor': int.parse(setor['id_setor'].toString()),
                'nome': setor['nome'].toString(),
              };
            }).toList();

            carregandoSetores = false;
          });
        } else {
          throw Exception(
            dados['mensagem'] ?? 'Não foi possível buscar os setores.',
          );
        }
      } else {
        throw Exception(
          'Erro HTTP ${resposta.statusCode}: ${resposta.body}',
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar setores: $e');

      setState(() {
        carregandoSetores = false;
        erroSetores = e.toString();
      });
    }
  }

  void novoUsuario() {
    final nome = nomeUsuarioController.text.trim();
    final senha = senhaController.text;

    if (nome.isEmpty || senha.isEmpty) {
      mostrarMensagem('Preencha o nome e a senha.');
      return;
    }

    final existe = usuarios.any(
      (u) => (u['nome'] as String).toLowerCase() == nome.toLowerCase(),
    );

    if (existe) {
      mostrarMensagem('Já existe um usuário com esse nome.');
      return;
    }

    if (papelSelecionado != 'admin' && setorSelecionado == null) {
      mostrarMensagem('Selecione um setor para o usuário.');
      return;
    }

    final idUsuario = usuarios.isEmpty
        ? 1
        : usuarios.map((u) => u['id'] as int).reduce((a, b) => a > b ? a : b) +
              1;

    setState(() {
      usuarios.add({
        'id': idUsuario,
        'nome': nome,
        'senha': senha,
        'papel': papelSelecionado,
        'setor': papelSelecionado == 'admin' ? null : setorSelecionado,
      });
    });

    nomeUsuarioController.clear();
    senhaController.clear();

    mostrarMensagem('Usuário criado com sucesso!');
  }

  void mostrarMensagem(String mensagem) {
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

      // MENU HAMBÚRGUER
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 10, 85, 64),
              ),
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
              title: const Text(
                "Início",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text(
                "Criar Setor",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriarSetor(
                      nomeSetor: widget.nomeSetor,
                      nomeAdmin: widget.nomeAdmin,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text(
                "Novo Usuário",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
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
              title: const Text(
                "Alertas",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
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
              title: const Text(
                "Histórico Geral (PDF)",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
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
          'Painel Geral',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Olá, ${widget.nomeAdmin}',
                  style: const TextStyle(fontSize: 18),
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
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),

            const SizedBox(height: 24),

            // SETORES
            _tituloSecao(
              Icons.apartment,
              'Setores cadastrados',
              verde,
              tamanhoFonte: 24,
            ),

            const SizedBox(height: 20),

            // CARREGANDO SETORES
            if (carregandoSetores)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(color: verde),
                ),
              )

            // ERRO AO BUSCAR SETORES
            else if (erroSetores != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 35,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Não foi possível carregar os setores.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        erroSetores!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: buscarSetores,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )

            // NENHUM SETOR CADASTRADO
            else if (listaSetores.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhum setor cadastrado.'),
                ),
              )

            // LISTA DE SETORES DO BANCO REAL
            else
              ...listaSetores.map((setor) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE1EFE8),
                      child: Icon(Icons.business, color: verde),
                    ),
                    title: Text(
                      setor['nome'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Setor ${setor['id_setor']}'),
                    trailing: const Icon(Icons.chevron_right, color: verde),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetorScreen(
                            nomeSetor: setor['nome'] as String,
                            nomeUsuario: widget.nomeAdmin,
                            idSetor: setor['id_setor'] as int,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CriarSetor(
                          nomeSetor: widget.nomeSetor,
                          nomeAdmin: widget.nomeAdmin,
                        ),
                      ),
                    ).then((_) {
                      buscarSetores();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    minimumSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Novo Setor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: () {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    minimumSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Novo Usuário',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSecao(
    IconData icone,
    String titulo,
    Color cor, {
    double tamanhoFonte = 19,
  }) {
    return Row(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(width: 10),
        Text(
          titulo,
          style: TextStyle(
            fontSize: tamanhoFonte,
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
    nomeUsuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
