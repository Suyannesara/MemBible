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

  /// 🔥 BUSCAR + PROGRESSO
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

      setState(() {
        versiculos = data["verses"];
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

  /// 🔥 PROCESSAR PALAVRAS
  List<Map<String, dynamic>> processarVersiculo(String texto) {
    List<String> palavras = texto.split(" ");

    int quantidadeEsconder;

    if (widget.nivel == "facil") {
      quantidadeEsconder = (palavras.length * 0.2).round();
    } else if (widget.nivel == "medio") {
      quantidadeEsconder = (palavras.length * 0.4).round();
    } else {
      quantidadeEsconder = (palavras.length * 0.6).round();
    }

    List<int> indices = List.generate(palavras.length, (i) => i);
    indices.shuffle();

    List<int> escolhidos = indices.take(quantidadeEsconder).toList();

    List<Map<String, dynamic>> resultado = [];

    for (int i = 0; i < palavras.length; i++) {
      resultado.add({
        "texto": palavras[i],
        "escondida": escolhidos.contains(i),
      });
    }

    return resultado;
  }

  /// 🔥 SALVAR
  void salvarProgresso() {
    ProgressoService.salvarProgresso(
      livro: widget.livro,
      capitulo: widget.capitulo,
      indice: indiceAtual,
      acertos: acertos,
      nivel: widget.nivel,
    );
  }

  /// 🔥 VERIFICAR POR PALAVRA
  void verificarRespostaCampos() {
    String normalizar(String texto) {
      return texto.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    }

    int inputIndex = 0;
    bool tudoCorreto = true;

    for (var palavra in palavrasProcessadas) {
      if (palavra["escondida"]) {
        String respostaUsuario = controllers[inputIndex].text;
        String correta = palavra["texto"];

        if (normalizar(respostaUsuario) != normalizar(correta)) {
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

    salvarProgresso();
  }

  /// 🔥 PRÓXIMO
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

      salvarProgresso();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 Terminou! Acertos: $acertos")),
      );
    }
  }

  /// 🔥 VOLTAR
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

  /// 🔥 PROGRESSO
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
    final textoOriginal = verso["text"];

    /// 🔥 PROCESSA UMA VEZ
    if (palavrasProcessadas.isEmpty) {
      palavrasProcessadas = processarVersiculo(textoOriginal);

      controllers = palavrasProcessadas
          .where((p) => p["escondida"])
          .map((_) => TextEditingController())
          .toList();
    }

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
              LinearProgressIndicator(
                value: progresso(),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                color: Colors.white,
              ),

              const SizedBox(height: 10),

              Text(
                "Versículo ${indiceAtual + 1} de ${versiculos.length}",
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 20),

              Text(
                "Versículo ${verso["number"]}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// 🔥 TEXTO COM INPUTS
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: palavrasProcessadas.map((palavra) {
                          if (!palavra["escondida"]) {
                            return Text(
                              palavra["texto"],
                              style: const TextStyle(fontSize: 18),
                            );
                          } else {
                            int index = palavrasProcessadas
                                .where((p) => p["escondida"])
                                .toList()
                                .indexOf(palavra);

                            String digitado = controllers[index].text;

                            bool correta = digitado.toLowerCase().trim() ==
                                palavra["texto"].toLowerCase().trim();

                            return SizedBox(
                              width: 90,
                              child: TextField(
                                controller: controllers[index],
                                enabled: !respondeu,
                                decoration: InputDecoration(
                                  hintText: "___",
                                  border: const OutlineInputBorder(),
                                  filled: respondeu,
                                  fillColor: respondeu
                                      ? (correta
                                          ? Colors.green[200]
                                          : Colors.red[200])
                                      : null,
                                ),
                              ),
                            );
                          }
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      if (!respondeu)
                        ElevatedButton(
                          onPressed: verificarRespostaCampos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Verificar"),
                        ),

                      const SizedBox(height: 20),

                      if (respondeu)
                        Column(
                          children: [
                            Text(
                              acertou ? "✅ Acertou!" : "❌ Errou!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: acertou ? Colors.green : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (!acertou)
                              Text(
                                textoOriginal,
                                style: const TextStyle(fontSize: 16),
                              ),

                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: proximoVersiculo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text("Próximo"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: indiceAtual > 0 ? voltarVersiculo : null,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: indiceAtual < versiculos.length - 1
                        ? proximoVersiculo
                        : null,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}