import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import 'package:super_selection/src/core/element.dart';
import 'package:super_selection/src/core/selection.dart';
import 'package:super_selection/src/core/text.dart';

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

class SelectableTextElement extends SelectableElementWidget {
  SelectableTextElement({
    GlobalKey<SelectableElementWidgetState>? key,
    required this.textSpan,
  }) : super(key: key ?? GlobalKey<SelectableElementWidgetState>());

  final TextSpan textSpan;

  @override
  _SelectableTextElementState createState() => _SelectableTextElementState();
}

class _SelectableTextElementState
    extends SelectableElementWidgetState<SelectableTextElement>
    implements TextElement {
  final _selectableTextKey = GlobalKey<SuperSelectableTextState>();

  TextElementSelection _selection =
      const TextElementSelection.collapsed(offset: -1);

  @override
  TextElementSelection get selection => _selection;

  @override
  void updateSelection(ElementSelection selection) {
    if (selection is! TextElementSelection) {
      throw Exception(
        'Expected selection of type TextElementSelection but got $selection',
      );
    }

    setState(() {
      _selection = selection;
    });
  }

  @override
  TextElementPosition getBasePosition() {
    return const TextElementPosition(offset: 0);
  }

  @override
  TextElementPosition getExtentPosition() {
    return TextElementPosition(offset: _rawText.length);
  }

  @override
  TextElementPosition getPositionAtOffset(Offset localOffset) {
    final position =
        _selectableTextKey.currentState!.getPositionAtOffset(localOffset);
    return TextElementPosition.fromTextPosition(position);
  }

  @override
  TextElementSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  ) {
    final selection = _selectableTextKey.currentState!.getSelectionInRect(
      localBaseOffset,
      localExtentOffset,
    );

    return TextElementSelection.fromTextSelection(selection);
  }

  @override
  String serializeSelection(ElementSelection selection) {
    return _rawText;
  }

  String get _rawText => widget.textSpan.toPlainText();

  @override
  TextElementPosition? getPositionOneLineUp(TextElementPosition textPosition) {
    final positionOneLineUp =
        _selectableTextKey.currentState!.getPositionOneLineUp(textPosition);
    if (positionOneLineUp == null) {
      return null;
    }
    return TextElementPosition.fromTextPosition(positionOneLineUp);
  }

  @override
  TextElementPosition? getPositionOneLineDown(
    TextElementPosition textPosition,
  ) {
    final positionOneLineDown =
        _selectableTextKey.currentState!.getPositionOneLineDown(textPosition);
    if (positionOneLineDown == null) {
      return null;
    }
    return TextElementPosition.fromTextPosition(positionOneLineDown);
  }

  @override
  TextElementPosition getPositionAtEndOfLine(TextElementPosition textPosition) {
    return TextElementPosition.fromTextPosition(
      _selectableTextKey.currentState!.getPositionAtEndOfLine(textPosition),
    );
  }

  @override
  TextElementPosition getPositionAtStartOfLine(
    TextElementPosition textElementPosition,
  ) {
    return TextElementPosition.fromTextPosition(
      _selectableTextKey.currentState!
          .getPositionAtStartOfLine(textElementPosition),
    );
  }

  @override
  TextElementSelection getWordSelectionAt(
    TextElementPosition textElementPosition,
  ) {
    return TextElementSelection.fromTextSelection(
      _selectableTextKey.currentState!.getWordSelectionAt(textElementPosition),
    );
  }

  @override
  TextElementSelection getParagraphSelectionAt(
    TextElementPosition textElementPosition,
  ) {
    final selection = expandPositionToParagraph(
      text: getContiguousTextAt(textElementPosition),
      textPosition: textElementPosition,
    );
    return TextElementSelection.fromTextSelection(selection);
  }

  @override
  TextElementSelection getVoidSelection() {
    return const TextElementSelection.collapsed(offset: -1);
  }

  @override
  String getContiguousTextAt(TextElementPosition textPosition) {
    // TODO: Split by \n
    return _rawText;
  }

  @override
  Widget build(BuildContext context) {
    return SelectableElementRegistrar(
      details: details,
      child: SuperSelectableText(
        key: _selectableTextKey,
        textSpan: widget.textSpan,
        textSelection: _selection,
      ),
    );
  }
}
