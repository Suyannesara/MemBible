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
  final respostaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    buscarVersiculos();
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
      return texto.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    }

    if (normalizar(respostaUsuario) == normalizar(respostaCorreta)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Acertou!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Errou!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.livro.toUpperCase()} ${widget.capitulo}"),
        backgroundColor: Colors.red,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: versiculos.length,
                itemBuilder: (context, index) {
                  final verso = versiculos[index];
                  final textoOriginal = verso["text"];
                  final textoOculto = esconderPalavras(textoOriginal);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Verso ${verso["number"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// TEXTO COM LACUNAS
                          Text(
                            textoOculto,
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 15),

                          /// CAMPO DE RESPOSTA
                          TextField(
                            controller: respostaController,
                            decoration: const InputDecoration(
                              labelText: "Digite o versículo completo",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// BOTÃO VERIFICAR
                          ElevatedButton(
                            onPressed: () {
                              verificarResposta(
                                respostaController.text,
                                textoOriginal,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text("Verificar"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
