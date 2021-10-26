import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_selection/src/core/text.dart';

import 'package:super_selection/super_selection.dart';

class SelectableScope extends StatefulWidget {
  const SelectableScope({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  SelectableScopeState createState() => SelectableScopeState();

  static SelectableScopeState of(BuildContext context) {
    assert(debugCheckHasSelectableScope(context));
    return context.findAncestorStateOfType<SelectableScopeState>()!;
  }

  static bool debugCheckHasSelectableScope(BuildContext context) {
    final state = context.findAncestorStateOfType<SelectableScopeState>();
    if (state == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No SelectableScope widget ancestor found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a SelectableScope widget ancestor.',
        ),
        context.describeWidget(
          'The specific widget that could not find a SelectableScope ancestor was',
        ),
        context.describeOwnershipChain(
          'The ownership chain for the affected widget is',
        ),
        ErrorHint(
          'No SelectableScope ancestor could be found starting from the context '
          'that was passed to SelectableScope.of(). This can happen because you '
          'have not added a SelectableScope widget. s',
        ),
      ]);
    }
    return true;
  }
}

class SelectableScopeState extends State<SelectableScope> {
  SelectionType _selectionType = SelectionType.position;
  Offset? _dragStartInScope;
  Offset? _dragEndInScope;
  MouseCursor? _cursorStyle;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @visibleForTesting
  final registeredElements = <SelectableElementDetails>[];

  void registerElement(SelectableElementDetails details) {
    registeredElements.add(details);
  }

  void unregisterElement(SelectableElementDetails details) {
    registeredElements.remove(details);
  }

  _SelectableScopeLayoutResolver get _layoutResolver =>
      _SelectableScopeLayoutResolver(registeredElements, context);

  void _clearSelection() {
    for (final element in registeredElements) {
      final state = element.key.currentState;

      if (state == null) continue;
      state.updateSelection(state.getVoidSelection());
    }
  }

  void _onTapDown(TapDownDetails details) {
    _clearSelection();
    _selectionType = SelectionType.position;

    _focusNode.requestFocus();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _selectionType = SelectionType.word;

    _clearSelection();

    final scopePosition =
        _layoutResolver.getScopePositionAtOffset(details.globalPosition);

    if (scopePosition != null) {
      _selectWordAt(
        scopePosition: scopePosition,
      );
    }

    _focusNode.requestFocus();
  }

  void _onDoubleTap() {
    _selectionType = SelectionType.position;
  }

  void _onTripleTapDown(TapDownDetails details) {
    _selectionType = SelectionType.paragraph;

    _clearSelection();

    final position =
        _layoutResolver.getScopePositionAtOffset(details.globalPosition);

    if (position != null) {
      _selectParagraphAt(
        scopePosition: position,
      );
    }

    _focusNode.requestFocus();
  }

  void _onTripleTap() {
    _selectionType = SelectionType.position;
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartInScope = details.globalPosition;
    _clearSelection();
    _focusNode.requestFocus();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragEndInScope = details.globalPosition;

      _updateDragSelection();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _dragStartInScope = null;
      _dragEndInScope = null;
    });
  }

  void _onPanCancel() {
    setState(() {
      _dragStartInScope = null;
      _dragEndInScope = null;
    });
  }

  void _updateDragSelection() {
    if (_dragStartInScope == null) return;
    if (_dragEndInScope == null) return;

    _selectRegion(
      baseOffset: _dragStartInScope!,
      extentOffset: _dragEndInScope!,
      selectionType: _selectionType,
    );
  }

  void _selectRegion({
    required Offset baseOffset,
    required Offset extentOffset,
    required SelectionType selectionType,
  }) {
    for (final element in registeredElements) {
      final elementKey = element.key;
      final elementState = elementKey.currentState;
      final elementBox =
          elementKey.currentContext?.findRenderObject() as RenderBox?;

      if (elementState != null && elementBox != null) {
        final localBaseOffset = elementBox.globalToLocal(
          baseOffset,
          ancestor: context.findRenderObject(),
        );
        final localExtentOffset = elementBox.globalToLocal(
          extentOffset,
          ancestor: context.findRenderObject(),
        );

        final elementSelection = elementState.getSelectionInRange(
          localBaseOffset,
          localExtentOffset,
        );

        if (elementSelection == null) {
          elementState.updateSelection(elementState.getVoidSelection());
          continue;
        }
        // TODO: Handle selection type variations
        ElementSelection adjustedSelection = elementSelection;

        if (_selectionType == SelectionType.paragraph) {
          final newSelection = elementState.getExpandedSelection();
          adjustedSelection = newSelection;
        } else if (_selectionType == SelectionType.word) {
          if (elementState is TextElement) {
            final textElementState = elementState as TextElement;

            final currentSelection = elementSelection as TextElementSelection;
            if (!currentSelection.isValid) break;
            final wordSelectionAtBase =
                textElementState.getWordSelectionAt(currentSelection.base);
            final wordSelectionAtExtent =
                textElementState.getWordSelectionAt(currentSelection.extent);

            final lowerBound = min(
              min(
                currentSelection.start,
                wordSelectionAtBase.start,
              ),
              wordSelectionAtExtent.start,
            );
            final upperBound = max(
              max(
                currentSelection.end,
                wordSelectionAtBase.end,
              ),
              wordSelectionAtExtent.end,
            );
            adjustedSelection = TextElementSelection(
              baseOffset: currentSelection.affinity == TextAffinity.downstream
                  ? lowerBound
                  : upperBound,
              extentOffset: currentSelection.affinity == TextAffinity.downstream
                  ? upperBound
                  : lowerBound,
            );
          }
        }
        elementState.updateSelection(adjustedSelection);
      }
    }
  }

  void _selectWordAt({required ScopePosition scopePosition}) {
    final position = scopePosition;
    final elementPosition = position.elementPosition;
    if (elementPosition is! TextElementPosition) return;

    final state = position.elementDetails.key.currentState as TextElement?;

    if (state == null) return;

    final selection = state.getWordSelectionAt(elementPosition);

    (state as SelectableElementWidgetState<SelectableElementWidget>)
        .updateSelection(selection);
  }

  void _selectParagraphAt({required ScopePosition scopePosition}) {
    final position = scopePosition;
    final elementPosition = position.elementPosition;
    if (elementPosition is! TextElementPosition) return;

    final state = position.elementDetails.key.currentState as TextElement?;
    if (state == null) return;
    final selection = state.getParagraphSelectionAt(elementPosition);

    (state as SelectableElementWidgetState<SelectableElementWidget>)
        .updateSelection(TextElementSelection.fromTextSelection(selection));
  }

  void _onMouseMove(PointerEvent pointerEvent) {
    _updateCursorStyle(pointerEvent.position);
  }

  void _updateCursorStyle(Offset cursorOffset) {
    SelectableElementDetails? elementAboveCursor;
    for (final element in registeredElements) {
      final box = element.key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final size = box.size;
      final offset =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

      if (rect.contains(cursorOffset)) {
        elementAboveCursor = element;
        break;
      }
    }

    if (elementAboveCursor == null) {
      setState(() {
        _cursorStyle = MouseCursor.defer;
      });
      return;
    }

    final box =
        elementAboveCursor.key.currentContext!.findRenderObject()! as RenderBox;

    final localOffset = box.globalToLocal(cursorOffset);
    final desiredCursor =
        elementAboveCursor.key.currentState!.getCursorAtOffset(localOffset);

    if (desiredCursor == null) {
      setState(() {
        _cursorStyle = MouseCursor.defer;
      });
    }
    setState(() {
      _cursorStyle = desiredCursor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: <Type, GestureRecognizerFactory>{
          TapSequenceGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              TapSequenceGestureRecognizer>(
            () => TapSequenceGestureRecognizer(),
            (TapSequenceGestureRecognizer recognizer) {
              recognizer
                ..onTapDown = _onTapDown
                ..onDoubleTapDown = _onDoubleTapDown
                ..onDoubleTap = _onDoubleTap
                ..onTripleTapDown = _onTripleTapDown
                ..onTripleTap = _onTripleTap;
            },
          ),
          PanGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
            (PanGestureRecognizer recognizer) {
              recognizer
                ..onStart = _onPanStart
                ..onUpdate = _onPanUpdate
                ..onEnd = _onPanEnd
                ..onCancel = _onPanCancel;
            },
          ),
        },
        child: MouseRegion(
          onHover: _onMouseMove,
          cursor: _cursorStyle ?? MouseCursor.defer,
          child: Listener(
            onPointerMove: _onMouseMove,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SelectableScopeLayoutResolver {
  const _SelectableScopeLayoutResolver(
    this._elements,
    this.context,
  );
  final List<SelectableElementDetails> _elements;
  final BuildContext context;

  ScopePosition? getScopePositionAtOffset(Offset globalPosition) {
    final element = findElementAtOffset(globalPosition);
    if (element == null) return null;
    final elementKey = element.key;
    final state = elementKey.currentState!;
    final box = elementKey.currentContext!.findRenderObject()! as RenderBox;

    final offset = box.globalToLocal(globalPosition);

    final position = state.getPositionAtOffset(offset);

    return ScopePosition(elementDetails: element, elementPosition: position);
  }

  SelectableElementDetails? findElementAtOffset(Offset offset) {
    for (final element in _elements) {
      final key = element.key;

      if (key.currentState == null ||
          key.currentState is! SelectableElementWidgetState) continue;
      if (key.currentContext == null) continue;

      final box = key.currentContext!.findRenderObject()! as RenderBox;

      if (_isOffsetInBox(box, offset)) {
        return element;
      }
    }
  }

  bool _isOffsetInBox(RenderBox widgetBox, Offset offset) {
    final box = context.findRenderObject() as RenderBox?;
    final widgetOffset = widgetBox.localToGlobal(Offset.zero, ancestor: box);
    final widgetRect = widgetOffset & widgetBox.size;

    return widgetRect.contains(offset);
  }
}
