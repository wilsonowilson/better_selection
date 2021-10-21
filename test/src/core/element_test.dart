import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_selection/super_selection.dart';

void main() {
  group('SelectableElementRegistrar', () {
    testWidgets('Registers SelectableElements properly', (tester) async {
      final widget = MaterialApp(
        home: SelectableScope(
          child: Column(
            children: [
              SelectableTextElement(
                textSpan: const TextSpan(
                  text: 'Hello world!',
                ),
              ),
              SelectableTextElement(
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
      expect(state.registeredElements.length, equals(2));
    });
    testWidgets('Unregisters Selectable Elements Properly', (tester) async {
      final notifier = ValueNotifier<bool>(false);
      final widget = MaterialApp(
        home: SelectableScope(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: notifier,
                builder: (context, hideWidget, _) {
                  if (hideWidget) return const SizedBox();
                  return SelectableTextElement(
                    key: GlobalKey(),
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
      expect(state.registeredElements.length, equals(1));

      notifier.value = true;
      await tester.pump();

      expect(state.registeredElements.length, equals(0));

      notifier.value = false;
      await tester.pump();

      expect(state.registeredElements.length, equals(1));
    });
  });
}
