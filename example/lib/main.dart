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
      debugShowCheckedModeBanner: false,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _buildText(
                          'Example',
                          const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildText('Home'),
                        const SizedBox(width: 8),
                        _buildText('About'),
                        const SizedBox(width: 8),
                        _buildText('Contact'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildText(lipsumLg),
                const SizedBox(height: 12),
                _buildText(lipsumLg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text, [TextStyle? style]) {
    return SelectableTextElement(
      textSpan: TextSpan(
        text: text,
        style: style ??
            const TextStyle(
              color: Colors.black,
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
