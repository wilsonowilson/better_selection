import 'package:flutter/material.dart';

import 'package:super_selection/src/core/element.dart';
import 'package:super_selection/src/core/selection.dart';

class BinaryElementPosition extends ElementPosition {
  const BinaryElementPosition.included() : included = true;
  const BinaryElementPosition.excluded() : included = false;
  final bool included;
}

class BinaryElementSelection extends ElementSelection {
  const BinaryElementSelection.all()
      : position = const BinaryElementPosition.included();

  const BinaryElementSelection.none()
      : position = const BinaryElementPosition.excluded();

  final BinaryElementPosition position;
}

class BoxElement extends SelectableElementWidget {
  BoxElement({
    GlobalKey<SelectableElementWidgetState>? key,
    this.text = '',
    required this.child,
  }) : super(key: key ?? GlobalKey<SelectableElementWidgetState>());

  final String text;
  final Widget child;

  @override
  _BinaryElementState createState() => _BinaryElementState();
}

class _BinaryElementState extends SelectableElementWidgetState<BoxElement> {
  BinaryElementSelection _selection = const BinaryElementSelection.none();

  @override
  ElementPosition getBasePosition() {
    return const BinaryElementPosition.excluded();
  }

  @override
  MouseCursor? getCursorAtOffset(Offset localOffset) {}

  @override
  ElementSelection getExpandedSelection() {
    return const BinaryElementSelection.all();
  }

  @override
  ElementPosition getExtentPosition() {
    return const BinaryElementPosition.included();
  }

  @override
  ElementPosition getPositionAtOffset(Offset localOffset) {
    return const BinaryElementPosition.included();
  }

  @override
  ElementSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return const BinaryElementSelection.none();

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
      return const BinaryElementSelection.all();
    } else if (intersection.height >= size.height) {
      return const BinaryElementSelection.all();
    }
  }

  @override
  ElementSelection getVoidSelection() {
    return const BinaryElementSelection.none();
  }

  @override
  ElementSelection get selection => _selection;

  @override
  String? serializeSelection(ElementSelection selection) {
    if (selection is! BinaryElementSelection) return null;
    if (!selection.position.included) return null;

    return widget.text;
  }

  @override
  void updateSelection(ElementSelection selection) {
    if (selection is! BinaryElementSelection) return;

    setState(() {
      _selection = selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SelectableElementRegistrar(
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
