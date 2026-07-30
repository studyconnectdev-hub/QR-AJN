import '../models/scan_models.dart';
import 'threat_rules.dart';

class SafeScanEngine {
  const SafeScanEngine(this.rules);
  final ThreatRules rules;

  SafetyAssessment analyze(ScanPayload payload) {
    return switch (payload.type) {
      ScanContentType.url => _url(payload),
      ScanContentType.appLink => _appLink(payload),
      ScanContentType.upi => _upi(payload),
      _ => const SafetyAssessment(
          score: 85,
          level: RiskLevel.safe,
          reasons: ['Processed locally; no automatic action will be taken.'],
        ),
    };
  }

  SafetyAssessment _url(ScanPayload payload) {
    final uri = Uri.tryParse(payload.actionUri ?? payload.raw);
    if (uri == null || uri.host.isEmpty) {
      return const SafetyAssessment(
        score: 10,
        level: RiskLevel.dangerous,
        reasons: ['The URL is malformed.'],
      );
    }

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    var score = 85;
    var verifiedTrusted = false;
    final reasons = <String>[];
    final warnings = <String>[];

    if (rules.blockedDomains.any((domain) => host == domain || host.endsWith('.$domain'))) {
      return const SafetyAssessment(
        score: 0,
        level: RiskLevel.dangerous,
        reasons: ['This domain is present in the current blocked-domain rules.'],
      );
    }
    if (rules.trustedDomains.contains(host)) {
      verifiedTrusted = true;
      score += 10;
      reasons.add('The exact domain matches the trusted-business directory.');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      score -= 20;
      warnings.add('The link does not use HTTPS.');
    } else {
      reasons.add('The link uses HTTPS.');
    }
    if (_isIpAddress(host)) {
      score -= 35;
      warnings.add('The destination uses an IP address instead of a normal domain.');
    }
    if (host.codeUnits.any((code) => code > 127) || host.startsWith('xn--')) {
      score -= 25;
      warnings.add('The domain may contain international look-alike characters.');
    }
    if (rules.shorteners.contains(host)) {
      score -= 20;
      warnings.add('This is a shortened link; the final destination is hidden.');
    }
    final tld = host.contains('.') ? host.split('.').last : '';
    if (rules.riskyTlds.contains(tld)) {
      score -= 10;
      warnings.add('The top-level domain has a higher abuse rate in the current rules.');
    }
    final lower = uri.toString().toLowerCase();
    final keywordHits = rules.suspiciousKeywords.where(lower.contains).take(3).toList();
    if (keywordHits.isNotEmpty) {
      score -= 8 * keywordHits.length;
      warnings.add('Sensitive or deceptive words detected: ${keywordHits.join(', ')}.');
    }
    if (rules.dangerousExtensions.any((extension) => uri.path.toLowerCase().endsWith('.$extension'))) {
      score -= 35;
      warnings.add('The link points to a potentially dangerous downloadable file.');
    }
    if (uri.userInfo.isNotEmpty) {
      score -= 20;
      warnings.add('The URL contains embedded user information, which can disguise the host.');
    }
    if (uri.toString().length > 300) {
      score -= 10;
      warnings.add('The URL is unusually long.');
    }

    score = score.clamp(0, 100).toInt();
    if (!verifiedTrusted) {
      reasons.add('No blocked-domain match was found, but this is not a guarantee that the site is safe.');
      score = score.clamp(0, 89).toInt();
    }
    return SafetyAssessment(
      score: score,
      level: _level(score, allowTrusted: verifiedTrusted),
      reasons: reasons,
      warnings: warnings,
    );
  }

  SafetyAssessment _appLink(ScanPayload payload) {
    final uri = Uri.tryParse(payload.actionUri ?? payload.raw);
    if (uri == null || uri.scheme.isEmpty) {
      return const SafetyAssessment(
        score: 20,
        level: RiskLevel.dangerous,
        reasons: ['The app link is malformed.'],
      );
    }
    var score = 68;
    final warnings = <String>[
      'This link may open another installed application. Confirm the destination before continuing.',
    ];
    if (uri.scheme.toLowerCase() == 'intent') {
      score -= 12;
      warnings.add('Android intent links can include fallback and package instructions.');
    }
    return SafetyAssessment(
      score: score,
      level: _level(score, allowTrusted: false),
      reasons: ['The scheme was parsed locally and no action is automatic.'],
      warnings: warnings,
    );
  }

  SafetyAssessment _upi(ScanPayload payload) {
    var score = 88;
    final warnings = <String>[];
    final reasons = <String>[
      'Payment details were parsed locally and require confirmation in the payment application.',
    ];
    final payee = payload.details['UPI ID'] ?? '';
    if (!RegExp(r'^[A-Za-z0-9._-]{2,}@[A-Za-z0-9.-]{2,}$').hasMatch(payee)) {
      score -= 45;
      warnings.add('The UPI ID format is invalid or incomplete.');
    }
    final amountText = payload.details['Amount'] ?? '';
    final amount = amountText == 'Not fixed' ? null : double.tryParse(amountText);
    if (amountText != 'Not fixed' && amount == null) {
      score -= 35;
      warnings.add('The fixed amount is not a valid number.');
    } else if (amount != null && amount <= 0) {
      score -= 50;
      warnings.add('The amount must be greater than zero.');
    }
    if ((payload.details['Payee name'] ?? '').trim().isEmpty) {
      score -= 8;
      warnings.add('The QR does not provide a payee display name. Verify the recipient in the payment app.');
    }
    score = score.clamp(0, 89).toInt();
    return SafetyAssessment(
      score: score,
      level: _level(score, allowTrusted: false),
      reasons: reasons,
      warnings: warnings,
    );
  }

  static bool _isIpAddress(String host) =>
      RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host) || host.contains(':');

  static RiskLevel _level(int score, {required bool allowTrusted}) {
    if (allowTrusted && score >= 90) return RiskLevel.trusted;
    if (score >= 75) return RiskLevel.safe;
    if (score >= 55) return RiskLevel.caution;
    if (score >= 30) return RiskLevel.suspicious;
    return RiskLevel.dangerous;
  }
}
