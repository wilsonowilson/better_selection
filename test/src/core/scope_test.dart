import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:super_selection/super_selection.dart';

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
