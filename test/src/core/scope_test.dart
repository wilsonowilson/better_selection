import 'package:better_selection/better_selection.dart';
import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectableScope', () {
    testWidgets('of(context) fails when there is no SelectableScope parent',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TextSelectable(
            textSpan: const TextSpan(
              text: 'Hello world!',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isFlutterError);
    });
  });
}
