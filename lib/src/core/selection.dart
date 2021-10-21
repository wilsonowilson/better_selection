import 'package:flutter/material.dart';

import 'element.dart';

/// A logical representation of a position within a selectable element.
@immutable
abstract class ElementPosition {}

/// Interface for the selection within a selectable element.
@immutable
abstract class ElementSelection {}

/// A logical position within a SelectableScope.
@immutable
class ScopePosition {
  const ScopePosition({
    required this.elementDetails,
    required this.elementPosition,
  });

  final ElementPosition elementPosition;
  final SelectableElementDetails elementDetails;
}

/// A representation of the selection within a SelectableScope.
@immutable
class ScopeSelection {
  const ScopeSelection({
    required this.base,
    required this.extent,
  });

  /// Creates a [ScopeSelection] with an equal base and extent.
  const ScopeSelection.collapsed({
    required ScopePosition position,
  })  : base = position,
        extent = position;

  /// The starting point of the selection
  final ScopePosition base;

  /// The ending point of the selection
  final ScopePosition extent;

  /// Creates a collapsed selection from the extent of the [ScopeSelection]
  ScopeSelection collapse() {
    if (isCollapsed) return this;
    return ScopeSelection(base: extent, extent: extent);
  }

  /// Returns `true` if the selection is collapsed.
  bool get isCollapsed => base == extent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopeSelection &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          extent == other.extent;

  @override
  int get hashCode => base.hashCode ^ extent.hashCode;

  ScopeSelection copyWith({
    ScopePosition? base,
    ScopePosition? extent,
  }) {
    return ScopeSelection(
      base: base ?? this.base,
      extent: extent ?? this.extent,
    );
  }
}
