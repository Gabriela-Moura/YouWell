import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/Administrador/criar_setor.dart';
import 'package:youwell/Administrador/qualidade_ar.dart';
import 'package:youwell/Administrador/ruido.dart';
import 'package:youwell/Administrador/temperatura_screen.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/admin.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class NovoUsuario extends StatefulWidget {
  final String nomeAdmin;
  final String nomeSetor;

  const NovoUsuario({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
  });

  @override
  State<NovoUsuario> createState() => _NovoUsuarioState();
}

class _NovoUsuarioState extends State<NovoUsuario> {
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

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: verde),

              child: Text(
                widget.nomeAdmin,
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
                "Inicio",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminScreen(
                      nomeSetor: widget.nomeAdmin,
                      nomeAdmin: widget.nomeSetor,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.window),

              title: const Text(
                "Geral",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetorScreen(
                      nomeSetor: widget.nomeAdmin,
                      nomeUsuario: widget.nomeSetor,
                    ),
                  ),
                );
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
                  MaterialPageRoute(builder: (context) => AlertaScreen()),
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

            // CRIAR USUÁRIO
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

                    TextField(
                      controller: senhaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

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
                          value: 'usuario',
                          child: Text('Usuário'),
                        ),
                        DropdownMenuItem(
                          value: 'gerente',
                          child: Text('Gerente'),
                        ),
                        DropdownMenuItem(value: 'ti', child: Text('TI')),
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

                    DropdownButtonFormField<int>(
                      value: setores.any((s) => s['id'] == setorSelecionado)
                          ? setorSelecionado
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Setor do usuário',
                        prefixIcon: const Icon(Icons.apartment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: setores.map((setor) {
                        return DropdownMenuItem<int>(
                          value: setor['id'] as int,
                          child: Text(setor['nome'] as String),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        setState(() {
                          setorSelecionado = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: novoUsuario,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Cadastrar usuário'),
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
