import 'package:flutter_test/flutter_test.dart';

import 'package:project1/main.dart';

void main() {
  testWidgets('Splash screen shows ReLoop branding', (WidgetTester tester) async {
    await tester.pumpWidget(const ReLoopApp());

    expect(find.text('ReLoop'), findsWidgets);
    expect(find.text('SWAP'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
  });

  testWidgets('Splash routes to the Welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ReLoopApp());

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Give Pre-Loved\nGoods a Second Story.'), findsOneWidget);
  });
}