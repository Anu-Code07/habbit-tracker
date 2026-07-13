import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulse/core/di/injection.dart';
import 'package:pulse/features/splash/presentation/pages/splash_page.dart';
import 'package:pulse/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('PulseApp builds splash', (tester) async {
    await tester.pumpWidget(const PulseApp());
    await tester.pump();
    expect(find.byType(PulseApp), findsOneWidget);
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
