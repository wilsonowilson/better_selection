import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:super_selection/super_selection.dart';

void main() {
  group('SelectableRegistrar', () {
    testWidgets('Registers Selectables properly', (tester) async {
      final widget = MaterialApp(
        home: SelectableScope(
          child: Column(
            children: [
              TextSelectable(
                textSpan: const TextSpan(
                  text: 'Hello world!',
                ),
              ),
              TextSelectable(
                textSpan: const TextSpan(
                  text: 'Hello world!',
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(widget);

      final state = tester.firstState<SelectableScopeState>(
        find.byType(SelectableScope),
      );
      expect(state.registeredSelectables.length, equals(2));
    });
    testWidgets('Unregisters Selectables Properly', (tester) async {
      final notifier = ValueNotifier<bool>(false);
      final widget = MaterialApp(
        home: SelectableScope(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: notifier,
                builder: (context, hideWidget, _) {
                  if (hideWidget) return const SizedBox();
                  return TextSelectable(
                    textSpan: const TextSpan(
                      text: 'Hello world!',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(widget);

      final state = tester.firstState<SelectableScopeState>(
        find.byType(SelectableScope),
      );
      expect(state.registeredSelectables.length, equals(1));

      notifier.value = true;
      await tester.pump();

      expect(state.registeredSelectables.length, equals(0));

      notifier.value = false;
      await tester.pump();

      expect(state.registeredSelectables.length, equals(1));
    });
  });
}
