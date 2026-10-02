// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get greetingPrefix => 'Hey chef, ';

  @override
  String get greetingSuffix => 'what\'s cooking?';

  @override
  String get appTitle => 'CookSmart';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get homeSubtitle =>
      'Turn what you already have into something worth eating.';

  @override
  String get searchHint => 'Search recipes';

  @override
  String get recipeOfTheDay => 'Recipe of the day';

  @override
  String get useMyKitchen => 'Use my kitchen';

  @override
  String get featured => 'Featured';

  @override
  String get allRecipes => 'All recipes';

  @override
  String get catAll => 'All';

  @override
  String get catBreakfast => 'Breakfast';

  @override
  String get catLunch => 'Lunch';

  @override
  String get catDinner => 'Dinner';

  @override
  String get catDessert => 'Dessert';

  @override
  String get catQuick => 'Under 20m';

  @override
  String get catArabian => 'Arabian';

  @override
  String get catTurkish => 'Turkish';

  @override
  String get catPakistani => 'Pakistani';

  @override
  String get catFastfood => 'Fast food';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabSaved => 'Saved';

  @override
  String get createTitle => 'What is in your kitchen?';

  @override
  String get createSubtitle => 'Type what you have, or tap the suggestions.';

  @override
  String get ingredientHint => 'Add an ingredient';

  @override
  String get liveBannerOn => 'Live AI writes this recipe for you';

  @override
  String get liveBannerOff => 'Live AI is off, using the local library';

  @override
  String get generateRecipe => 'Generate Recipe';

  @override
  String get generating => 'Writing your recipe';

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String get clear => 'Clear';

  @override
  String get noResultsTitle => 'Nothing here yet';

  @override
  String get noSavedTitle => 'No saved recipes';

  @override
  String get noSavedBody => 'Recipes you save will show up here.';

  @override
  String get saveRecipe => 'Save Recipe';

  @override
  String get savedRecipe => 'Saved';

  @override
  String get remove => 'Remove';

  @override
  String get fromLibrary => 'From the library';

  @override
  String get fromYourIdea => 'from your idea';

  @override
  String get grokPick => 'Grok\'s pick';

  @override
  String get inKitchen => 'in your kitchen';

  @override
  String get needToBuy => 'YOU MAY NEED TO BUY';

  @override
  String get totalKcal => 'Total';

  @override
  String get perServing => 'per serving';

  @override
  String get totalLabel => 'Total';

  @override
  String get timeMin => 'Time';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get servings => 'Servings';

  @override
  String get methodHeading => 'Method';

  @override
  String stepsCount(int count) {
    return 'Method · $count steps';
  }

  @override
  String get liveAiTitle => 'Live AI';

  @override
  String get liveAiOn => 'on';

  @override
  String get liveAiOff => 'off';

  @override
  String get liveAiBusy => 'working';

  @override
  String get noEndpoint => 'no endpoint';

  @override
  String get useLiveGeneration => 'Use live generation';

  @override
  String get useLiveGenerationBody =>
      'Groq writes new recipes and dish ideas. The bundled library of 191 recipes works with this off, and the app opens that way by default.';

  @override
  String get keyStaysLocal =>
      'Your key stays on your own machine, inside the proxy server, and is never part of this app.';

  @override
  String get endpointLabel => 'Endpoint';

  @override
  String get testConnection => 'Test connection';

  @override
  String get testing => 'Testing...';

  @override
  String get endpointSaved => 'Endpoint saved';

  @override
  String get connectedOk => 'Connected to the AI service';

  @override
  String get noEndpointSet => 'No endpoint set';

  @override
  String get startProxyTitle => 'Start the proxy with:';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataBody =>
      'CookSmart has no account, no sign-in and no server of its own. We do not use analytics, advertising or crash reporting, and we do not collect or sell personal information.';

  @override
  String get staysOnPhone => 'What stays on your phone';

  @override
  String get staysOnPhoneBody =>
      'Your ingredient lists, favourites, saved recipes and the endpoint you have chosen are stored only on this device, in its private app storage. Removing the app deletes all of it.';

  @override
  String get optionalLive => 'Optional live recipe generation';

  @override
  String get optionalLiveBody =>
      'If you turn on live generation, the ingredients and dish you ask for are sent to an AI service through a small proxy server that you run yourself on your own computer. Your API key stays in that proxy and is never part of this app. Turn live generation off and nothing leaves your phone at all.';

  @override
  String get foodPhotos => 'Food photographs';

  @override
  String get foodPhotosBody =>
      'The recipe photographs bundled with the app come from TheMealDB and Wikipedia, under their respective licences, with the author and licence recorded alongside the app source. Recipes written by the AI service get a photograph looked up from the same sources.';

  @override
  String get children => 'Children';

  @override
  String get childrenBody =>
      'CookSmart is intended for a general audience. Because the app collects no data from anyone, it collects none from children either.';

  @override
  String get yourRights => 'Your rights and choices';

  @override
  String get yourRightsBody =>
      'Since no personal information is collected, there is nothing to disclose, correct or delete on request. You can erase everything the app stores at any time by clearing the app\'s storage in your device settings, or by uninstalling it.';

  @override
  String get policyChanges => 'Changes to this policy';

  @override
  String get policyChangesBody =>
      'If this policy changes, the updated text will appear on the Privacy screen inside the app and in the release notes for the version you have installed.';

  @override
  String get contact => 'Contact';

  @override
  String get contactBody =>
      'Questions about this policy can be sent to the contact address given on the app\'s Google Play Store listing.';

  @override
  String get policyLastUpdated => 'Last updated 29 September 2026';

  @override
  String searchResults(int count) {
    return '$count results';
  }

  @override
  String get photoBy => 'Recipe by Groq · photo from TheMealDB';

  @override
  String get lookingUpPhoto => 'Looking up a photo…';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get lookingForAnother => 'Looking for another photo…';

  @override
  String get photoOf => 'Photo';

  @override
  String get close => 'Close';

  @override
  String pageOf(int index, int total) {
    return '$index of $total';
  }

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get tipTitle => 'Tip';

  @override
  String get tipBody =>
      'Add what you have. If something is missing we will tell you exactly what to buy.';

  @override
  String addIngredient(String ingredient) {
    return 'Add $ingredient';
  }

  @override
  String get settings => 'Settings';

  @override
  String get networkError =>
      'Could not reach the AI service. Check your connection.';
}
