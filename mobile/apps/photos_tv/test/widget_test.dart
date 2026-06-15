import 'package:flutter_test/flutter_test.dart';
import 'package:photos_tv/main.dart';

void main() {
  testWidgets('shows pairing instructions', (tester) async {
    await tester.pumpWidget(const PhotosTvApp());
    expect(
      find.text('Enter this code on Ente Photos to pair this screen'),
      findsOneWidget,
    );
  });
}
