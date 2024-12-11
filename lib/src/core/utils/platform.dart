import 'platform_stub.dart' as stub
    if (kIsWeb) 'platform_web.dart'
    if (kIsWeb) 'platform_native.dart' ;

String getOperatingSystem() {
  return stub.getOperatingSystem();
}

bool isMobile() {
  final os = getOperatingSystem();
  return os == 'Android' || os == 'iOS';
}
