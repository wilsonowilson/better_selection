import 'package:flutter/material.dart';
import 'package:super_selection/src/core/selection.dart';

class TextElementPosition extends TextPosition implements ElementPosition {
  const TextElementPosition({
    required int offset,
    TextAffinity affinity = TextAffinity.downstream,
  }) : super(offset: offset, affinity: affinity);

  TextElementPosition.fromTextPosition(TextPosition position)
      : super(offset: position.offset, affinity: position.affinity);
}

class TextElementSelection extends TextSelection implements ElementSelection {
  const TextElementSelection({
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

  const TextElementSelection.collapsed({
    required int offset,
    TextAffinity affinity = TextAffinity.downstream,
  }) : super(
          baseOffset: offset,
          extentOffset: offset,
          affinity: affinity,
        );

  TextElementSelection.fromTextSelection(TextSelection textSelection)
      : super(
          baseOffset: textSelection.baseOffset,
          extentOffset: textSelection.extentOffset,
          affinity: textSelection.affinity,
          isDirectional: textSelection.isDirectional,
        );

  @override
  TextElementPosition get base => TextElementPosition(offset: baseOffset);

  @override
  TextElementPosition get extent => TextElementPosition(offset: extentOffset);
}

abstract class TextElement {
  TextElementSelection getWordSelectionAt(
    TextElementPosition textElementPosition,
  );
  TextElementSelection getParagraphSelectionAt(
    TextElementPosition textElementPosition,
  );

  TextElementPosition? getPositionOneLineUp(
    TextElementPosition textElementPosition,
  );
  TextElementPosition? getPositionOneLineDown(
    TextElementPosition textElementPosition,
  );
  TextElementPosition getPositionAtStartOfLine(
    TextElementPosition textElementPosition,
  );
  TextElementPosition getPositionAtEndOfLine(
    TextElementPosition textElementPosition,
  );

  String getContiguousTextAt(TextElementPosition textPosition);
}
