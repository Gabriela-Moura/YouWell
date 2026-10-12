
import 'package:flutter/material.dart';
import 'package:youwell/simulacaoBD/dados_sensores.dart';

class UsuarioTi extends StatefulWidget {
  const UsuarioTi({super.key});

  @override
  State<UsuarioTi> createState() => _UsuarioTiState();
}

class _UsuarioTiState extends State<UsuarioTi> {
  final nomeSetorController = TextEditingController();
  final nomeUsuarioController = TextEditingController();
  final senhaController = TextEditingController();

  String papelSelecionado = 'usuario';
  int? setorSelecionado;

  void criarSetor() {
    final nome = nomeSetorController.text.trim();

    if (nome.isEmpty) {
      mostrarMensagem('Digite o nome do setor.');
      return;
    }

    final existe = setores.any(
      (s) => (s['nome'] as String).toLowerCase() == nome.toLowerCase(),
    );

    if (existe) {
      mostrarMensagem('Já existe um setor com esse nome.');
      return;
    }

    final novoId = setores.isEmpty
        ? 1
        : setores
                .map((s) => s['id'] as int)
                .reduce((a, b) => a > b ? a : b) +
            1;

    setState(() {
      setores.add({
        'id': novoId,
        'nome': nome,
      });
    });

    nomeSetorController.clear();
    mostrarMensagem('Setor criado com sucesso!');
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
        : usuarios
                .map((u) => u['id'] as int)
                .reduce((a, b) => a > b ? a : b) +
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  void dispose() {
    nomeSetorController.dispose();
    nomeUsuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página TI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Criar setor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomeSetorController,
            decoration: const InputDecoration(
              labelText: 'Nome do setor',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: criarSetor,
            child: const Text('Criar Setor'),
          ),

          const Divider(height: 40),

          const Text(
            'Criar usuário',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomeUsuarioController,
            decoration: const InputDecoration(
              labelText: 'Nome do usuário',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: senhaController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: papelSelecionado,
            decoration: const InputDecoration(
              labelText: 'Papel do usuário',
              border: OutlineInputBorder(),
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
              DropdownMenuItem(
                value: 'ti',
                child: Text('TI'),
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
          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            value: setorSelecionado,
            decoration: const InputDecoration(
              labelText: 'Setor do usuário',
              border: OutlineInputBorder(),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: novoUsuario,
            child: const Text('Criar Usuário'),
          ),
        ],
      ),
    );
  }
}