import 'dart:convert';

import 'package:cooksmart/state/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A live recipe payload shaped exactly like the real endpoint's, including the
/// long ingredient names and calorie text that stretch a row.
const Map<String, dynamic> kLiveRecipe = {
  'name': 'Groq Sheet Pan Chicken',
  'description': 'One tray, one oven, zero fuss.',
  'timeMinutes': 45,
  'difficulty': 'Easy',
  'servings': 4,
  'emoji': '🍗',
  'imagePrompt': 'sheet pan chicken',
  'owned': ['chicken'],
  'missing': ['paprika'],
  'calories': 1120,
  'ingredients': [
    {
      'name': 'boneless skinless chicken breasts',
      'quantity': '4 breasts, cut into bite-size pieces',
      'calories': 495,
    },
    {'name': 'smoked paprika', 'quantity': '2 tsp', 'calories': 15},
    {'name': 'extra-virgin olive oil', 'quantity': '2 tbsp', 'calories': 238},
  ],
  'steps': [
    'Heat the oven to 200°C and line a large sheet pan.',
    'Toss the chicken with the oil, paprika, salt and pepper until every piece is coated.',
    'Spread the pieces out in a single layer, not touching, so they roast rather than steam.',
    'Roast for 25 minutes, then turn and roast for 15 minutes more until 74°C inside.',
    'Rest the chicken for 5 minutes so the juices settle before serving.',
  ],
};

/// A live endpoint that answers instantly, so widget tests never touch a socket.
http.Client fakeGrokClient() {
  const headers = <String, String>{'content-type': 'application/json'};
  return MockClient((req) async {
    if (req.url.path == '/gemini/recipe') {
      return http.Response(jsonEncode(kLiveRecipe), 200, headers: headers);
    }
    if (req.url.path == '/gemini/suggest') {
      return http.Response(
        jsonEncode({
          'names': [
            'Miso Ramen',
            'Charred Corn Tacos',
            'Za\'atar Flatbread',
            'Preserved Lemon Tagine',
            'Sichuan Dry Green Beans',
            'Coconut Curry Lentil Pilaf',
          ],
        }),
        200,
        headers: headers,
      );
    }
    return http.Response(
      jsonEncode({'url': 'https://example.test/photo.jpg'}),
      200,
      headers: headers,
    );
  });
}

/// A state wired to the fake endpoint.
///
/// Production ships offline-first, so a test that wants live generation has to
/// ask for it explicitly.
AppState liveTestState() {
  final client = fakeGrokClient();
  final state = AppState(httpClient: client);
  state.setLiveEnabled(true);
  state.updateEndpoint('http://groq.test');
  return state;
}
