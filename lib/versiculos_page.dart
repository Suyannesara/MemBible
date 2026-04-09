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
    List palavras = texto.split(" ");

    int quantidadeEsconder;

    if (widget.nivel == "facil") {
      quantidadeEsconder = (palavras.length * 0.2).round();
    } else if (widget.nivel == "medio") {
      quantidadeEsconder = (palavras.length * 0.4).round();
    } else {
      quantidadeEsconder = (palavras.length * 0.6).round();
    }

    palavras.shuffle();

    for (int i = 0; i < quantidadeEsconder; i++) {
      int index = palavras.indexOf(palavras[i]);
      palavras[index] = "_____";
    }

    return palavras.join(" ");
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
                          Text(
                            esconderPalavras(verso["text"]),
                            style: const TextStyle(fontSize: 16),
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
