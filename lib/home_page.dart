import 'package:flutter/material.dart';
import 'versiculos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String livroSelecionado = "john";
  String capitulo = "3";

  final livros = [
    "genesis",
    "psalms",
    "proverbs",
    "john",
    "romans"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Treino Bíblico"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.orange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// CARD PRINCIPAL
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "📖 Escolha seu treino",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LIVROS
                      DropdownButtonFormField(
                        value: livroSelecionado,
                        items: livros.map((livro) {
                          return DropdownMenuItem(
                            value: livro,
                            child: Text(livro.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            livroSelecionado = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Livro",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// CAPÍTULO
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Capítulo",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          capitulo = value;
                        },
                      ),

                      const SizedBox(height: 20),

                      /// BOTÃO INICIAR
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VersiculosPage(
                                livro: livroSelecionado,
                                capitulo: capitulo,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("🔥 Iniciar treino"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// CARD GAMEFICADO
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "🏆 Seu progresso",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(value: 0.3),
                      SizedBox(height: 10),
                      Text("30% completo"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}