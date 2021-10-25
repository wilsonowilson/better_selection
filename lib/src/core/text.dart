import 'package:super_selection/src/default_elements/text.dart';

abstract class TextElement {
  TextElementSelection getWordSelectionAt(
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
