import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../services/firebase_bootstrap.dart';

class CommunityReportService {
  const CommunityReportService._();
  static int _reportsThisSession = 0;

  static Future<bool> report(String raw, String reason) async {
    if (!FirebaseBootstrap.available || _reportsThisSession >= 3) return false;
    final uri = Uri.tryParse(raw);
    final host = (uri?.host ?? '').toLowerCase();
    if (host.isEmpty) return false;
    final hostHash = sha256.convert(utf8.encode(host)).toString();
    try {
      await FirebaseFirestore.instance.collection('community_reports').add({
        'hostHash': hostHash,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      _reportsThisSession += 1;
      return true;
    } catch (_) { return false; }
  }
}
