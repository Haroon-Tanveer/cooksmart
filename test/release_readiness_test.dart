import 'package:cooksmart/services/groq_config.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the two things a shipped build has to get right about live AI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install is offline and has no endpoint baked in', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.init();

    // Someone installing from the Play Store has no proxy running, so the app
    // has to open as a complete offline library with nothing to connect to.
    expect(state.config.baseUrl, '');
    expect(state.isLive, isFalse);
    expect(GroqConfig.defaultLiveEnabled, isFalse);
  });

  test('upgrading from an older build does not silently switch live on', () {
    // Config written before liveEnabled existed must not restore it as true,
    // or an existing user gets a connection error they never opted into.
    final restored = GroqConfig.fromJson(<String, dynamic>{
      'baseUrl': 'http://10.0.2.2:8787',
    });
    expect(restored.liveEnabled, isFalse);

    // One that genuinely had it on keeps it on.
    final optedIn = GroqConfig.fromJson(<String, dynamic>{
      'baseUrl': 'https://proxy.example',
      'liveEnabled': true,
    });
    expect(optedIn.liveEnabled, isTrue);
  });
}
