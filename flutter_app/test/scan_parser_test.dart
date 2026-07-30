import 'package:flutter_test/flutter_test.dart';
import 'package:private_safe_qr/core/models/scan_models.dart';
import 'package:private_safe_qr/core/parsing/scan_parser.dart';

void main() {
  test('parses HTTPS URL', () {
    final result = ScanParser.parse('https://example.com/path');
    expect(result.type, ScanContentType.url);
    expect(result.details['Domain'], 'example.com');
  });

  test('parses UPI details', () {
    final result = ScanParser.parse('upi://pay?pa=test@upi&pn=Shop&am=10&cu=INR');
    expect(result.type, ScanContentType.upi);
    expect(result.details['UPI ID'], 'test@upi');
    expect(result.details['Amount'], '10');
  });

  test('parses Wi-Fi QR', () {
    final result = ScanParser.parse('WIFI:T:WPA;S:Office;P:secret;;');
    expect(result.type, ScanContentType.wifi);
    expect(result.details['Network'], 'Office');
  });


  test('parses Android app deep link', () {
    final result = ScanParser.parse('whatsapp://send?phone=919999999999');
    expect(result.type, ScanContentType.appLink);
    expect(result.actionUri, isNotNull);
  });

  test('parses provider payment URI as UPI action', () {
    final result = ScanParser.parse('phonepe://pay?pa=test@upi&pn=Shop&am=25');
    expect(result.type, ScanContentType.upi);
    expect(result.details['UPI ID'], 'test@upi');
  });
}
