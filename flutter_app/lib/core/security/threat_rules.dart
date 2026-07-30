class ThreatRules {
  const ThreatRules({
    required this.blockedDomains,
    required this.trustedDomains,
    required this.shorteners,
    required this.riskyTlds,
    required this.suspiciousKeywords,
    required this.dangerousExtensions,
    required this.version,
  });

  final Set<String> blockedDomains;
  final Set<String> trustedDomains;
  final Set<String> shorteners;
  final Set<String> riskyTlds;
  final Set<String> suspiciousKeywords;
  final Set<String> dangerousExtensions;
  final int version;

  static ThreatRules fromJson(Map<String, dynamic> json) => ThreatRules(
        blockedDomains: _set(json['blockedDomains']),
        trustedDomains: _set(json['trustedDomains']),
        shorteners: _set(json['shorteners']),
        riskyTlds: _set(json['riskyTlds']),
        suspiciousKeywords: _set(json['suspiciousKeywords']),
        dangerousExtensions: _set(json['dangerousExtensions']),
        version: (json['version'] as num?)?.toInt() ?? 1,
      );

  static Set<String> _set(dynamic value) => value is List ? value.map((e) => e.toString().toLowerCase()).toSet() : <String>{};

  ThreatRules merge(ThreatRules remote) => ThreatRules(
        blockedDomains: {...blockedDomains, ...remote.blockedDomains},
        trustedDomains: {...trustedDomains, ...remote.trustedDomains},
        shorteners: {...shorteners, ...remote.shorteners},
        riskyTlds: {...riskyTlds, ...remote.riskyTlds},
        suspiciousKeywords: {...suspiciousKeywords, ...remote.suspiciousKeywords},
        dangerousExtensions: {...dangerousExtensions, ...remote.dangerousExtensions},
        version: remote.version > version ? remote.version : version,
      );
}
