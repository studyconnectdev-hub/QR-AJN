import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../security/threat_rules.dart';
import '../services/firebase_bootstrap.dart';

class AppRuntime {
  static final rules = ValueNotifier<ThreatRules?>(null);

  static Future<void> initialize() => refreshRules();

  static Future<void> refreshRules() async {
    final localMap = jsonDecode(await rootBundle.loadString('assets/data/threat_rules.json')) as Map<String, dynamic>;
    var merged = ThreatRules.fromJson(localMap);
    final trustedMap = jsonDecode(await rootBundle.loadString('assets/data/trusted_domains.json')) as Map<String, dynamic>;
    merged = merged.merge(ThreatRules.fromJson({...trustedMap, 'version': trustedMap['version'] ?? 1}));

    if (FirebaseBootstrap.available) {
      merged = _mergeRemoteConfig(merged);
      try {
        final security = await FirebaseFirestore.instance.doc('public_config/security_rules').get();
        if (security.exists && security.data() != null) merged = merged.merge(ThreatRules.fromJson(security.data()!));
        final trusted = await FirebaseFirestore.instance.doc('public_config/trusted_domains').get();
        if (trusted.exists && trusted.data() != null) merged = merged.merge(ThreatRules.fromJson(trusted.data()!));
      } catch (error) {
        debugPrint('Using bundled/Remote Config threat rules: $error');
      }
    }
    rules.value = merged;
  }

  static ThreatRules _mergeRemoteConfig(ThreatRules current) {
    var merged = current;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      for (final key in const ['threat_rules_json', 'trusted_domains_json']) {
        final raw = remoteConfig.getString(key).trim();
        if (raw.isEmpty) continue;
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) merged = merged.merge(ThreatRules.fromJson(decoded));
      }
    } catch (error) {
      debugPrint('Remote Config safety payload ignored: $error');
    }
    return merged;
  }
}
