import 'package:flutter/material.dart' hide SelectableText;

import 'package:better_selection/better_selection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.indigo.withOpacity(0.3),
          )),
      home: const MyHomePage(),
    );
  }
}

class Screen extends StatelessWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableScope(
      child: Scaffold(
        body: Column(
          children: const [],
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableScope(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 12),
              _Header(),
              Expanded(
                child: SingleChildScrollView(
                  child: _ArticleLayout(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleLayout extends StatelessWidget {
  const _ArticleLayout({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const _TextWidget(
          'An Awesome Headline',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BoxSelectable(
                child: Image.network(imageLink),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BoxSelectable(
                text: '<img src="$imageLink">',
                child: Image.network(imageLink2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Center(child: _TextWidget('Example Carousel')),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
        const SizedBox(height: 12),
        const _TextWidget(lipsumLg),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            _TextWidget(
              'Example',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            _TextWidget('Home'),
            SizedBox(width: 8),
            SizedBox(width: 8),
            _TextWidget('Contact'),
          ],
        ),
      ),
    );
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget(
    this.text, {
    Key? key,
    this.style,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    return TextSelectable(
      textSpan: TextSpan(
        text: text,
        style: style ??
            const TextStyle(
              color: Colors.black,
              height: 1.4,
            ),
      ),
    );
  }
}

const lipsumSm = 'Lorem ipsum dolor sit amet, consectetur adipiscing '
    'elit, sed do eiusmod tempor incididunt ut '
    'labore et dolore magna aliqua.';

const lipsumMd = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
    'sed do eiusmod tempor incididunt ut labore et dolore '
    'magna aliqua. Ut enim ad minim veniam, quis nostrud '
    'exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ';

const lipsumLg = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
    'sed do eiusmod tempor incididunt ut labore et dolore magna '
    'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
    'ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis '
    'aute irure dolor in reprehenderit in voluptate velit esse '
    'cillum dolore eu fugiat nulla pariatur.';

const imageLink =
    'https://images.unsplash.com/photo-1635185113179-3fa7fbb4ca5e?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=2070&q=80';
const imageLink2 =
    'https://images.unsplash.com/photo-1521706862577-47b053587f91?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=2072&q=80';
