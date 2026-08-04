import 'package:flutter/material.dart';
import 'package:youwell/main.dart';
import 'package:youwell/setor_screen.dart';
// import 'package:youwell/setor.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // LISTA LOCAL (FAKE)
  // List<Map<String, dynamic>> setores
  // Cria uma lista de objetos (Map) para armazenar
  // os setores do sistema. Cada setor possui
  // informações como id e nome.
  //
  //O tipo da chave é string
  /// Exemplo:
  /// {
  ///   "id": 1,
  ///   "nome": "Setor A"
  /// }

  List<Map<String, dynamic>> setores = [
    {"id": 1, "nome": "Setor A"},

    {"id": 2, "nome": "Setor B"},

    {"id": 3, "nome": "Setor C"},

    {"id": 4, "nome": "Setor D"},

    {"id": 5, "nome": "Setor E"},

    {"id": 6, "nome": "Setor F"},
  ];

  // CRIAR SETOR
  void criarSetor() {
    setState(() {
      setores.add({"id": setores.length + 1, "nome": "Novo Setor"});
    });
  }

  // DELETAR SETOR
  void deletarSetor(int index) {
    setState(() {
      //removeAt() é um método usado para remover um item de uma lista usando a posição (índice).
      //0 = Gabi
      //1 = Maria
      //2 = João
      setores.removeAt(index);
    });
  }

  // EDITAR SETOR
  void editarSetor(int index) {
    // Cria um controlador para o TextField.
    // O parâmetro text já inicia o campo
    // com o nome atual do setor, permitindo
    // editar o valor existente.
    TextEditingController controller = TextEditingController(
      text: setores[index]["nome"],
    );

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Editar setor"),

          content: TextField(controller: controller),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancelar"),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  setores[index]["nome"] = controller.text;
                });

                Navigator.pop(context);
              },

              child: const Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              // TOPO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  ElevatedButton(
                    onPressed: criarSetor,

                    child: const Text("Criar novo setor"),
                  ),

                  Row(
                    children: const [
                      Text(
                        "Olá ADMIN",

                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(width: 10),

                      CircleAvatar(radius: 22, child: Icon(Icons.person)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // LISTA DE SETORES
              Expanded(
                child: ListView.builder(
                  itemCount: setores.length,

                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) =>
                                SetorScreen(nomeSetor: setores[index]["nome"]),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),

                        height: 120,

                        padding: const EdgeInsets.all(15),

                        decoration: BoxDecoration(
                          color: Colors.grey[400],

                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              setores[index]["nome"],

                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,

                              children: [
                                IconButton(
                                  onPressed: () {
                                    editarSetor(index);
                                  },

                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    deletarSetor(index);
                                  },

                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // BOTÕES INFERIORES
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},

                      child: const Text("Alertas ativos"),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},

                      child: const Text("Gerar relatório (PDF)"),
                    ),
                  ),

                  SizedBox(height: 50),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                  );
                },

                child: const Text("Voltar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
