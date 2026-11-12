import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youwell/widgets/sino_alertas.dart';
import 'package:http/http.dart' as http;

import 'package:youwell/Gerente/setor_screen_gerente.dart';
import 'package:youwell/services/monitor_alertas.dart';

class GerenteScreen extends StatefulWidget {
  final String nomeGerente;
  final int idUsuario;
  final String? fotoPerfil;

  const GerenteScreen({
    super.key,
    required this.nomeGerente,
    required this.idUsuario,
    this.fotoPerfil,
  });

  @override
  State<GerenteScreen> createState() => _GerenteScreenState();
}

class _GerenteScreenState extends State<GerenteScreen> {
  List<Map<String, dynamic>> setores = [];

  bool carregando = true;
  String? erro;

  final String urlBuscarSetores =
      'https://devsbee.com.br/You-Well/controllers/buscar_setor.php';

  @override
  void initState() {
    super.initState();
    debugPrint('ENTROU NO INITSTATE DO GERENTESCREEN');
    debugPrint('ID RECEBIDO PELO GERENTESCREEN: ${widget.idUsuario}');
    MonitorAlertas.iniciarGerente(idUsuario: widget.idUsuario);
    buscarSetores();
  }

  // BUSCAR TODOS OS SETORES RESPONSÁVEIS PELO GERENTE
  Future<void> buscarSetores() async {
    debugPrint('INICIOU A BUSCA DOS SETORES');
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resposta = await http
          .post(
            Uri.parse(urlBuscarSetores),
            headers: {'Accept': 'application/json'},
            body: {'id_usuario': widget.idUsuario.toString()},
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('ID USUÁRIO GERENTE: ${widget.idUsuario}');
      debugPrint('STATUS SETORES GERENTE: ${resposta.statusCode}');
      debugPrint('RESPOSTA SETORES GERENTE: ${resposta.body}');

      if (resposta.statusCode != 200) {
        throw Exception('Erro HTTP ${resposta.statusCode}');
      }

      final dados =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;

      if (dados['success'] != true) {
        throw Exception(
          dados['mensagem'] ?? 'Não foi possível buscar os setores.',
        );
      }

      final List lista = dados['setores'] ?? [];

      final setoresRecebidos = lista.map((setor) {
        return {
          'id_setor': int.parse(setor['id_setor'].toString()),
          'nome': setor['nome'].toString(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        setores = setoresRecebidos;
        carregando = false;
      });
    } catch (e) {
      debugPrint('ERRO AO BUSCAR SETORES DO GERENTE: $e');

      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color.fromARGB(255, 10, 85, 64);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: verde,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          const SinoAlertas(),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text(
                  "Olá ${widget.nomeGerente}",
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      widget.fotoPerfil != null && widget.fotoPerfil!.isNotEmpty
                      ? MemoryImage(base64Decode(widget.fotoPerfil!))
                      : null,
                  child: widget.fotoPerfil == null || widget.fotoPerfil!.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 10, 85, 64),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: carregando
              ? const Center(child: CircularProgressIndicator(color: verde))
              : erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Não foi possível carregar seus setores.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton.icon(
                        onPressed: buscarSetores,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : setores.isEmpty
              ? const Center(
                  child: Text(
                    'Você não possui setores cadastrados.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  children: [
                    const Text(
                      'Seus setores',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: verde,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ...setores.map((setor) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SetorScreen(
                                nomeSetor: setor['nome'],
                                nomeUsuario: widget.nomeGerente,
                                idSetor: setor['id_setor'],
                                idUsuario: widget.idUsuario,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              setor['nome'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }
}
