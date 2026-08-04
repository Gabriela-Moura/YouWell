import 'package:flutter/material.dart';
import 'package:youwell/main.dart';

void main() {
  runApp(SobreNos());
}

class SobreNos extends StatelessWidget {
  const SobreNos({super.key});

  @override
  Widget build(BuildContext context) {
    double largura = MediaQuery.of(context).size.width;
    double altura = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 85, 64),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sobre a YouWell",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: largura * 0.85,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/sistema.png',
                          width: largura * 0.8,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "A YouWell é uma plataforma da DataBee que auxilia empresas no monitoramento e na melhoria das condições do ambiente de trabalho.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Monitore:",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 32,
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Temperatura
                    Container(
                      width: largura * 0.45,
                      height: altura * 0.15,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(178, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Icon(
                              Icons.thermostat,
                              size: 50,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Temperatura",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Umidade
                    Container(
                      width: largura * 0.45,
                      height: altura * 0.15,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(178, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Icon(
                              Icons.water_drop,
                              size: 50,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Umidade",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Qualidade do ar
                    Container(
                      width: largura * 0.45,
                      height: altura * 0.15,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(178, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Icon(
                              Icons.air,
                              size: 50,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Qualidade do ar",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ruído
                    Container(
                      width: largura * 0.45,
                      height: altura * 0.15,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(178, 255, 255, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Icon(
                              Icons.volume_up,
                              size: 50,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Ruído",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color.fromARGB(255, 10, 85, 64),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Container(
                  width: largura * 0.9,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        "Essas informações ajudam as empresas a criar ambientes mais seguros e saudáveis, promovendo o bem-estar dos colaboradores e aumentando a produtividade.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Nossa Equipe",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Container(
                  width: largura * 0.9,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/equipe.png',
                          width: 700,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: largura * 0.8,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: Image.asset(
                          'assets/images/samuel.png',
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Designer / Front-End",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: largura * 0.8,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: Image.asset(
                          'assets/images/yago.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Back-End",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: largura * 0.8,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: Image.asset(
                          'assets/images/gabi.png',
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Production Owner/FullStack",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: largura * 0.8,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: Image.asset(
                          'assets/images/amanda.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Documentação e testes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: largura * 0.8,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color.fromARGB(140, 220, 220, 220),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: Image.asset(
                          'assets/images/diego.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "Analista e criador de Banco de dados",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    );
                  },

                  child: const Text("Voltar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
