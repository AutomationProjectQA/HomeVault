import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/main.dart';

void main() {
  testWidgets('app boots to dashboard with quick-add available', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeVaultApp()));
    await tester.pumpAndSettle();

    expect(find.text('My Home'), findsOneWidget);
    expect(find.text("Today's tasks"), findsOneWidget);

    // Quick-add sheet opens from the empty-state CTA.
    await tester.tap(find.text('Add your first appliance'));
    await tester.pumpAndSettle();
    expect(find.text('Add to your home'), findsOneWidget);
    expect(find.text('Bill'), findsOneWidget);
  });
}
