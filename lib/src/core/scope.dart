import 'package:flutter/material.dart';
import 'package:super_selection/src/core/element.dart';

class SelectableScope extends StatefulWidget {
  const SelectableScope({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  SelectableScopeState createState() => SelectableScopeState();

  static SelectableScopeState of(BuildContext context) {
    assert(debugCheckHasSelectableScope(context));
    return context.findAncestorStateOfType<SelectableScopeState>()!;
  }

  static bool debugCheckHasSelectableScope(BuildContext context) {
    final state = context.findAncestorStateOfType<SelectableScopeState>();
    if (state == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No SelectableScope widget ancestor found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a SelectableScope widget ancestor.',
        ),
        context.describeWidget(
          'The specific widget that could not find a SelectableScope ancestor was',
        ),
        context.describeOwnershipChain(
          'The ownership chain for the affected widget is',
        ),
        ErrorHint(
          'No SelectableScope ancestor could be found starting from the context '
          'that was passed to SelectableScope.of(). This can happen because you '
          'have not added a SelectableScope widget. s',
        ),
      ]);
    }
    return true;
  }
}

class SelectableScopeState extends State<SelectableScope> {
  @visibleForTesting
  final registeredElements = <SelectableElementDetails>{};

  void registerElement(SelectableElementDetails details) {
    registeredElements.add(details);
  }

  void unregisterElement(SelectableElementDetails details) {
    registeredElements.remove(details);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
