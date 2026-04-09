import 'package:flutter/material.dart';
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

  final respostaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    buscarVersiculos();
  }

  @override
  void dispose() {
    respostaController.dispose();
    super.dispose();
  }

  Future<void> buscarVersiculos() async {
    try {
      final data = await BibliaService.getVersiculos(
        "acf",
        widget.livro,
        widget.capitulo,
      );

      setState(() {
        versiculos = data["verses"];
        carregando = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        carregando = false;
      });
    }
  }

  String esconderPalavras(String texto) {
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

    for (int i = 0; i < quantidadeEsconder; i++) {
      palavras[indices[i]] = "_____";
    }

    return palavras.join(" ");
  }

  void verificarResposta(String respostaUsuario, String respostaCorreta) {
    String normalizar(String texto) {
      return texto
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
    }

    setState(() {
      respondeu = true;
      acertou =
          normalizar(respostaUsuario) == normalizar(respostaCorreta);
    });
  }

  void proximoVersiculo() {
    if (indiceAtual < versiculos.length - 1) {
      setState(() {
        indiceAtual++;
        respondeu = false;
        respostaController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Você terminou o capítulo!")),
      );
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
    final textoOriginal = verso["text"];
    final textoOculto = esconderPalavras(textoOriginal);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.livro.toUpperCase()} ${widget.capitulo}"),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.orange],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// 🔥 PROGRESSO
              LinearProgressIndicator(
                value: progresso(),
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                color: Colors.white,
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

                      /// TEXTO COM LACUNAS
                      Text(
                        textoOculto,
                        style: const TextStyle(fontSize: 18),
                      ),

                      const SizedBox(height: 20),

                      /// INPUT
                      TextField(
                        controller: respostaController,
                        enabled: !respondeu,
                        decoration: const InputDecoration(
                          labelText: "Digite o versículo completo",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// BOTÃO VERIFICAR
                      if (!respondeu)
                        ElevatedButton(
                          onPressed: () {
                            verificarResposta(
                              respostaController.text,
                              textoOriginal,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Verificar"),
                        ),

                      const SizedBox(height: 20),

                      /// FEEDBACK
                      if (respondeu)
                        Column(
                          children: [
                            Text(
                              acertou ? "✅ Acertou!" : "❌ Errou!",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: acertou
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// MOSTRAR RESPOSTA CORRETA
                            if (!acertou)
                              Text(
                                textoOriginal,
                                style: const TextStyle(fontSize: 16),
                              ),

                            const SizedBox(height: 20),

                            /// PRÓXIMO
                            ElevatedButton(
                              onPressed: proximoVersiculo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize:
                                    const Size(double.infinity, 50),
                              ),
                              child: const Text("Próximo"),
                            ),
                          ],
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