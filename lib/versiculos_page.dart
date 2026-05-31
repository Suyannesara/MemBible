import 'package:flutter/material.dart';
import 'services/progresso_service.dart';
import 'services/biblia_service.dart';

class VersiculosPage extends StatefulWidget {
  final String livro;
  final String capitulo;
  final String nivel;

  const VersiculosPage({
    super.key,
    required this.livro,
    required this.capitulo,
    required this.nivel,
  });

  @override
  State<VersiculosPage> createState() => _VersiculosPageState();
}

class _VersiculosPageState extends State<VersiculosPage> {
  List versiculos = [];
  List<int> memorizados = [];

  bool carregando = true;

  int indiceAtual = 0;
  bool respondeu = false;
  bool acertou = false;
  int acertos = 0;

  List<TextEditingController> controllers = [];
  List<Map<String, dynamic>> palavrasProcessadas = [];

  @override
  void initState() {
    super.initState();
    buscarVersiculos();
  }

  @override
  void dispose() {
    for (var c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> buscarVersiculos() async {
    try {
      final data = await BibliaService.getVersiculos(
        "nvi",
        widget.livro,
        widget.capitulo,
      );

      final progresso = await ProgressoService.carregarProgresso(
        widget.livro,
        widget.capitulo,
      );

      final mem = await ProgressoService.carregarMemorizados(
        livro: widget.livro,
        capitulo: widget.capitulo,
      );

      setState(() {
        versiculos = data["verses"];
        memorizados = mem;
        carregando = false;

        if (progresso != null) {
          indiceAtual = (progresso["indice"] ?? 0).toInt();
          acertos = (progresso["acertos"] ?? 0).toInt();
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        carregando = false;
      });
    }
  }

  List<Map<String, dynamic>> processarVersiculo(String texto) {
    List<String> palavras = texto.split(" ");

    int qtd = widget.nivel == "facil"
        ? (palavras.length * 0.2).round()
        : widget.nivel == "medio"
            ? (palavras.length * 0.4).round()
            : (palavras.length * 0.6).round();

    List<int> indices = List.generate(palavras.length, (i) => i);
    indices.shuffle();

    List<int> escondidas = indices.take(qtd).toList();

    return List.generate(palavras.length, (i) {
      return {
        "texto": palavras[i],
        "escondida": escondidas.contains(i),
      };
    });
  }

  void verificarRespostaCampos() {
    String norm(String t) =>
        t.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    int inputIndex = 0;
    bool tudoCorreto = true;

    for (var p in palavrasProcessadas) {
      if (p["escondida"]) {
        if (norm(controllers[inputIndex].text) != norm(p["texto"])) {
          tudoCorreto = false;
        }
        inputIndex++;
      }
    }

    setState(() {
      respondeu = true;
      acertou = tudoCorreto;
      if (acertou) acertos++;
    });

    ProgressoService.salvarProgresso(
      livro: widget.livro,
      capitulo: widget.capitulo,
      indice: indiceAtual,
      acertos: acertos,
      nivel: widget.nivel,
    );
  }

  void proximoVersiculo() {
    if (indiceAtual < versiculos.length - 1) {
      setState(() {
        indiceAtual++;
        respondeu = false;
        acertou = false;

        palavrasProcessadas = [];
        for (var c in controllers) {
          c.dispose();
        }
        controllers.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Terminou!")),
      );
    }
  }

  void voltarVersiculo() {
    if (indiceAtual > 0) {
      setState(() {
        indiceAtual--;
        respondeu = false;
        acertou = false;

        palavrasProcessadas = [];
        for (var c in controllers) {
          c.dispose();
        }
        controllers.clear();
      });
    }
  }

  double progresso() {
    if (versiculos.isEmpty) return 0;
    return (indiceAtual + 1) / versiculos.length;
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final verso = versiculos[indiceAtual];

    if (palavrasProcessadas.isEmpty) {
      palavrasProcessadas = processarVersiculo(verso["text"]);

      controllers = palavrasProcessadas
          .where((p) => p["escondida"])
          .map((_) => TextEditingController())
          .toList();
    }

    int inputIndex = 0;

    final int versiculoNumero = verso["number"];

    final bool isMemorizado = memorizados.contains(versiculoNumero);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.livro.toUpperCase()} ${widget.capitulo}"),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(value: progresso()),
              const SizedBox(height: 10),

              Text(
                "Versículo $versiculoNumero ${isMemorizado ? "✔" : ""}",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: palavrasProcessadas.map((p) {
                      if (!p["escondida"]) {
                        return Text(p["texto"]);
                      } else {
                        final index = inputIndex++;
                        final c = controllers[index];

                        return SizedBox(
                          width: 90,
                          child: TextField(
                            controller: c,
                            enabled: !respondeu,
                            decoration: InputDecoration(
                              hintText: "___",
                              filled: respondeu,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (!respondeu)
                ElevatedButton(
                  onPressed: verificarRespostaCampos,
                  child: const Text("Verificar"),
                ),

              if (respondeu)
                ElevatedButton(
                  onPressed: proximoVersiculo,
                  child: const Text("Próximo"),
                ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () async {
                  await ProgressoService.marcarVersiculoMemorizado(
                    livro: widget.livro,
                    capitulo: widget.capitulo,
                    versiculo: versiculoNumero,
                  );

                  setState(() {
                    if (!memorizados.contains(versiculoNumero)) {
                      memorizados.add(versiculoNumero);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: Text(
                  isMemorizado
                      ? "✔ Já memorizado"
                      : "✔ Marcar como memorizado",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}