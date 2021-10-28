import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_selection/src/core/text.dart';
import 'package:super_selection/src/infrastructure/platform.dart';

import 'package:super_selection/super_selection.dart';

class SelectableScope extends StatefulWidget {
  const SelectableScope({
    Key? key,
    required this.child,
    this.onCopy,
  }) : super(key: key);

  final Widget child;

  // Callback for when Cmd + C (Ctrl + C on windows) is pressed.
  final ValueSetter<String>? onCopy;

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
  final registeredSelectables = <Selectable>[];

  void registerSelectable(Selectable details) {
    registeredSelectables.add(details);
  }

  void unregisterSelectable(Selectable details) {
    registeredSelectables.remove(details);
  }

  _SelectableScopeLayoutResolver get _layoutResolver =>
      _SelectableScopeLayoutResolver(registeredSelectables, context);

  void _clearSelection() {
    for (final selectable in registeredSelectables) {
      final state = selectable.key.currentState;

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
    for (final selectable in registeredSelectables) {
      final selectableKey = selectable.key;
      final selectableState = selectableKey.currentState;
      final selectableBox =
          selectableKey.currentContext?.findRenderObject() as RenderBox?;

      if (selectableState != null && selectableBox != null) {
        final localBaseOffset = selectableBox.globalToLocal(
          baseOffset,
          ancestor: context.findRenderObject(),
        );
        final localExtentOffset = selectableBox.globalToLocal(
          extentOffset,
          ancestor: context.findRenderObject(),
        );

        final selectableSelection = selectableState.getSelectionInRange(
          localBaseOffset,
          localExtentOffset,
        );

        if (selectableSelection == null) {
          selectableState.updateSelection(selectableState.getVoidSelection());
          continue;
        }
        // TODO: Handle selection type variations
        SelectableSelection adjustedSelection = selectableSelection;

        if (_selectionType == SelectionType.paragraph) {
          final newSelection = selectableState.getExpandedSelection();
          adjustedSelection = newSelection;
        } else if (_selectionType == SelectionType.word) {
          if (selectableState is TextSelectableWidgetState) {
            final textSelectableState =
                selectableState as TextSelectableWidgetState;

            final currentSelection =
                selectableSelection as TextSelectableSelection;
            if (!currentSelection.isValid) break;
            final wordSelectionAtBase =
                textSelectableState.getWordSelectionAt(currentSelection.base);
            final wordSelectionAtExtent =
                textSelectableState.getWordSelectionAt(currentSelection.extent);

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
            adjustedSelection = TextSelectableSelection(
              baseOffset: currentSelection.affinity == TextAffinity.downstream
                  ? lowerBound
                  : upperBound,
              extentOffset: currentSelection.affinity == TextAffinity.downstream
                  ? upperBound
                  : lowerBound,
            );
          }
        }
        selectableState.updateSelection(adjustedSelection);
      }
    }
  }

  void _selectWordAt({required ScopePosition scopePosition}) {
    final position = scopePosition;
    final selectablePosition = position.selectablePosition;
    if (selectablePosition is! TextSelectablePosition) return;

    final state =
        position.selectable.key.currentState as TextSelectableWidgetState?;

    if (state == null) return;

    final selection = state.getWordSelectionAt(selectablePosition);

    (state as SelectableWidgetState<SelectableWidget>)
        .updateSelection(selection);
  }

  void _selectParagraphAt({required ScopePosition scopePosition}) {
    final position = scopePosition;
    final selectablePosition = position.selectablePosition;
    if (selectablePosition is! TextSelectablePosition) return;

    final state =
        position.selectable.key.currentState as TextSelectableWidgetState?;
    if (state == null) return;
    final selection = state.getParagraphSelectionAt(selectablePosition);

    (state as SelectableWidgetState<SelectableWidget>)
        .updateSelection(TextSelectableSelection.fromTextSelection(selection));
  }

  void _onMouseMove(PointerEvent pointerEvent) {
    _updateCursorStyle(pointerEvent.position);
  }

  List<Selectable> _sortSelectablesByPosition() {
    final selectableList = registeredSelectables
      ..sort((a, b) {
        final aBox = a.key.currentContext!.findRenderObject()! as RenderBox;
        final bBox = b.key.currentContext!.findRenderObject()! as RenderBox;

        final aPos = aBox.localToGlobal(Offset.zero);
        final bPos = bBox.localToGlobal(Offset.zero);

        return aPos.compareTo(bPos);
      });

    return selectableList;
  }

  void _updateCursorStyle(Offset cursorOffset) {
    Selectable? selectableAboveCursor;
    for (final selectable in registeredSelectables) {
      final box =
          selectable.key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final size = box.size;
      final offset =
          box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

      if (rect.contains(cursorOffset)) {
        selectableAboveCursor = selectable;
        break;
      }
    }

    if (selectableAboveCursor == null) {
      setState(() {
        _cursorStyle = MouseCursor.defer;
      });
      return;
    }

    final box = selectableAboveCursor.key.currentContext!.findRenderObject()!
        as RenderBox;

    final localOffset = box.globalToLocal(cursorOffset);
    final desiredCursor =
        selectableAboveCursor.key.currentState!.getCursorAtOffset(localOffset);

    if (desiredCursor == null) {
      setState(() {
        _cursorStyle = MouseCursor.defer;
      });
    }
    setState(() {
      _cursorStyle = desiredCursor;
    });
  }

  String _getSelectedText() {
    final buffer = StringBuffer();
    final sortedSelectables = _sortSelectablesByPosition();
    for (final selectable in sortedSelectables) {
      final state = selectable.key.currentState;
      if (state == null) continue;
      final currentSelection = state.selection;
      final text = state.serializeSelection(currentSelection);
      if (text != null && text.isNotEmpty) {
        buffer
          ..writeln(text)
          ..writeln();
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: (_, event) {
        if (event is RawKeyUpEvent) {
          return KeyEventResult.ignored;
        }
        final isMacOS = Platform.instance.isMacOS;

        final primaryKeyPressed =
            isMacOS ? event.isMetaPressed : event.isControlPressed;

        if (primaryKeyPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
          final text = _getSelectedText();

          final onCopy = widget.onCopy;

          if (onCopy == null) {
            Clipboard.setData(ClipboardData(text: text));
          } else {
            onCopy(text);
          }
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
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
    this._selectables,
    this.context,
  );
  final List<Selectable> _selectables;
  final BuildContext context;

  ScopePosition? getScopePositionAtOffset(Offset globalPosition) {
    final selectable = findSelectableAtOffset(globalPosition);
    if (selectable == null) return null;
    final selectableKey = selectable.key;
    final state = selectableKey.currentState!;
    final box = selectableKey.currentContext!.findRenderObject()! as RenderBox;

    final offset = box.globalToLocal(globalPosition);

    final position = state.getPositionAtOffset(offset);

    return ScopePosition(selectable: selectable, selectablePosition: position);
  }

  Selectable? findSelectableAtOffset(Offset offset) {
    for (final selectable in _selectables) {
      final key = selectable.key;

      if (key.currentState == null ||
          key.currentState is! SelectableWidgetState) continue;
      if (key.currentContext == null) continue;

      final box = key.currentContext!.findRenderObject()! as RenderBox;

      if (_isOffsetInBox(box, offset)) {
        return selectable;
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

extension on Offset {
  int compareTo(Offset other) {
    if (dx == other.dx && dy == other.dy) return 0;

    if (dy > other.dy) {
      return 1;
    } else if (dx > other.dx) {
      return 1;
    }

    return 0;
  }
}
