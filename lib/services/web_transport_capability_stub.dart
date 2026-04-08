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
  return WebTransportCapability(
    isWeb: false,
    bluetoothSupported: false,
    webMidiSupported: false,
    webSerialSupported: false,
    bridgeConnected: bridgeConnected,
    osLabel: 'Native App',
    browserLabel: 'Native',
    recommendation: WebTransportRecommendation.nativeWeb,
    reason: 'Native app has direct access to local Bluetooth, USB, and MIDI.',
    downloadLinks: const [],
  );
}
