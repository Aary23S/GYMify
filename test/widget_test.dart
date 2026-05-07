import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/app.dart';
import 'package:gymflow/core/widgets/gym_logo_widget.dart';

void main() {
  testWidgets('App starts with Splash Screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GymFlowApp(),
      ),
    );

    // Verify that the Splash Screen is shown.
    expect(find.text('GymFlow'), findsOneWidget);
    expect(find.text('Manage Your Gym Smarter'), findsOneWidget);
    expect(find.byType(GymLogoWidget), findsOneWidget);

    // Advance time to trigger the navigation timer in SplashScreen
    await tester.pump(const Duration(seconds: 3));

    // We don't use pumpAndSettle() because of the infinite animation in LinearProgressIndicator
    // which would cause a timeout.
  });
}
