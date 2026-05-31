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

    final docId = "${livro}_$capitulo";

    await _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .doc(docId)
        .set({
          "livro": livro,
          "capitulo": capitulo,
          "indice": indice,
          "acertos": acertos,
          "nivel": nivel,
          "updatedAt": FieldValue.serverTimestamp(),
        });
  }

  static Future<Map<String, dynamic>?> carregarProgresso(
    String livro,
    String capitulo,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docId = "${livro}_$capitulo";

    final doc = await _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .doc(docId)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  /// 🔥 NOVO: pegar TODOS os capítulos
  static Future<List<Map<String, dynamic>>> listarCapitulos() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> marcarVersiculoMemorizado({
    required String livro,
    required String capitulo,
    required int versiculo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .doc("${livro}_$capitulo");

    await ref.set({
      "versiculosMemorizados": FieldValue.arrayUnion([versiculo]),
    }, SetOptions(merge: true));
  }

  static Future<List<int>> carregarMemorizados({
    required String livro,
    required String capitulo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .doc("${livro}_$capitulo")
        .get();

    if (!doc.exists) return [];

    final data = doc.data();
    return List<int>.from(data?["versiculosMemorizados"] ?? []);
  }

  static Future<int> contarVersiculosMemorizados() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection("progresso")
        .doc(user.uid)
        .collection("capitulos")
        .get();

    int total = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final list = data["versiculosMemorizados"];

      if (list is List) {
        total += list.length;
      }
    }

    return total;
  }
}
