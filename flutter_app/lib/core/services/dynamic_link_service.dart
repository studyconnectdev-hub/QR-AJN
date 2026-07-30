import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import 'firebase_bootstrap.dart';

class DynamicQrLink {
  const DynamicQrLink({
    required this.code,
    required this.title,
    required this.destination,
    this.androidDestination = '',
    this.iosDestination = '',
    this.desktopDestination = '',
    this.fallbackDestination = '',
    this.active = true,
    this.expiresAt,
    this.maximumScans,
    this.scanCount = 0,
  });

  final String code;
  final String title;
  final String destination;
  final String androidDestination;
  final String iosDestination;
  final String desktopDestination;
  final String fallbackDestination;
  final bool active;
  final DateTime? expiresAt;
  final int? maximumScans;
  final int scanCount;

  String get publicUrl => '${AppConfig.publicDomain}/q/$code';

  factory DynamicQrLink.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      DynamicQrLink(
        code: id,
        title: '${data['title'] ?? 'Dynamic QR'}',
        destination: '${data['destination'] ?? ''}',
        androidDestination: '${data['androidDestination'] ?? ''}',
        iosDestination: '${data['iosDestination'] ?? ''}',
        desktopDestination: '${data['desktopDestination'] ?? ''}',
        fallbackDestination: '${data['fallbackDestination'] ?? ''}',
        active: data['active'] != false,
        expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
        maximumScans: data['maximumScans'] is num
            ? (data['maximumScans'] as num).toInt()
            : null,
        scanCount:
            data['scanCount'] is num ? (data['scanCount'] as num).toInt() : 0,
      );

  Map<String, dynamic> toFirestore(String ownerUid) => <String, dynamic>{
        'ownerUid': ownerUid,
        'title': title,
        'destination': destination,
        'androidDestination': androidDestination,
        'iosDestination': iosDestination,
        'desktopDestination': desktopDestination,
        'fallbackDestination': fallbackDestination,
        'active': active,
        'expiresAt':
            expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'maximumScans': maximumScans,
        'scanCount': scanCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

class DynamicLinkService {
  const DynamicLinkService._();

  static Future<List<DynamicQrLink>> loadMine() async {
    if (!FirebaseBootstrap.available) return const <DynamicQrLink>[];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const <DynamicQrLink>[];

    final snapshot = await FirebaseFirestore.instance
        .collection('dynamic_links')
        .where('ownerUid', isEqualTo: user.uid)
        .limit(100)
        .get();
    final links = snapshot.docs
        .map((document) =>
            DynamicQrLink.fromFirestore(document.id, document.data()))
        .toList();
    links.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return links;
  }

  static Future<DynamicQrLink> save(DynamicQrLink link) async {
    if (!FirebaseBootstrap.available) {
      throw StateError('Firebase is not configured.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to manage dynamic QR links.');
    if (!_isHttpUrl(link.destination)) {
      throw StateError('Enter a valid HTTPS destination.');
    }

    final code = link.code.trim().isEmpty ? _newCode() : _normalizeCode(link.code);
    final result = DynamicQrLink(
      code: code,
      title: link.title.trim().isEmpty ? 'Dynamic QR' : link.title.trim(),
      destination: link.destination.trim(),
      androidDestination: link.androidDestination.trim(),
      iosDestination: link.iosDestination.trim(),
      desktopDestination: link.desktopDestination.trim(),
      fallbackDestination: link.fallbackDestination.trim(),
      active: link.active,
      expiresAt: link.expiresAt,
      maximumScans: link.maximumScans,
      scanCount: link.scanCount,
    );
    await FirebaseFirestore.instance
        .collection('dynamic_links')
        .doc(code)
        .set(result.toFirestore(user.uid), SetOptions(merge: true));
    return result;
  }

  static Future<void> delete(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (!FirebaseBootstrap.available || user == null) return;
    await FirebaseFirestore.instance
        .collection('dynamic_links')
        .doc(code)
        .delete();
  }

  static String _newCode() =>
      const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();

  static String _normalizeCode(String value) {
    final normalized = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '');
    if (normalized.isEmpty) return _newCode();
    return normalized.length <= 12 ? normalized : normalized.substring(0, 12);
  }

  static bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }
}
