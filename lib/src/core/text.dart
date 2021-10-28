import 'package:flutter/material.dart';
import 'package:better_selection/src/core/selection.dart';

class TextSelectablePosition extends TextPosition
    implements SelectablePosition {
  const TextSelectablePosition({
    required int offset,
    TextAffinity affinity = TextAffinity.downstream,
  }) : super(offset: offset, affinity: affinity);

  TextSelectablePosition.fromTextPosition(TextPosition position)
      : super(offset: position.offset, affinity: position.affinity);
}

class TextSelectableSelection extends TextSelection
    implements SelectableSelection {
  const TextSelectableSelection({
    required int baseOffset,
    required int extentOffset,
    TextAffinity affinity = TextAffinity.downstream,
    bool isDirectional = false,
  }) : super(
          baseOffset: baseOffset,
          extentOffset: extentOffset,
          affinity: affinity,
          isDirectional: isDirectional,
        );

  const TextSelectableSelection.collapsed({
    required int offset,
    TextAffinity affinity = TextAffinity.downstream,
  }) : super(
          baseOffset: offset,
          extentOffset: offset,
          affinity: affinity,
        );

  TextSelectableSelection.fromTextSelection(TextSelection textSelection)
      : super(
          baseOffset: textSelection.baseOffset,
          extentOffset: textSelection.extentOffset,
          affinity: textSelection.affinity,
          isDirectional: textSelection.isDirectional,
        );

  @override
  TextSelectablePosition get base => TextSelectablePosition(offset: baseOffset);

  @override
  TextSelectablePosition get extent =>
      TextSelectablePosition(offset: extentOffset);
}

abstract class TextSelectableWidgetState {
  TextSelectableSelection getWordSelectionAt(
    TextSelectablePosition textSelectablePosition,
  );
  TextSelectableSelection getParagraphSelectionAt(
    TextSelectablePosition textSelectablePosition,
  );

  TextSelectablePosition? getPositionOneLineUp(
    TextSelectablePosition textSelectablePosition,
  );
  TextSelectablePosition? getPositionOneLineDown(
    TextSelectablePosition textSelectablePosition,
  );
  TextSelectablePosition getPositionAtStartOfLine(
    TextSelectablePosition textSelectablePosition,
  );
  TextSelectablePosition getPositionAtEndOfLine(
    TextSelectablePosition textSelectablePosition,
  );

  String getContiguousTextAt(TextSelectablePosition textPosition);
}
