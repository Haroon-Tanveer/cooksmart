import 'groq_service.dart';

/// Where the app should send AI requests.
///
/// A build compiled with `--dart-define=GROQ_API_KEY=...` calls Groq directly
/// and needs no server at all. A build without a key points `baseUrl` at a proxy,
/// which is what the offline build and the test fakes use.
class GroqConfig {
  const GroqConfig({
    required this.baseUrl,
    required this.liveEnabled,
    this.lastError,
  });

  /// Where the app should send AI requests.
  ///
  /// A build compiled with `--dart-define=GROQ_API_KEY=...` talks to Groq
  /// directly and needs no server. Without a key, point this at a proxy, which is
  /// what the offline build and the test fakes use.
  static const String defaultBaseUrl = String.fromEnvironment('AI_BASE_URL');

  /// Live generation is on from the first launch, always. Having to reach into
  /// settings before the app does the obvious thing was the wrong default, and
  /// with no key or endpoint the app falls back to the local library on its own.
  static const bool defaultLiveEnabled = true;

  /// True when the build carries a key and calls Groq without a proxy.
  static bool get callsProviderDirectly => AiProvider.hasKey;

  /// `10.0.2.2` is how the Android emulator reaches the host machine.
  static const String emulatorProxyUrl = 'http://10.0.2.2:8787';
  static const String emulatorMockUrl = 'http://10.0.2.2:8788';

  final String baseUrl;

  /// When false the app never touches the network and uses the local engine.
  final bool liveEnabled;
  final String? lastError;

  bool get isConfigured => AiProvider.hasKey || baseUrl.trim().isNotEmpty;

  /// What the switch in settings reflects: the user's choice, which now starts
  /// on. Whether a call can actually succeed is decided by the service, which
  /// reports the reason rather than failing silently.
  bool get isLive => liveEnabled;

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
