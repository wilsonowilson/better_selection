import 'package:better_selection/src/core/selectable.dart';
import 'package:better_selection/src/core/selection.dart';
import 'package:better_selection/src/core/text.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class TextSelectable extends SelectableWidget {
  TextSelectable({
    GlobalKey<SelectableWidgetState>? key,
    required this.textSpan,
    this.selectableDecoration,
  }) : super(key: key ?? GlobalKey<SelectableWidgetState>());

  TextSelectable.plain(
    String text, {
    TextStyle? style,
    GlobalKey<SelectableWidgetState>? key,
    this.selectableDecoration,
  })  : textSpan = TextSpan(
          text: text,
          style: style,
        ),
        super(key: key ?? GlobalKey<SelectableWidgetState>());

  final TextSpan textSpan;
  final TextSelectableDecoration? selectableDecoration;

  @override
  _TextSelectableState createState() => _TextSelectableState();
}

class _TextSelectableState extends SelectableWidgetState<TextSelectable>
    implements TextSelectableWidgetState {
  final _selectableTextKey = GlobalKey<SuperSelectableTextState>();

  TextSelectableSelection _selection =
      const TextSelectableSelection.collapsed(offset: -1);

  @override
  TextSelectableSelection get selection => _selection;

  @override
  void updateSelection(SelectableSelection selection) {
    if (selection is! TextSelectableSelection) {
      throw Exception(
        'Expected selection of type TextSelectableSelection but got $selection',
      );
    }

    if (selection == _selection) return;

    setState(() {
      _selection = selection;
    });
  }

  @override
  TextSelectablePosition getBasePosition() {
    return const TextSelectablePosition(offset: 0);
  }

  @override
  TextSelectablePosition getExtentPosition() {
    return TextSelectablePosition(offset: _rawText.length);
  }

  @override
  TextSelectablePosition getPositionAtOffset(Offset localOffset) {
    final position =
        _selectableTextKey.currentState!.getPositionAtOffset(localOffset);
    return TextSelectablePosition.fromTextPosition(position);
  }

  @override
  TextSelectableSelection? getSelectionInRange(
    Offset localBaseOffset,
    Offset localExtentOffset,
  ) {
    // This selection is never null because it is resolved to offset = 0 if
    // the rect is above the widget and offset = text.length if the rect
    // is below.
    final selection = _selectableTextKey.currentState!.getSelectionInRect(
      localBaseOffset,
      localExtentOffset,
    );

    if (selection.isCollapsed) return null;

    return TextSelectableSelection.fromTextSelection(selection);
  }

  @override
  String? serializeSelection(SelectableSelection selection) {
    if (selection is! TextSelectableSelection) return null;
    if (selection.isValid) {
      return selection.textInside(_rawText);
    }
  }

  String get _rawText => widget.textSpan.toPlainText();

  @override
  TextSelectablePosition? getPositionOneLineUp(
    TextSelectablePosition textPosition,
  ) {
    final positionOneLineUp =
        _selectableTextKey.currentState!.getPositionOneLineUp(textPosition);
    if (positionOneLineUp == null) {
      return null;
    }
    return TextSelectablePosition.fromTextPosition(positionOneLineUp);
  }

  @override
  TextSelectablePosition? getPositionOneLineDown(
    TextSelectablePosition textPosition,
  ) {
    final positionOneLineDown =
        _selectableTextKey.currentState!.getPositionOneLineDown(textPosition);
    if (positionOneLineDown == null) {
      return null;
    }
    return TextSelectablePosition.fromTextPosition(positionOneLineDown);
  }

  @override
  TextSelectablePosition getPositionAtEndOfLine(
    TextSelectablePosition textPosition,
  ) {
    return TextSelectablePosition.fromTextPosition(
      _selectableTextKey.currentState!.getPositionAtEndOfLine(textPosition),
    );
  }

  @override
  TextSelectablePosition getPositionAtStartOfLine(
    TextSelectablePosition textSelectablePosition,
  ) {
    return TextSelectablePosition.fromTextPosition(
      _selectableTextKey.currentState!
          .getPositionAtStartOfLine(textSelectablePosition),
    );
  }

  @override
  TextSelectableSelection getWordSelectionAt(
    TextSelectablePosition textSelectablePosition,
  ) {
    return TextSelectableSelection.fromTextSelection(
      _selectableTextKey.currentState!
          .getWordSelectionAt(textSelectablePosition),
    );
  }

  @override
  TextSelectableSelection getParagraphSelectionAt(
    TextSelectablePosition textSelectablePosition,
  ) {
    final selection = expandPositionToParagraph(
      text: getContiguousTextAt(textSelectablePosition),
      textPosition: textSelectablePosition,
    );
    return TextSelectableSelection.fromTextSelection(selection);
  }

  @override
  TextSelectableSelection getVoidSelection() {
    return const TextSelectableSelection.collapsed(offset: -1);
  }

  @override
  TextSelectableSelection getExpandedSelection() {
    return TextSelectableSelection(
      baseOffset: 0,
      extentOffset: _rawText.length,
    );
  }

  @override
  String getContiguousTextAt(TextSelectablePosition textPosition) {
    // TODO: Split by \n
    return _rawText;
  }

  @override
  Widget buildContent(BuildContext context) {
    final selectionTheme = Theme.of(context).textSelectionTheme;
    final selectionDecoration = widget.selectableDecoration ??
        TextSelectableDecoration(
          selectionColor:
              selectionTheme.selectionColor ?? Colors.blue.withOpacity(0.3),
        );
    return SuperSelectableText(
      key: _selectableTextKey,
      textSpan: widget.textSpan,
      textSelection: _selection,
      textSelectionDecoration: TextSelectionDecoration(
        selectionColor: selectionDecoration.selectionColor,
      ),
    );
  }

  @override
  MouseCursor? getCursorAtOffset(Offset localOffset) {
    final offsetOverlapsText =
        _selectableTextKey.currentState?.isTextAtOffset(localOffset) ?? false;

    if (offsetOverlapsText) return SystemMouseCursors.text;
  }
}

class TextSelectableDecoration {
  const TextSelectableDecoration({
    required this.selectionColor,
  });
  final Color selectionColor;
}
