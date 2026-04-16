import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressoService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> salvarProgresso({
    required String livro,
    required String capitulo,
    required int indice,
    required int acertos,
    required String nivel,
  }) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _db.collection("progresso").doc(user.uid).set({
      "livro": livro,
      "capitulo": capitulo,
      "indice": indice,
      "acertos": acertos,
      "nivel": nivel,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> carregarProgresso() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc =
        await _db.collection("progresso").doc(user.uid).get();

    if (!doc.exists) return null;

    return doc.data();
  }
}