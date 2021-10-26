// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

final _platformInfo = html.window.navigator.platform ?? '';
final isMacOS = _platformInfo.toLowerCase().startsWith('mac');
