import 'package:cooksmart/services/groq_config.dart';
import 'package:cooksmart/services/groq_service.dart';
import 'package:cooksmart/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards how a shipped build behaves when live generation is switched on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install generates live, with no setup', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.init();

    // Live is the default now, so a new user is not met with a switch that
    // has to be found before the app does the obvious thing.
    expect(state.isLive, isTrue);
  });

  test('a build with no key says what is missing rather than timing out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.init();

    state.addIngredient('chicken');
    final recipe = await state.generate();
    // With nothing configured it must fall back to the local library rather
    // than leave the cook with no recipe at all.
    expect(recipe, isNotNull);
    expect(recipe!.name, isNotEmpty);
    expect(state.liveError, contains('GROQ_API_KEY'));
  });

  test('an old saved config does not turn live generation back off', () {
    // Config written before the always-on change has no liveEnabled key.
    final restored = GroqConfig.fromJson(<String, dynamic>{
      'baseUrl': '',
    });
    expect(restored.liveEnabled, isTrue);
  });

  test('the user can still switch live generation off', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.init();
    expect(state.isLive, isTrue);

    state.setLiveEnabled(false);
    expect(state.isLive, isFalse);
  });

  test('a compiled key turns on the direct path', () {
    // True in a build made with --dart-define=GROQ_API_KEY, false otherwise.
    expect(AiProvider.hasKey, AiProvider.groqKey != '');
  });
}
