import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:private_safe_qr/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('application shell renders', (tester) async {
    await tester.pumpWidget(const PrivateSafeQrApp());
    await tester.pumpAndSettle();
    expect(find.text('QR AJN'), findsOneWidget);
  });
}
