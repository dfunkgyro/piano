// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

enum WebTransportPreference { auto, webBluetooth, bridge }

enum WebTransportRecommendation { nativeWeb, bridgeRecommended, bridgeRequired }

class WebBridgeDownloadLink {
  final String platform;
  final String label;
  final String url;
  final String? version;

  const WebBridgeDownloadLink({
    required this.platform,
    required this.label,
    required this.url,
    this.version,
  });
}

class WebTransportCapability {
  final bool isWeb;
  final bool bluetoothSupported;
  final bool webMidiSupported;
  final bool webSerialSupported;
  final bool bridgeConnected;
  final String osLabel;
  final String browserLabel;
  final WebTransportRecommendation recommendation;
  final String reason;
  final List<WebBridgeDownloadLink> downloadLinks;

  const WebTransportCapability({
    required this.isWeb,
    required this.bluetoothSupported,
    required this.webMidiSupported,
    required this.webSerialSupported,
    required this.bridgeConnected,
    required this.osLabel,
    required this.browserLabel,
    required this.recommendation,
    required this.reason,
    required this.downloadLinks,
  });
}

Future<WebTransportCapability> detectWebTransportCapability({
  bool bridgeConnected = false,
}) async {
  final navigator = html.window.navigator;
  final userAgent = navigator.userAgent.toLowerCase();
  final bluetoothSupported = js_util.hasProperty(navigator, 'bluetooth');
  final webMidiSupported = js_util.hasProperty(navigator, 'requestMIDIAccess');
  final webSerialSupported = js_util.hasProperty(navigator, 'serial');
  final osLabel = _detectOs(userAgent);
  final browserLabel = _detectBrowser(userAgent);

  late final WebTransportRecommendation recommendation;
  late final String reason;

  if (bluetoothSupported && webMidiSupported) {
    recommendation = WebTransportRecommendation.nativeWeb;
    reason = 'This browser can use direct Web MIDI and Web Bluetooth. Prefer direct device access and keep the bridge only as a localhost fallback.';
  } else if (bluetoothSupported) {
    recommendation = WebTransportRecommendation.nativeWeb;
    reason = 'This browser supports direct Web Bluetooth. Use the bridge only if direct BLE MIDI is unstable or unavailable for your device.';
  } else if (webMidiSupported || webSerialSupported) {
    recommendation = WebTransportRecommendation.bridgeRecommended;
    reason = 'Native browser transport is partially available. The bridge should run as a localhost helper, not as a Bluetooth target.';
  } else if (bridgeConnected) {
    recommendation = WebTransportRecommendation.bridgeRecommended;
    reason = 'Direct browser device access is limited here. Use the bridge as a localhost helper that talks to the real MIDI device.';
  } else {
    recommendation = WebTransportRecommendation.bridgeRequired;
    reason = 'This browser lacks the required direct device APIs. The bridge is required, and it should connect to local MIDI/Bluetooth natively and expose them to the web app over localhost.';
  }

  return WebTransportCapability(
    isWeb: true,
    bluetoothSupported: bluetoothSupported,
    webMidiSupported: webMidiSupported,
    webSerialSupported: webSerialSupported,
    bridgeConnected: bridgeConnected,
    osLabel: osLabel,
    browserLabel: browserLabel,
    recommendation: recommendation,
    reason: reason,
    downloadLinks: await _downloadLinksFor(osLabel),
  );
}

String _detectOs(String userAgent) {
  if (userAgent.contains('windows')) return 'Windows';
  if (userAgent.contains('android')) return 'Android';
  if (userAgent.contains('iphone') || userAgent.contains('ipad')) return 'iOS';
  if (userAgent.contains('mac os x') || userAgent.contains('macintosh')) {
    return 'macOS';
  }
  if (userAgent.contains('linux')) return 'Linux';
  return 'Unknown';
}

String _detectBrowser(String userAgent) {
  if (userAgent.contains('edg/')) return 'Edge';
  if (userAgent.contains('chrome/') && !userAgent.contains('edg/')) {
    return 'Chrome';
  }
  if (userAgent.contains('safari/') && !userAgent.contains('chrome/')) {
    return 'Safari';
  }
  if (userAgent.contains('firefox/')) return 'Firefox';
  return 'Browser';
}

Future<List<WebBridgeDownloadLink>> _downloadLinksFor(String osLabel) async {
  final manifestLinks = await _downloadLinksFromManifest(osLabel);
  if (manifestLinks.isNotEmpty) {
    return manifestLinks;
  }

  const base = 'https://piano.thegyromusic.com/downloads/bridge';
  switch (osLabel) {
    case 'Windows':
      return const [
        WebBridgeDownloadLink(
          platform: 'windows',
          label: 'Download Bridge for Windows',
          url: '$base/windows/gyro-midi-bridge-windows.zip',
        ),
      ];
    case 'macOS':
      return const [
        WebBridgeDownloadLink(
          platform: 'macos',
          label: 'Download Bridge for macOS',
          url: '$base/macos/gyro-midi-bridge-macos.zip',
        ),
      ];
    case 'Linux':
      return const [
        WebBridgeDownloadLink(
          platform: 'linux',
          label: 'Download Bridge for Linux',
          url: '$base/linux/gyro-midi-bridge-linux.zip',
        ),
      ];
    case 'Android':
      return const [
        WebBridgeDownloadLink(
          platform: 'android',
          label: 'Download Bridge for Android',
          url: '$base/android/gyro-midi-bridge-android.apk',
        ),
      ];
    case 'iOS':
      return const [
        WebBridgeDownloadLink(
          platform: 'ios',
          label: 'Bridge for iOS',
          url: 'https://www.thegyromusic.com',
        ),
      ];
    default:
      return const [
        WebBridgeDownloadLink(
          platform: 'generic',
          label: 'Bridge Downloads',
          url: 'https://piano.thegyromusic.com/downloads/bridge/',
        ),
      ];
  }
}

Future<List<WebBridgeDownloadLink>> _downloadLinksFromManifest(
  String osLabel,
) async {
  const manifestUrl = 'https://piano.thegyromusic.com/downloads/bridge/manifest.json';
  try {
    final raw = await html.HttpRequest.getString(manifestUrl);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final version = data['version']?.toString();
    final platforms = (data['platforms'] as Map?)?.cast<String, dynamic>() ?? const {};

    String? platformKey;
    switch (osLabel) {
      case 'Windows':
        platformKey = 'windows';
        break;
      case 'macOS':
        platformKey = 'macos';
        break;
      case 'Linux':
        platformKey = 'linux';
        break;
      case 'Android':
        platformKey = 'android';
        break;
      default:
        platformKey = null;
    }

    if (platformKey == null) {
      return const [];
    }

    final entry = (platforms[platformKey] as Map?)?.cast<String, dynamic>();
    if (entry == null) {
      return const [];
    }

    final url = entry['url']?.toString();
    if (url == null || url.isEmpty) {
      return const [];
    }

    return [
      WebBridgeDownloadLink(
        platform: platformKey,
        label: entry['label']?.toString() ?? 'Download Bridge',
        url: url,
        version: version,
      ),
    ];
  } catch (_) {
    return const [];
  }
}
