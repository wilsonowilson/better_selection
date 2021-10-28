# Better Selection

Experimental solution for web-like text selection across widgets (text, images, et cetera).

Better selection is depends on, and is heavily inspired by [super_editor](https://github.com/superlistapp/super_editor). It uses super_editor's `SuperSelectableText` which allows a text selection to be passed in as an argument, as well as `TapSequenceGestureRecognizer` for tripple click support.

This package is nowhere near stable, and many APIs may change in the near future.

## Limitations

- Limited scrollable support. Nested scrollviews and multiple scrollviews in a scope may behave unnaturally.
- No "multiple column layout" support. Using a scope on a Row behaves very differently from how it would on web.

## Installation

To get started, add the git dependency to your pubspec.yaml.

```yaml
better_selection:
  git:
    url: git://github.com/wilsonowilson/better_selection.git
    ref: main
```


## Usage

### Add the SelectableScope widget 

Before doing anything, you must insert the `SelectableScope` widget in your widget tree. You can place this widget wherever you want multiple text selection to take place.


```dart
class Screen extends StatelessWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableScope(
      child: Scaffold(
        body: Column(
          children: [
             ...
          ],
        ),
      ),
    );
  }
}
```
All child widgets that implement `SelectableWidget` can now be selected accross the scope.

### Default Selectable Widgets

By default, better_selection comes with two selectable widgets out of the box.

#### TextSelectable

A plain text widget. Also supports rich text.

```dart
 TextSelectable.plain('Lorem ipsum')
```

#### BoxSelectable

A SelectableWidget that allows its child to be selected. Example use cases would be copying images and icons. You can specify the copied text using the `text` parameter.

```dart
BoxSelectable(
  // Making the copyable text html enables 
  // inter-application image pasting.
  text: '<img src="$imageLink">',
  child: Image.network(imageLink),
),
```
