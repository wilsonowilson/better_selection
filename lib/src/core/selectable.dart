import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_selection/src/core/scope.dart';

import 'package:super_selection/src/core/selection.dart';

/// Details used to identify a [SelectableWidget].
class Selectable {
  const Selectable({
    required this.key,
    this.parentScrollable,
  });
  final GlobalKey<SelectableWidgetState> key;
  final ScrollableState? parentScrollable;
}

abstract class SelectableWidget extends StatefulWidget {
  const SelectableWidget({
    required GlobalKey<SelectableWidgetState> key,
  }) : super(key: key);

  @override
  SelectableWidgetState createState();
}

abstract class SelectableWidgetState<T extends SelectableWidget>
    extends State<T> with AutomaticKeepAliveClientMixin {
  /// The selection of the selectable.
  SelectableSelection get selection;

  Selectable get details {
    final scrollable = Scrollable.of(context);
    return Selectable(
      key: widget.key! as GlobalKey<SelectableWidgetState>,
      parentScrollable: scrollable,
    );
  }

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

  Widget buildContent(BuildContext context);

  @override
  bool get wantKeepAlive => true;

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _SelectableRegistrar(
      details: details,
      child: buildContent(context),
    );
  }
}

/// Registers [SelectableSelectable]s with the [SelectableScope]. It also
/// uses the key provided by the [details].
///
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
class _SelectableRegistrar extends StatefulWidget {
  const _SelectableRegistrar({
    Key? key,
    required this.child,
    required this.details,
  }) : super(key: key);

  final Selectable details;
  final Widget child;
  @override
  _SelectableRegistrarState createState() => _SelectableRegistrarState();
}

class _SelectableRegistrarState extends State<_SelectableRegistrar> {
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
  void didUpdateWidget(_SelectableRegistrar oldWidget) {
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
