import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dopamine_assets/app.dart';

void main() {
  testWidgets('DopamineApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      DopamineApp(navigatorKey: GlobalKey<NavigatorState>()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
