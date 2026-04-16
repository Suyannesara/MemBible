import 'package:flutter/material.dart';
import 'versiculos_page.dart';

class CapitulosPage extends StatelessWidget {
  final String livro;
  final List capitulos;

  const CapitulosPage({
    super.key,
    required this.livro,
    required this.capitulos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Capítulos - $livro"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        itemCount: capitulos.length,
        itemBuilder: (context, index) {
          final cap = capitulos[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text("Capítulo ${cap["capitulo"]}"),
              subtitle: Text("🏆 ${cap["acertos"]} acertos"),
              trailing: const Icon(Icons.play_arrow),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VersiculosPage(
                      livro: cap["livro"],
                      capitulo: cap["capitulo"],
                      nivel: cap["nivel"],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}