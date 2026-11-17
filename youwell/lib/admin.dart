import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/alertas.dart';
import 'package:youwell/historico.dart';
import 'package:youwell/login_screen.dart';
import 'package:youwell/Administrador/criar_setor.dart';
import 'package:youwell/Administrador/novo_usuario.dart';
import 'package:youwell/Administrador/setor_screen.dart';
import 'package:youwell/services/monitor_alertas.dart';
import 'package:youwell/widgets/sino_alertas.dart';

class AdminScreen extends StatefulWidget {
  final String nomeAdmin;
  final String nomeSetor;
  final int? idSetor;
  final int? idUsuario;
  final String? fotoPerfil;

  const AdminScreen({
    super.key,
    required this.nomeAdmin,
    required this.nomeSetor,
    required this.idSetor,
    this.idUsuario,
    required this.fotoPerfil,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const String _baseUrlControllers =
      'https://devsbee.com.br/You-Well/controllers/';

  // Lista de setores recebidos do banco de dados real
  List<Map<String, dynamic>> listaSetores = [];

  bool carregandoSetores = true;
  String? erroSetores;
  Timer? _timerAtualizacao;
  int? _setorEmAlteracao;

  // Endereço da API
  final String urlBuscarSetores =
      'https://devsbee.com.br/You-Well/controllers/buscar_setor.php';

  @override
  void initState() {
    super.initState();
    buscarSetores();
    _timerAtualizacao = Timer.periodic(const Duration(minutes: 1), (_) {
      buscarSetores(mostrarCarregamento: false);
    });
    final idUsuario = widget.idUsuario;
    if (idUsuario != null) {
      MonitorAlertas.iniciarAdmin(idUsuario: idUsuario);
    }
  }

  // BUSCAR TODOS OS SETORES NO BANCO DE DADOS
  Future<void> buscarSetores({bool mostrarCarregamento = true}) async {
    setState(() {
      if (mostrarCarregamento) carregandoSetores = true;
      erroSetores = null;
    });

    try {
      final resposta = await http
          .post(Uri.parse(urlBuscarSetores))
          .timeout(const Duration(seconds: 15));

      debugPrint('Status setores: ${resposta.statusCode}');
      debugPrint('Resposta setores: ${resposta.body}');

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (dados['success'] == true) {
          final List setoresRecebidos = dados['setores'] ?? [];

          if (!mounted) return;
          setState(() {
            listaSetores = setoresRecebidos.map((setor) {
              return {
                'id_setor': int.parse(setor['id_setor'].toString()),
                'nome': setor['nome'].toString(),
                'id_gerente': int.tryParse(
                  setor['id_gerente']?.toString() ?? '',
                ),
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
        throw Exception('Erro HTTP ${resposta.statusCode}: ${resposta.body}');
      }
    } catch (e) {
      debugPrint('Erro ao buscar setores: $e');

      if (!mounted) return;
      setState(() {
        carregandoSetores = false;
        erroSetores = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _buscarGerentes() async {
    final resposta = await http
        .get(Uri.parse('${_baseUrlControllers}listar_gerentes.php'))
        .timeout(const Duration(seconds: 15));

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (resposta.statusCode != 200 ||
        dados is! Map ||
        dados['success'] != true ||
        dados['gerentes'] is! List) {
      final mensagem = dados is Map
          ? dados['mensagem']?.toString() ??
                dados['message']?.toString() ??
                'Não foi possível carregar os gerentes.'
          : 'Resposta inválida do servidor.';
      throw Exception(mensagem);
    }

    return (dados['gerentes'] as List)
        .whereType<Map>()
        .map((gerente) => Map<String, dynamic>.from(gerente))
        .toList();
  }

  Future<void> _editarSetor(Map<String, dynamic> setor) async {
    late final List<Map<String, dynamic>> gerentes;
    try {
      gerentes = await _buscarGerentes();
    } catch (e) {
      if (mounted) {
        _mostrarMensagem('Não foi possível carregar os gerentes: $e');
      }
      return;
    }

    if (!mounted) return;
    if (gerentes.isEmpty) {
      _mostrarMensagem('Não há gerentes cadastrados para atribuir ao setor.');
      return;
    }

    final nomeController = TextEditingController(text: setor['nome'] as String);
    final senhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var gerenteSelecionado = setor['id_gerente'] as int?;
    if (!gerentes.any(
      (gerente) =>
          int.tryParse(gerente['id_usuario'].toString()) == gerenteSelecionado,
    )) {
      gerenteSelecionado = null;
    }

    final valores = await _showDialogAndWaitForDismiss<Map<String, String>>(
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar setor'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do setor',
                    ),
                    validator: (valor) => valor == null || valor.trim().isEmpty
                        ? 'Informe o nome do setor.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: gerenteSelecionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Gerente responsável',
                    ),
                    items: gerentes.map((gerente) {
                      return DropdownMenuItem<int>(
                        value: int.parse(gerente['id_usuario'].toString()),
                        child: Text(gerente['nome'].toString()),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setDialogState(() => gerenteSelecionado = valor);
                    },
                    validator: (valor) => valor == null
                        ? 'Selecione um gerente responsável.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha do administrador',
                    ),
                    validator: (valor) => valor == null || valor.isEmpty
                        ? 'Informe sua senha para confirmar.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final formulario = formKey.currentState;

                if (formulario == null || !formulario.validate()) {
                  return;
                }

                final resultado = <String, String>{
                  'nome': nomeController.text.trim(),
                  'id_gerente': gerenteSelecionado.toString(),
                  'admin_nome': widget.nomeAdmin,
                  'admin_senha': senhaController.text,
                };

                Navigator.of(dialogContext).pop(resultado);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
    nomeController.dispose();
    senhaController.dispose();

    if (valores == null) return;

    await _enviarAcaoSetor(
      endpoint: 'atualizar_setor.php',
      setorId: setor['id_setor'] as int,
      sucesso: 'Setor atualizado com sucesso.',
      campos: {...valores, 'id_setor': setor['id_setor'].toString()},
    );
  }

  Future<void> _excluirSetor(Map<String, dynamic> setor) async {
    final setorId = setor['id_setor'] as int;
    final senhaController = TextEditingController();
    final senhaAdmin = await _showDialogAndWaitForDismiss<String>(
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Deseja excluir "${setor['nome']}"? O servidor bloqueará '
                'a exclusão se houver registros relacionados.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senhaController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Senha do administrador',
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: senhaController.text.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(senhaController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        ),
      ),
    );
    senhaController.dispose();

    if (senhaAdmin == null) return;

    await _enviarAcaoSetor(
      endpoint: 'excluir_setor.php',
      setorId: setorId,
      sucesso: 'Setor excluído com sucesso.',
      campos: {
        'id_setor': setorId.toString(),
        'admin_nome': widget.nomeAdmin,
        'admin_senha': senhaAdmin,
      },
    );
  }

  Future<T?> _showDialogAndWaitForDismiss<T>({
    required WidgetBuilder builder,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    );
    final result = await navigator.push<T>(route);
    await route.completed;
    return result;
  }

  Future<void> _enviarAcaoSetor({
    required String endpoint,
    required int setorId,
    required String sucesso,
    required Map<String, String> campos,
  }) async {
    if (_setorEmAlteracao != null) return;
    setState(() => _setorEmAlteracao = setorId);

    try {
      final resposta = await http
          .post(
            Uri.parse('$_baseUrlControllers$endpoint'),
            headers: {'Accept': 'application/json'},
            body: campos,
          )
          .timeout(const Duration(seconds: 20));
      dynamic resultado;
      try {
        resultado = jsonDecode(utf8.decode(resposta.bodyBytes));
      } on FormatException {
        final corpo = resposta.body.trim();
        debugPrint(
          'Resposta inválida de $endpoint (HTTP ${resposta.statusCode}): '
          '${corpo.length > 300 ? '${corpo.substring(0, 300)}...' : corpo}',
        );
        final mensagem = resposta.statusCode == 404
            ? 'Endpoint $endpoint não encontrado (HTTP 404). '
                  'Confira o caminho /controllers no cPanel.'
            : 'Resposta inválida do servidor (HTTP ${resposta.statusCode}).';
        throw Exception(mensagem);
      }

      if (resultado is! Map ||
          resposta.statusCode < 200 ||
          resposta.statusCode >= 300 ||
          resultado['success'] != true) {
        final mensagem = resultado is Map
            ? resultado['mensagem']?.toString() ??
                  'Não foi possível concluir a operação.'
            : 'Resposta inválida do servidor.';
        throw Exception(mensagem);
      }

      _mostrarMensagem(sucesso);
      await buscarSetores(mostrarCarregamento: false);
    } on FormatException {
      _mostrarMensagem('O servidor retornou uma resposta inválida.');
    } catch (e) {
      debugPrint('Erro ao alterar setor: $e');
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _setorEmAlteracao = null);
    }
  }

  void _mostrarMensagem(String mensagem) {
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
                      fotoPerfil: widget.fotoPerfil,
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
                      fotoPerfil: widget.fotoPerfil,
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
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 3, 3),
                  fontSize: 18,
                ),
              ),
              onTap: () {
                MonitorAlertas.parar();
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
          'Painel Geral',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          const SinoAlertas(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  'Olá, ${widget.nomeAdmin}',
                  style: const TextStyle(fontSize: 18),
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
                final setorId = setor['id_setor'] as int;
                final emAlteracao = _setorEmAlteracao == setorId;
                final ocupado = _setorEmAlteracao != null;

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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar setor',
                          onPressed: ocupado ? null : () => _editarSetor(setor),
                          icon: emAlteracao
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.edit_outlined, color: verde),
                        ),
                        IconButton(
                          tooltip: 'Excluir setor',
                          onPressed: ocupado
                              ? null
                              : () => _excluirSetor(setor),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: verde),
                      ],
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetorScreen(
                            nomeSetor: setor['nome'] as String,
                            nomeUsuario: widget.nomeAdmin,
                            idSetor: setor['id_setor'] as int,
                            fotoPerfil: widget.fotoPerfil,
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
                          fotoPerfil: widget.fotoPerfil,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          fotoPerfil: widget.fotoPerfil,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    _timerAtualizacao?.cancel();
    super.dispose();
  }
}
