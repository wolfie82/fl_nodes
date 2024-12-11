// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String getOperatingSystem() {
  final userAgent = html.window.navigator.userAgent;
  if (userAgent.contains('Windows')) return 'Windows';
  if (userAgent.contains('Mac OS')) return 'macOS';
  if (userAgent.contains('Linux')) return 'Linux';
  if (userAgent.contains('Android')) return 'Android';
  if (userAgent.contains('iPhone') || userAgent.contains('iPad')) return 'iOS';
  return 'Web';
}
