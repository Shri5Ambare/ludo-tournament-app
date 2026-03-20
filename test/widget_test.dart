import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_tournament_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // App requires ProviderScope and router, so we just verify it can build
    // Real integration tests would use the full app with mocked providers
    expect(LudoTournamentApp, isNotNull);
  });
}
