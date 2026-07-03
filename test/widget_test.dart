import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keuangan_v1/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KeuanganApp(),
      ),
    );

    // Verify that the main app is successfully rendered
    expect(find.byType(KeuanganApp), findsOneWidget);
  });
}
