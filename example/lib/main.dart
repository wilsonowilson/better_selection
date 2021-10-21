import 'package:flutter/material.dart';
import 'package:super_selection/super_selection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectableScope(
      child: Scaffold(
        body: SelectableScope(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SelectableTextElement(
                  textSpan: const TextSpan(
                    text: 'Hello world',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                SelectableTextElement(
                  textSpan: const TextSpan(
                    text: 'Hello world',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
