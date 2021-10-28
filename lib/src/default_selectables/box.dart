import 'package:flutter/material.dart';

import 'package:super_selection/src/core/selectable.dart';
import 'package:super_selection/src/core/selection.dart';

class BinarySelectablePosition extends SelectablePosition {
  const BinarySelectablePosition.included() : included = true;
  const BinarySelectablePosition.excluded() : included = false;
  final bool included;
}

class BinarySelectableSelection extends SelectableSelection {
  const BinarySelectableSelection.all()
      : position = const BinarySelectablePosition.included();

  const BinarySelectableSelection.none()
      : position = const BinarySelectablePosition.excluded();

  final BinarySelectablePosition position;
}

class BoxSelectable extends SelectableWidget {
  BoxSelectable({
    GlobalKey<SelectableWidgetState>? key,
    this.text = '',
    required this.child,
  }) : super(key: key ?? GlobalKey<SelectableWidgetState>());

  final String text;
  final Widget child;

  @override
  _BinarySelectableState createState() => _BinarySelectableState();
}

class _BinarySelectableState extends SelectableWidgetState<BoxSelectable> {
  BinarySelectableSelection _selection = const BinarySelectableSelection.none();

  @override
  SelectablePosition getBasePosition() {
    return const BinarySelectablePosition.excluded();
  }

  @override
  MouseCursor? getCursorAtOffset(Offset localOffset) {}

  @override
  SelectableSelection getExpandedSelection() {
    return const BinarySelectableSelection.all();
  }

  @override
  SelectablePosition getExtentPosition() {
    return const BinarySelectablePosition.included();
  }

  @override
  SelectablePosition getPositionAtOffset(Offset localOffset) {
    return const BinarySelectablePosition.included();
  }

  @override
  SelectableSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return const BinarySelectableSelection.none();

    final size = box.size;
    final boxRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final selectionRect = Rect.fromPoints(localBaseOffset, localExtentOffset);

    final intersection = selectionRect.intersect(
      boxRect,
    );

    if (intersection.height.isNegative) {
      return null;
    }

    // Not selected at all
    if (intersection.width.isNegative && intersection.height.isNegative) {
      return null;
    }

    if (!intersection.width.isNegative && !intersection.height.isNegative) {
      return const BinarySelectableSelection.all();
    } else if (intersection.height >= size.height) {
      return const BinarySelectableSelection.all();
    }
  }

  @override
  SelectableSelection getVoidSelection() {
    return const BinarySelectableSelection.none();
  }

  @override
  SelectableSelection get selection => _selection;

  @override
  String? serializeSelection(SelectableSelection selection) {
    if (selection is! BinarySelectableSelection) return null;
    if (!selection.position.included) return null;

    return widget.text;
  }

  @override
  void updateSelection(SelectableSelection selection) {
    if (selection is! BinarySelectableSelection) return;

    setState(() {
      _selection = selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SelectableRegistrar(
      details: details,
      child: Container(
        foregroundDecoration: BoxDecoration(
          color: _selection.position.included
              ? Colors.blue.withOpacity(0.3)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
