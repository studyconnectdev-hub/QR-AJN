import 'dart:convert';
import '../models/scan_models.dart';

class ScanParser {
  const ScanParser._();

  static const _webSchemes = {'http', 'https'};
  static const _paymentSchemes = {'upi', 'tez', 'phonepe', 'paytmmp'};
  static const _safeAppSchemes = {
    'market',
    'intent',
    'whatsapp',
    'tg',
    'telegram',
    'instagram',
    'fb',
    'maps',
    'google.navigation',
  };
  static const _productFormats = ['ean', 'upc', 'code128', 'code39', 'itf', 'codabar'];

  static ScanPayload parse(String raw, {String format = ''}) {
    final value = raw.trim();
    final lower = value.toLowerCase();

    if (_looksLikePayment(value)) return _upi(value, format);
    if (lower.startsWith('wifi:')) return _wifi(value, format);
    if (lower.startsWith('begin:vcard') || lower.startsWith('mecard:')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.contact,
        title: 'Contact card',
        summary: 'Preview contact details before saving.',
        details: lower.startsWith('mecard:') ? _mecard(value) : _vcard(value),
        format: format,
      );
    }
    if (lower.startsWith('begin:vevent')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.calendar,
        title: 'Calendar event',
        summary: 'Calendar event details',
        details: _lines(value),
        format: format,
      );
    }
    if (lower.startsWith('mailto:') || lower.startsWith('matmsg:')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.email,
        title: 'Email',
        summary: _emailSummary(value),
        actionUri: lower.startsWith('mailto:') ? value : _matmsgToMailto(value),
        format: format,
      );
    }
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.sms,
        title: 'SMS message',
        summary: value,
        actionUri: lower.startsWith('sms:') ? value : 'sms:${value.substring(6)}',
        format: format,
      );
    }
    if (lower.startsWith('tel:')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.phone,
        title: 'Phone number',
        summary: value.substring(4),
        actionUri: value,
        format: format,
      );
    }
    if (lower.startsWith('geo:')) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.location,
        title: 'Location',
        summary: value.substring(4),
        actionUri: value,
        format: format,
      );
    }

    final uri = Uri.tryParse(value);
    if (uri != null && _webSchemes.contains(uri.scheme.toLowerCase()) && uri.host.isNotEmpty) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.url,
        title: 'Website link',
        summary: uri.host,
        actionUri: value,
        details: {
          'Scheme': uri.scheme,
          'Domain': uri.host,
          'Path': uri.path.isEmpty ? '/' : uri.path,
          if (uri.query.isNotEmpty) 'Query': uri.query,
        },
        format: format,
      );
    }

    if (uri != null && uri.scheme.isNotEmpty && (_safeAppSchemes.contains(uri.scheme.toLowerCase()) || value.contains('://'))) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.appLink,
        title: 'App or deep link',
        summary: uri.scheme.toUpperCase(),
        actionUri: value,
        details: {
          'Scheme': uri.scheme,
          if (uri.host.isNotEmpty) 'Target': uri.host,
          if (uri.path.isNotEmpty) 'Path': uri.path,
        },
        format: format,
      );
    }

    if (_looksLikeJson(value)) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.json,
        title: 'JSON data',
        summary: 'Structured JSON content',
        details: const {'Valid JSON': 'Yes'},
        format: format,
      );
    }
    if (_productFormats.any((item) => format.toLowerCase().contains(item))) {
      return ScanPayload(
        raw: value,
        type: ScanContentType.product,
        title: 'Product barcode',
        summary: value,
        details: {'Format': format},
        format: format,
      );
    }
    return ScanPayload(
      raw: value,
      type: ScanContentType.text,
      title: 'Text',
      summary: value,
      format: format,
    );
  }

  static bool _looksLikePayment(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return value.toLowerCase().startsWith('upi://pay');
    final scheme = uri.scheme.toLowerCase();
    return _paymentSchemes.contains(scheme) &&
        (scheme == 'upi' || uri.host.toLowerCase().contains('pay') || uri.path.toLowerCase().contains('pay'));
  }

  static ScanPayload _upi(String value, String format) {
    final uri = Uri.tryParse(value);
    final q = uri?.queryParameters ?? const <String, String>{};
    final details = <String, String>{
      'UPI ID': q['pa'] ?? q['payeeVpa'] ?? '',
      'Payee name': q['pn'] ?? q['payeeName'] ?? '',
      'Amount': q['am'] ?? q['amount'] ?? 'Not fixed',
      'Currency': q['cu'] ?? 'INR',
      'Note': q['tn'] ?? q['transactionNote'] ?? '',
      'Reference': q['tr'] ?? q['transactionRefId'] ?? '',
      'Merchant category': q['mc'] ?? '',
      'Source scheme': uri?.scheme ?? 'upi',
    };
    final display = details['Payee name']!.trim().isEmpty ? details['UPI ID']! : details['Payee name']!;
    final actionUri = uri?.scheme.toLowerCase() == 'upi'
        ? value
        : Uri(scheme: 'upi', host: 'pay', queryParameters: q).toString();
    return ScanPayload(
      raw: value,
      type: ScanContentType.upi,
      title: 'UPI payment request',
      summary: display.isEmpty ? 'Payment request' : display,
      actionUri: actionUri,
      details: details,
      format: format,
    );
  }

  static ScanPayload _wifi(String value, String format) {
    final map = _parseEscapedFields(value.substring(5));
    return ScanPayload(
      raw: value,
      type: ScanContentType.wifi,
      title: 'Wi-Fi network',
      summary: map['S'] ?? 'Unnamed network',
      details: {
        'Network': map['S'] ?? '',
        'Security': map['T'] ?? 'Unknown',
        'Hidden': map['H'] ?? 'false',
        'Password': map['P']?.isNotEmpty == true ? 'Present — reveal only when trusted' : 'Not provided',
      },
      format: format,
    );
  }

  static Map<String, String> _parseEscapedFields(String body) {
    final result = <String, String>{};
    final buffer = StringBuffer();
    final fields = <String>[];
    var escaped = false;
    for (final rune in body.runes) {
      final char = String.fromCharCode(rune);
      if (escaped) {
        buffer.write(char);
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == ';') {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) fields.add(buffer.toString());
    for (final field in fields) {
      final index = field.indexOf(':');
      if (index > 0) result[field.substring(0, index)] = field.substring(index + 1);
    }
    return result;
  }

  static Map<String, String> _vcard(String value) {
    final lines = _lines(value);
    return {
      'Name': lines['FN'] ?? lines['N'] ?? '',
      'Phone': lines['TEL'] ?? '',
      'Email': lines['EMAIL'] ?? '',
      'Organization': lines['ORG'] ?? '',
      'Website': lines['URL'] ?? '',
    };
  }

  static Map<String, String> _mecard(String value) {
    final body = value.substring(value.indexOf(':') + 1);
    final fields = _parseEscapedFields(body);
    return {
      'Name': fields['N'] ?? '',
      'Phone': fields['TEL'] ?? '',
      'Email': fields['EMAIL'] ?? '',
      'Address': fields['ADR'] ?? '',
      'Website': fields['URL'] ?? '',
    };
  }

  static Map<String, String> _lines(String value) {
    final map = <String, String>{};
    for (final line in const LineSplitter().convert(value)) {
      final index = line.indexOf(':');
      if (index > 0) {
        map[line.substring(0, index).split(';').first.toUpperCase()] = line.substring(index + 1);
      }
    }
    return map;
  }

  static String _emailSummary(String value) {
    final uri = Uri.tryParse(value);
    return uri?.path.isNotEmpty == true ? uri!.path : value;
  }

  static String? _matmsgToMailto(String value) {
    final fields = _parseEscapedFields(value.substring(value.indexOf(':') + 1));
    final recipient = fields['TO'];
    if (recipient == null || recipient.isEmpty) return null;
    return Uri(
      scheme: 'mailto',
      path: recipient,
      queryParameters: {
        if ((fields['SUB'] ?? '').isNotEmpty) 'subject': fields['SUB']!,
        if ((fields['BODY'] ?? '').isNotEmpty) 'body': fields['BODY']!,
      },
    ).toString();
  }

  static bool _looksLikeJson(String value) {
    if (!((value.startsWith('{') && value.endsWith('}')) ||
        (value.startsWith('[') && value.endsWith(']')))) {
      return false;
    }
    try {
      jsonDecode(value);
      return true;
    } catch (_) {
      return false;
    }
  }
}
