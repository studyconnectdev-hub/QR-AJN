import 'package:flutter_test/flutter_test.dart';
import 'package:private_safe_qr/core/models/scan_models.dart';
import 'package:private_safe_qr/core/parsing/scan_parser.dart';
import 'package:private_safe_qr/core/security/safe_scan_engine.dart';
import 'package:private_safe_qr/core/security/threat_rules.dart';

void main() {
  const rules = ThreatRules(
    blockedDomains: {'bad.example'},
    trustedDomains: {'example.com'},
    shorteners: {'bit.ly'},
    riskyTlds: {'zip'},
    suspiciousKeywords: {'login', 'verify'},
    dangerousExtensions: {'apk', 'exe'},
    version: 1,
  );

  test('exact trusted HTTPS domain is trusted', () {
    final score = const SafeScanEngine(rules).analyze(ScanParser.parse('https://example.com'));
    expect(score.level, RiskLevel.trusted);
    expect(score.score, greaterThanOrEqualTo(90));
  });

  test('unknown HTTPS domain is not labelled trusted', () {
    final score = const SafeScanEngine(rules).analyze(ScanParser.parse('https://unknown.example'));
    expect(score.level, RiskLevel.safe);
    expect(score.score, lessThan(90));
  });

  test('subdomain does not inherit exact trusted status', () {
    final score = const SafeScanEngine(rules).analyze(ScanParser.parse('https://user-content.example.com'));
    expect(score.level, isNot(RiskLevel.trusted));
  });

  test('blocked domain is dangerous', () {
    final score = const SafeScanEngine(rules).analyze(ScanParser.parse('https://bad.example/login'));
    expect(score.score, 0);
  });

  test('shortened non-HTTPS link has warnings', () {
    final score = const SafeScanEngine(rules).analyze(ScanParser.parse('http://bit.ly/verify'));
    expect(score.warnings, isNotEmpty);
  });
}
