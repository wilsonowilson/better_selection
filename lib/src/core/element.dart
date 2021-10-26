import 'package:flutter/material.dart';
import 'package:super_selection/src/core/scope.dart';

import 'package:super_selection/src/core/selection.dart';

/// Details used to identify a [SelectableElement].
class SelectableElementDetails {
  const SelectableElementDetails({
    required this.key,
  });
  final GlobalKey<SelectableElementWidgetState> key;
}

abstract class SelectableElementWidget extends StatefulWidget {
  const SelectableElementWidget({
    required GlobalKey<SelectableElementWidgetState> key,
  }) : super(key: key);

  @override
  SelectableElementWidgetState createState();
}

abstract class SelectableElementWidgetState<T extends SelectableElementWidget>
    extends State<T> {
  /// The selection of the element.
  ElementSelection get selection;

  SelectableElementDetails get details => SelectableElementDetails(
        key: widget.key! as GlobalKey<SelectableElementWidgetState>,
      );

  ElementSelection getVoidSelection();

  ElementSelection getExpandedSelection();

  /// Get the [ElementPosition] of the [SelectableElement] at a localPosition.
  ElementPosition getPositionAtOffset(Offset localOffset);

  /// Get the starting position of the [SelectableElement], for example,
  /// the start of a text element.
  ElementPosition getBasePosition();

  /// Get the ending position of the [SelectableElement], for example,
  /// the end of a text element.
  ElementPosition getExtentPosition();

  ElementSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  );

  /// Convert the selection into copyable text.
  String? serializeSelection(ElementSelection selection);

  MouseCursor? getCursorAtOffset(Offset localOffset);

  /// Update the selection of the [SelectableElement].
  void updateSelection(ElementSelection selection);
}

/// Registers [SelectableElement]s with the [SelectableScope]. It also
/// uses the key provided by the [details].
///
/// To use this, wrap the widget in the build method of your [SelectableElement]
/// in a [SelectableElementRegistrar]. Ex.
///
/// ```dart
///   ...
///   @override
///   Widget build(BuildContext context) {
///     return SelectableElementRegistrar(
///        details: details,
///        child: Image(...),
///     );
///  }
/// ```
class SelectableElementRegistrar extends StatefulWidget {
  const SelectableElementRegistrar({
    Key? key,
    required this.child,
    required this.details,
  }) : super(key: key);

  final SelectableElementDetails details;
  final Widget child;
  @override
  _SelectableElementRegistrarState createState() =>
      _SelectableElementRegistrarState();
}

class _SelectableElementRegistrarState
    extends State<SelectableElementRegistrar> {
  late final SelectableScopeState _scope;
  @override
  void initState() {
    super.initState();
    _scope = SelectableScope.of(context);
    _registerElement(widget.details);
  }

  @override
  void dispose() {
    _unregisterElement(widget.details);
    super.dispose();
  }

  @override
  void didUpdateWidget(SelectableElementRegistrar oldWidget) {
    if (oldWidget.details != widget.details) {
      _unregisterElement(oldWidget.details);
      _registerElement(widget.details);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _registerElement(SelectableElementDetails details) {
    _scope.registerElement(details);
  }

  void _unregisterElement(SelectableElementDetails details) {
    _scope.unregisterElement(details);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
