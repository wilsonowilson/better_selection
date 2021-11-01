import 'platform/platform_unsupported.dart'
    if (dart.library.io) 'platform/platform_io.dart'
    if (dart.library.html) 'platform/platform_html.dart' as platform;

class Platform {
  static final _instance = Platform();
  static Platform get instance => _instance;

  bool get isMacOS => platform.isMacOS;
}
