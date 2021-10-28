import 'dart:math';
import 'dart:ui';

import 'package:better_selection/src/core/selectable.dart';
import 'package:better_selection/src/core/selection.dart';
import 'package:better_selection/src/core/text.dart';
import 'package:better_selection/src/infrastructure/platform.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

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

class SelectableScopeState extends State<SelectableScope>
    with SingleTickerProviderStateMixin {
  SelectionType _selectionType = SelectionType.position;
  Offset? _dragStartInScope;
  Offset? _dragEndInScope;

  Offset? _dragEndInScrollableViewport;
  ScrollableState? _currentScrollable;

  MouseCursor? _cursorStyle;
  late FocusNode _focusNode;

  bool _scrollUpOnTick = false;
  bool _scrollDownOnTick = false;
  late Ticker _ticker;

  final _dragGutterExtent = 100;
  final _maxDragSpeed = 20;

  Map<ScrollableState, double>? _dragStartOffsetInScrollables;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
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
    _currentScrollable = _getTargetScrollable(details.globalPosition);

    _dragStartInScope = details.globalPosition;

    _clearSelection();
    _focusNode.requestFocus();

    _dragStartOffsetInScrollables =
        _mapScrollablesToCurrentOffsets(_registeredScrollables);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _dragEndInScope = details.globalPosition;

    if (_currentScrollable != null) {
      _dragEndInScrollableViewport =
          _getPositionInScrollable(_currentScrollable!, details.globalPosition);
    }

    _updateDragSelection();
    _scrollIfNearBoundary();
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStartInScope = null;
    _dragEndInScope = null;
    _dragEndInScrollableViewport = null;
    _dragStartOffsetInScrollables = null;
    _currentScrollable = null;
  }

  void _onPanCancel() {
    _dragStartInScope = null;
    _dragEndInScope = null;
    _dragEndInScrollableViewport = null;
    _dragStartOffsetInScrollables = null;
    _currentScrollable = null;
  }

  void _updateDragSelection() {
    if (_dragStartInScope == null) return;
    if (_dragEndInScope == null) return;

    for (final entry in _registeredSelectablesByScrollables.entries) {
      final scrollable = entry.key;
      final selectables = entry.value;
      if (scrollable == null) {
        _selectRegion(
          selectables: selectables,
          baseOffset: _dragStartInScope!,
          extentOffset: _dragEndInScope!,
          selectionType: _selectionType,
        );
      } else if (scrollable == _currentScrollable) {
        final scrollablePosition =
            Offset(0, _currentScrollable!.position.pixels);
        _selectRegion(
          selectables: selectables,
          baseOffset: _dragStartInScope!.translate(
            0,
            -(scrollablePosition.dy -
                _dragStartOffsetInScrollables![scrollable]!),
          ),
          extentOffset: _dragEndInScope!,
          selectionType: _selectionType,
        );
      } else {
        final scrollablePosition = Offset(0, scrollable.position.pixels);

        _selectRegion(
          selectables: selectables,
          baseOffset: _dragStartInScope!.translate(
            0,
            -(_dragStartOffsetInScrollables![scrollable]! +
                scrollablePosition.dy),
          ),
          extentOffset: _dragEndInScope!,
          selectionType: _selectionType,
        );
      }
    }
  }

  void _selectRegion({
    required List<Selectable> selectables,
    required Offset baseOffset,
    required Offset extentOffset,
    required SelectionType selectionType,
  }) {
    for (final selectable in selectables) {
      final selectableKey = selectable.key;
      final selectableState = selectableKey.currentState;
      final selectableBox =
          selectableKey.currentContext?.findRenderObject() as RenderBox?;

      if (selectableState != null && selectableBox != null) {
        if (!selectableBox.hasSize) continue;
        if (!selectableState.mounted) continue;
        final localBaseOffset = selectableBox.globalToLocal(
          baseOffset,
          ancestor: context.findRenderObject(),
        );
        final localExtentOffset = selectableBox.globalToLocal(
          extentOffset,
          ancestor: context.findRenderObject(),
        );
        if (localBaseOffset == Offset.zero &&
            localExtentOffset == Offset.zero) {
          continue;
        }
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
      if (!box.hasSize) continue;
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

  List<ScrollableState> get _registeredScrollables {
    return registeredSelectables
        .map((e) => e.parentScrollable)
        .whereNotNull()
        .toSet()
        .toList();
  }

  // The scrollable which should be affected by scrolling up or down
  // is the first scrollable at the point where drags start.
  ScrollableState? _getTargetScrollable(Offset globalPosition) {
    ScrollableState? targetScrollable;

    for (final scrollable in _registeredScrollables) {
      final size = scrollable.context.size;
      final box = scrollable.context.findRenderObject() as RenderBox?;

      if (size == null || box == null) continue;

      final offset = box.localToGlobal(Offset.zero);

      final rect = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

      if (rect.contains(globalPosition)) targetScrollable = scrollable;
    }

    return targetScrollable;
  }

  Map<ScrollableState, double> _mapScrollablesToCurrentOffsets(
    List<ScrollableState> scrollables,
  ) {
    final _scrollablesAndOffsets = <ScrollableState, double>{};

    for (final scrollable in scrollables) {
      _scrollablesAndOffsets[scrollable] = scrollable.position.pixels;
    }

    return _scrollablesAndOffsets;
  }

  Map<ScrollableState?, List<Selectable>>
      get _registeredSelectablesByScrollables {
    return groupBy<Selectable, ScrollableState?>(
      registeredSelectables,
      (selectable) {
        return selectable.parentScrollable;
      },
    );
  }

  Offset? _getPositionInScrollable(
    ScrollableState scrollable,
    Offset globalPosition,
  ) {
    final box = scrollable.context.findRenderObject() as RenderBox?;

    if (box == null) return null;

    return box.globalToLocal(globalPosition);
  }

  void _scrollIfNearBoundary() {
    if (_currentScrollable == null) return;
    assert(_dragEndInScrollableViewport != null);
    final scrollableBox =
        _currentScrollable!.context.findRenderObject()! as RenderBox;

    if (_dragEndInScrollableViewport!.dy < _dragGutterExtent) {
      _startScrollingUp();
    } else {
      _stopScrollingUp();
    }
    if (scrollableBox.size.height - _dragEndInScrollableViewport!.dy <
        _dragGutterExtent) {
      _startScrollingDown();
    } else {
      _stopScrollingDown();
    }
  }

  void _startScrollingUp() {
    if (_scrollUpOnTick) {
      return;
    }

    _scrollUpOnTick = true;
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _stopScrollingUp() {
    if (!_scrollUpOnTick) {
      return;
    }

    _scrollUpOnTick = false;
    _ticker.stop();
  }

  void _scrollUp(ScrollableState scrollable) {
    if (_dragEndInScrollableViewport == null) return;

    if (scrollable.position.pixels <= 0) {
      return;
    }

    final gutterAmount =
        _dragEndInScrollableViewport!.dy.clamp(0.0, _dragGutterExtent);
    final speedPercent = 1.0 - (gutterAmount / _dragGutterExtent);
    final scrollAmount = lerpDouble(0, _maxDragSpeed, speedPercent);

    scrollable.position.jumpTo(scrollable.position.pixels - scrollAmount!);
  }

  void _startScrollingDown() {
    if (_scrollDownOnTick) {
      return;
    }

    _scrollDownOnTick = true;
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _stopScrollingDown() {
    if (!_scrollDownOnTick) {
      return;
    }

    _scrollDownOnTick = false;
    _ticker.stop();
  }

  void _scrollDown(ScrollableState scrollable) {
    if (_dragEndInScrollableViewport == null) return;

    if (scrollable.position.pixels >= scrollable.position.maxScrollExtent) {
      return;
    }

    final scrollableBox = scrollable.context.findRenderObject()! as RenderBox;
    final gutterAmount =
        (scrollableBox.size.height - _dragEndInScrollableViewport!.dy)
            .clamp(0.0, _dragGutterExtent);
    final speedPercent = 1.0 - (gutterAmount / _dragGutterExtent);
    final scrollAmount = lerpDouble(0, _maxDragSpeed, speedPercent);

    scrollable.position.jumpTo(scrollable.position.pixels + scrollAmount!);
  }

  void _onTick(elapsedTime) {
    if (_currentScrollable == null) return;
    if (_scrollUpOnTick) {
      _scrollUp(_currentScrollable!);
    }
    if (_scrollDownOnTick) {
      _scrollDown(_currentScrollable!);
    }
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
