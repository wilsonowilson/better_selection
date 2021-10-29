import 'package:better_selection/src/core/selectable.dart';
import 'package:better_selection/src/core/selection.dart';
import 'package:flutter/material.dart';

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
    this.selectableDecoration,
  }) : super(key: key ?? GlobalKey<SelectableWidgetState>());

  final String text;
  final Widget child;
  final BoxSelectableDecoration? selectableDecoration;

  @override
  _BoxSelectableState createState() => _BoxSelectableState();
}

class _BoxSelectableState extends SelectableWidgetState<BoxSelectable> {
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
  Widget buildContent(BuildContext context) {
    final selectionTheme = Theme.of(context).textSelectionTheme;
    final decoration = widget.selectableDecoration ??
        BoxSelectableDecoration(
          color: selectionTheme.selectionColor ?? Colors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        );
    return Container(
      foregroundDecoration: _selection.position.included
          ? BoxDecoration(
              color: decoration.color,
              borderRadius: decoration.borderRadius,
            )
          : null,
      child: widget.child,
    );
  }
}

class BoxSelectableDecoration {
  const BoxSelectableDecoration({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final BorderRadius borderRadius;
}
