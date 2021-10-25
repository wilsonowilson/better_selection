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
