export 'src/core/element.dart';
export 'src/core/scope.dart';
export 'src/core/selection.dart';
export 'src/default_elements/box.dart';
export 'src/default_elements/text.dart';

/// Why super_selection depends on super_editor
///
/// One of the core widgets provided by super_editor is SuperSelectableText.
/// This widget makes it possible to implement text selection however you
/// want, since the widget is only responsible for rendering a selection and
/// not interacting with that selection.
///
/// super_editor also provides gesture apis which make paragraph selection on
/// triple tap possible.
///
/// How super_selection is designed
///
/// super_selection provides support for both text and non-text widgets.
///
/// It is heavily inspired by how SuperEditor handles multiple selections.
/// The base interface is also similar to DocumentComponents in super_editor.
/// Each selectable widget defines their internal positions at a localPosition,
/// and also provides information about their base position as well as extent.
/// They also provide a way to serialize information about the content between
/// two internal positions to a String.
///
/// Selections are defined by two points. The internal selection of
/// the starting node in scope's global position, and the internal position
/// of the node in the scope's global position. The actual selection represents
/// everything in-between these two points.
///
/// The selections are calculated from top-down like on the web, meaning that
/// adjacent widgets are selected as the cursor moves down.
///
///
