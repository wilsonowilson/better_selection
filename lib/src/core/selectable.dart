import 'package:flutter/material.dart';
import 'package:super_selection/src/core/scope.dart';

import 'package:super_selection/src/core/selection.dart';

/// Details used to identify a [SelectableWidget].
class Selectable {
  const Selectable({
    required this.key,
  });
  final GlobalKey<SelectableWidgetState> key;
}

abstract class SelectableWidget extends StatefulWidget {
  const SelectableWidget({
    required GlobalKey<SelectableWidgetState> key,
  }) : super(key: key);

  @override
  SelectableWidgetState createState();
}

abstract class SelectableWidgetState<T extends SelectableWidget>
    extends State<T> {
  /// The selection of the selectable.
  SelectableSelection get selection;

  Selectable get details => Selectable(
        key: widget.key! as GlobalKey<SelectableWidgetState>,
      );

  SelectableSelection getVoidSelection();

  SelectableSelection getExpandedSelection();

  /// Get the [SelectablePosition] of the [SelectableSelectable] at a localPosition.
  SelectablePosition getPositionAtOffset(Offset localOffset);

  /// Get the starting position of the [SelectableSelectable], for example,
  /// the start of a text selectable.
  SelectablePosition getBasePosition();

  /// Get the ending position of the [SelectableSelectable], for example,
  /// the end of a text selectable.
  SelectablePosition getExtentPosition();

  SelectableSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  );

  /// Convert the selection into copyable text.
  String? serializeSelection(SelectableSelection selection);

  MouseCursor? getCursorAtOffset(Offset localOffset);

  /// Update the selection of the [SelectableSelectable].
  void updateSelection(SelectableSelection selection);
}

/// Registers [SelectableSelectable]s with the [SelectableScope]. It also
/// uses the key provided by the [details].
///
/// To use this, wrap the widget in the build method of your [SelectableSelectable]
/// in a [SelectableRegistrar]. Ex.
///
/// ```dart
///   ...
///   @override
///   Widget build(BuildContext context) {
///     return SelectableSelectableRegistrar(
///        details: details,
///        child: Image(...),
///     );
///  }
/// ```
class SelectableRegistrar extends StatefulWidget {
  const SelectableRegistrar({
    Key? key,
    required this.child,
    required this.details,
  }) : super(key: key);

  final Selectable details;
  final Widget child;
  @override
  _SelectableRegistrarState createState() => _SelectableRegistrarState();
}

class _SelectableRegistrarState extends State<SelectableRegistrar> {
  late final SelectableScopeState _scope;
  @override
  void initState() {
    super.initState();
    _scope = SelectableScope.of(context);
    _registerSelectable(widget.details);
  }

  @override
  void dispose() {
    _unregisterSelectable(widget.details);
    super.dispose();
  }

  @override
  void didUpdateWidget(SelectableRegistrar oldWidget) {
    if (oldWidget.details != widget.details) {
      _unregisterSelectable(oldWidget.details);
      _registerSelectable(widget.details);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _registerSelectable(Selectable details) {
    _scope.registerSelectable(details);
  }

  void _unregisterSelectable(Selectable details) {
    _scope.unregisterSelectable(details);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
