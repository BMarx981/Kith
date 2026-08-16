import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/main.dart' as entrypoint;

void main() {
  testWidgets('main mounts KithApp inside a ProviderScope', (tester) async {
    entrypoint.main();
    await tester.pumpAndSettle();

    expect(find.byType(KithApp), findsOneWidget);
  });
}
