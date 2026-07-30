enum ScanContentType {
  url,
  appLink,
  upi,
  wifi,
  contact,
  email,
  sms,
  phone,
  location,
  calendar,
  json,
  product,
  text,
}

enum RiskLevel { trusted, safe, caution, suspicious, dangerous }

class ScanPayload {
  const ScanPayload({
    required this.raw,
    required this.type,
    required this.title,
    required this.summary,
    this.actionUri,
    this.details = const {},
    this.format = '',
  });

  final String raw;
  final ScanContentType type;
  final String title;
  final String summary;
  final String? actionUri;
  final Map<String, String> details;
  final String format;
}

class SafetyAssessment {
  const SafetyAssessment({
    required this.score,
    required this.level,
    required this.reasons,
    this.warnings = const [],
  });

  final int score;
  final RiskLevel level;
  final List<String> reasons;
  final List<String> warnings;

  String get label => switch (level) {
        RiskLevel.trusted => 'Trusted',
        RiskLevel.safe => 'Safe',
        RiskLevel.caution => 'Caution',
        RiskLevel.suspicious => 'Suspicious',
        RiskLevel.dangerous => 'Dangerous',
      };
}
