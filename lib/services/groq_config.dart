/// Where the app should send Gemini requests.
///
/// The Gemini key never reaches the device: the app talks to the local proxy in
/// `tool/server/gemini_proxy.js`, which holds `GEMINI_API_KEY` server-side. Any
/// endpoint can be swapped in at runtime (the bundled mock, a LAN host, a
/// deployed backend of your own).
class GroqConfig {
  const GroqConfig({
    required this.baseUrl,
    required this.liveEnabled,
    this.lastError,
  });

  /// Compile-time default, overridable with
  /// `--dart-define=GEMINI_BASE_URL=https://your-proxy.example`.
  ///
  /// There is deliberately no baked-in default: the shipped app opens with live
  /// generation off, so a fresh install behaves as a complete offline recipe
  /// library instead of showing a connection error to someone who has no proxy
  /// running. Point AI_BASE_URL at a deployed proxy to ship a build with live
  /// generation on from the start.
  static const String defaultBaseUrl = String.fromEnvironment('AI_BASE_URL');

  /// Whether a build has live generation switched on by default. True only when
  /// a proxy URL was compiled in.
  static const bool defaultLiveEnabled = defaultBaseUrl != '';

  /// `10.0.2.2` is how the Android emulator reaches the host machine.
  static const String emulatorProxyUrl = 'http://10.0.2.2:8787';
  static const String emulatorMockUrl = 'http://10.0.2.2:8788';

  final String baseUrl;

  /// When false the app never touches the network and uses the local engine.
  final bool liveEnabled;
  final String? lastError;

  bool get isConfigured => baseUrl.trim().isNotEmpty;
  bool get isLive => liveEnabled && isConfigured;

  GroqConfig copyWith({
    String? baseUrl,
    bool? liveEnabled,
    String? lastError,
    bool clearError = false,
  }) => GroqConfig(
    baseUrl: baseUrl ?? this.baseUrl,
    liveEnabled: liveEnabled ?? this.liveEnabled,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'liveEnabled': liveEnabled,
  };

  factory GroqConfig.fromJson(Map<String, dynamic> json) => GroqConfig(
    baseUrl: json['baseUrl'] as String? ?? defaultBaseUrl,
    // Default to this build's setting, not to true: a config written by an
    // older build has no liveEnabled key, and restoring it as true would
    // turn live generation on for someone who never asked for it.
    liveEnabled: json['liveEnabled'] as bool? ?? defaultLiveEnabled,
  );

  static String normalise(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Human hint about what an endpoint will actually reach on this device.
  static String describeEndpoint(String raw) {
    if (raw.contains('10.0.2.2')) return 'Android emulator → host machine';
    if (raw.contains('localhost') || raw.contains('127.0.0.1')) {
      return 'same device (will not work on an emulator)';
    }
    return raw;
  }
}
