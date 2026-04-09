import 'package:flutter/material.dart';
import 'services/biblia_service.dart';
import 'versiculos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List livros = [];
  bool carregando = true;

  String? livroSelecionado;
  String capitulo = "1";

  @override
  void initState() {
    super.initState();
    carregarLivros();
  }

  Future<void> carregarLivros() async {
    try {
      final data = await BibliaService.getLivros();

      setState(() {
        livros = data;
        livroSelecionado = livros[0]["abbrev"]["pt"];
        carregando = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Treino Bíblico"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "📖 Escolha o livro",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 20),

                            DropdownButtonFormField<String>(
                              value: livroSelecionado,
                              items: livros.map<DropdownMenuItem<String>>((
                                livro,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: livro["abbrev"]["pt"],
                                  child: Text(livro["name"]),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  livroSelecionado = value;
                                });
                              },
                            ),

                            const SizedBox(height: 15),

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

                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VersiculosPage(
                                      livro: livroSelecionado!,
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
                  ],
                ),
              ),
            ),
    );
  }
}
