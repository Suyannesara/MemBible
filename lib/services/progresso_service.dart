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

  static Future<void> salvarMetaDiaria(int meta) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection("usuarios").doc(user.uid).set({
      "metaDiaria": meta,
    }, SetOptions(merge: true));
  }

  static Future<int> carregarMetaDiaria() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 5;

      final doc = await _db.collection("usuarios").doc(user.uid).get();

      final data = doc.data();
      if (data == null) return 5;

      final meta = data["metaDiaria"];

      if (meta is int) return meta;
      if (meta is String) return int.tryParse(meta) ?? 5;

      return 5;
    } catch (e) {
      return 5;
    }
  }

  static Future<void> atualizarUsoDiario() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final hoje = DateTime.now();
    final hojeStr = "${hoje.year}-${hoje.month}-${hoje.day}";

    final ref = _db.collection("usuarios").doc(user.uid);

    await ref.set({"ultimoDiaUso": hojeStr}, SetOptions(merge: true));
  }

  static Future<int> carregarStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final ref = await _db.collection("usuarios").doc(user.uid).get();

    if (!ref.exists) return 0;

    final data = ref.data();
    if (data == null) return 0;

    final ultimo = data["ultimoDiaUso"];

    if (ultimo == null) return 0;

    final parts = ultimo.split("-");
    final lastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final hoje = DateTime.now();

    final diff = hoje.difference(lastDate).inDays;

    if (diff == 0) {
      return 1; // hoje ativo
    } else if (diff == 1) {
      return 2; // continuidade simples (MVP streak)
    } else {
      return 0; // quebrou streak
    }
  }
}
