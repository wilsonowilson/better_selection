import 'package:flutter/material.dart';

import 'selectable.dart';

/// A logical representation of a position within a selectable.
@immutable
abstract class SelectablePosition {
  const SelectablePosition();
}

/// Interface for the selection within a selectable.
@immutable
abstract class SelectableSelection {
  const SelectableSelection();
}

/// A logical position within a SelectableScope.
@immutable
class ScopePosition {
  const ScopePosition({
    required this.selectable,
    required this.selectablePosition,
  });

  final SelectablePosition selectablePosition;
  final Selectable selectable;
}
