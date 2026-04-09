import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VersiculosPage extends StatefulWidget {
  final String livro;
  final String capitulo;

  const VersiculosPage({
    super.key,
    required this.livro,
    required this.capitulo,
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
      final url =
          "https://bible-api.com/${widget.livro}+${widget.capitulo}";

      final response = await http.get(Uri.parse(url));

      final data = json.decode(response.body);

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
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.orange],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
                            "Verso ${verso["verse"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            verso["text"],
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