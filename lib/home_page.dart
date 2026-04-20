import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/progresso_service.dart';
import 'package:flutter/material.dart';
import 'services/biblia_service.dart';
import 'versiculos_page.dart';
import 'capitulos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List livros = [];
  List<Map<String, dynamic>> capitulosSalvos = [];

  bool carregando = true;

  String nivel = "facil";
  String? livroSelecionado;
  String capitulo = "1";

  final capituloController = TextEditingController();
  TextEditingController? typeAheadController;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> carregarDados() async {
    try {
      final dataLivros = await BibliaService.getLivros();
      final caps = await ProgressoService.listarCapitulos();

      setState(() {
        livros = dataLivros;
        capitulosSalvos = caps;

        if (livros.isNotEmpty) {
          livroSelecionado = livros[0]["abbrev"]["pt"];
        }

        carregando = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        carregando = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> agruparPorLivro() {
    Map<String, List<Map<String, dynamic>>> mapa = {};

    for (var cap in capitulosSalvos) {
      final livro = cap["livro"];

      if (!mapa.containsKey(livro)) {
        mapa[livro] = [];
      }

      mapa[livro]!.add(cap);
    }

    return mapa;
  }

  double progressoLivro(List caps) {
    int total = caps.length;
    int somaIndices = 0;

    for (var cap in caps) {
      somaIndices += (cap["indice"] is num)
          ? (cap["indice"] as num).toInt()
          : 0;
    }

    return total == 0 ? 0 : (somaIndices / (total * 30));
  }

  bool capituloValido() {
    if (livroSelecionado == null) return false;

    final livro = livros.firstWhere(
      (l) => l["abbrev"]["pt"] == livroSelecionado,
    );

    int totalCaps = livro["chapters"];

    final cap = int.tryParse(capituloController.text);

    if (cap == null) return false;

    return cap >= 1 && cap <= totalCaps;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final livrosMap = agruparPorLivro();
    final listaLivros = livrosMap.keys.toList();

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              accountName: const Text(""),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ?? "",
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.red),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Sair"),
              onTap: () async {
                Navigator.pop(context);
                await logout();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Treino Bíblico"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "📖 Novo treino",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LIVRO
                      DropdownButtonFormField<String>(
                        value: livroSelecionado,
                        items: livros.map<DropdownMenuItem<String>>((livro) {
                          return DropdownMenuItem<String>(
                            value: livro["abbrev"]["pt"],
                            child: Text(livro["name"]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            livroSelecionado = value;
                            capituloController.clear();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Livro",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// CAPÍTULO
                      TypeAheadField<int>(
                        builder: (context, controller, focusNode) {
                          typeAheadController = controller;

                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Capítulo",
                              border: const OutlineInputBorder(),
                              errorText:
                                  controller.text.isEmpty || capituloValido()
                                  ? null
                                  : "Capítulo inválido",
                            ),
                            onChanged: (value) {
                              capituloController.text = value;
                              setState(() {});
                            },
                          );
                        },

                        suggestionsCallback: (pattern) {
                          if (livroSelecionado == null) return [];

                          final livro = livros.firstWhere(
                            (l) => l["abbrev"]["pt"] == livroSelecionado,
                          );

                          int totalCaps = livro["chapters"];
                          final lista = List.generate(totalCaps, (i) => i + 1);

                          if (pattern.isEmpty) return lista;

                          final numeroDigitado = int.tryParse(pattern);

                          if (numeroDigitado != null) {
                            final filtrados = lista
                                .where((c) => c.toString().startsWith(pattern))
                                .toList();

                            filtrados.sort((a, b) {
                              if (a == numeroDigitado) return -1;
                              if (b == numeroDigitado) return 1;
                              return a.compareTo(b);
                            });

                            return filtrados;
                          }

                          return [];
                        },

                        itemBuilder: (context, suggestion) {
                          return ListTile(title: Text("Capítulo $suggestion"));
                        },

                        onSelected: (suggestion) {
                          final texto = suggestion.toString();

                          capitulo = texto;
                          capituloController.text = texto;
                          typeAheadController?.text = texto;

                          setState(() {});
                        },

                        emptyBuilder: (context) => const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("Capítulo não encontrado"),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// NÍVEL
                      DropdownButtonFormField<String>(
                        value: nivel,
                        items: const [
                          DropdownMenuItem(
                            value: "facil",
                            child: Text("Fácil"),
                          ),
                          DropdownMenuItem(
                            value: "medio",
                            child: Text("Médio"),
                          ),
                          DropdownMenuItem(
                            value: "dificil",
                            child: Text("Difícil"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            nivel = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Dificuldade",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// BOTÃO
                      ElevatedButton(
                        onPressed: () {
                          if (!capituloValido()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Capítulo inválido 😬"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VersiculosPage(
                                livro: livroSelecionado!,
                                capitulo: capituloController.text,
                                nivel: nivel,
                              ),
                            ),
                          ).then((_) => carregarDados());
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
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "📊 Seu progresso",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: listaLivros.isEmpty
                  ? const Center(
                      child: Text(
                        "Nenhum progresso ainda.\nComece a praticar!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      itemCount: listaLivros.length,
                      itemBuilder: (context, index) {
                        final livro = listaLivros[index];
                        final caps = livrosMap[livro]!;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          child: ListTile(
                            title: Text("📖 $livro"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                LinearProgressIndicator(
                                  value: progressoLivro(caps),
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 5),
                                Text("${caps.length} capítulos estudados"),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CapitulosPage(
                                    livro: livro,
                                    capitulos: caps,
                                  ),
                                ),
                              ).then((_) => carregarDados());
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
