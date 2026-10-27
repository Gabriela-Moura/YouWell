import 'package:flutter/material.dart';
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

  const AdminScreen({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
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
                widget.nomeSetor,

                style: TextStyle(
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
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_alarm),

              title: const Text(
                "Criar Setor",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
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
              leading: const Icon(Icons.access_alarm),

              title: const Text(
                "Novo Usuário",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
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
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AlertaScreen()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf),

              title: const Text(
                "Histórico Geral (PDF)",
                style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
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

            // SETORES
            _tituloSecao(Icons.apartment, 'Setores cadastrados', verde),
            const SizedBox(height: 12),

            if (setores.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhum setor cadastrado.'),
                ),
              )
            else
              ...setores.map((setor) {
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
                    subtitle: Text('Setor ${setor['id']}'),
                    trailing: const Icon(Icons.chevron_right, color: verde),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetorScreen(
                            nomeSetor: setor['nome'] as String,
                            nomeUsuario: widget.nomeAdmin,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            Row(
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
                    );
                  },
                  child: const Text('Novo Setor'),
                ),

                SizedBox(width: 10),

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
                  child: const Text('Novo Usuário'),
                ),
              ],
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
    nomeUsuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
