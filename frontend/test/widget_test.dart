import 'package:flutter_test/flutter_test.dart';

import 'package:chamada_app/main.dart';

void main() {
  testWidgets('App bar title', (WidgetTester tester) async {
    await tester.pumpWidget(const ChamadaApp());
    expect(find.text('Chamada'), findsWidgets);
  });
}
