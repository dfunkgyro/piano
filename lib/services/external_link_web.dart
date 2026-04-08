// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> openExternalLink(String url) async {
  html.window.open(url, '_blank');
}
