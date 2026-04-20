import 'package:flutter/material.dart';
import 'services/biblia_service.dart';
import 'services/progresso_service.dart';
import 'versiculos_page.dart';
import 'capitulos_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              accountName: const Text("Usuário"),
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
                          if (livroSelecionado == null || capitulo.isEmpty)
                            return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VersiculosPage(
                                livro: livroSelecionado!,
                                capitulo: capitulo,
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

            /// 🔥 TÍTULO
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

            /// 🔥 LISTA POR LIVRO
            Expanded(
              child: listaLivros.isEmpty
                  ? const Center(
                      child: Text(
                        "Nenhum progresso ainda 😢",
                        style: TextStyle(color: Colors.white),
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
