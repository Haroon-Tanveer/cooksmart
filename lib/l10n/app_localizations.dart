import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @greetingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hey chef, '**
  String get greetingPrefix;

  /// No description provided for @greetingSuffix.
  ///
  /// In en, this message translates to:
  /// **'what\'s cooking?'**
  String get greetingSuffix;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CookSmart'**
  String get appTitle;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn what you already have into something worth eating.'**
  String get homeSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search recipes'**
  String get searchHint;

  /// No description provided for @recipeOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Recipe of the day'**
  String get recipeOfTheDay;

  /// No description provided for @useMyKitchen.
  ///
  /// In en, this message translates to:
  /// **'Use my kitchen'**
  String get useMyKitchen;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @allRecipes.
  ///
  /// In en, this message translates to:
  /// **'All recipes'**
  String get allRecipes;

  /// No description provided for @catAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catAll;

  /// No description provided for @catBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get catBreakfast;

  /// No description provided for @catLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get catLunch;

  /// No description provided for @catDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get catDinner;

  /// No description provided for @catDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get catDessert;

  /// No description provided for @catQuick.
  ///
  /// In en, this message translates to:
  /// **'Under 20m'**
  String get catQuick;

  /// No description provided for @catArabian.
  ///
  /// In en, this message translates to:
  /// **'Arabian'**
  String get catArabian;

  /// No description provided for @catTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get catTurkish;

  /// No description provided for @catPakistani.
  ///
  /// In en, this message translates to:
  /// **'Pakistani'**
  String get catPakistani;

  /// No description provided for @catFastfood.
  ///
  /// In en, this message translates to:
  /// **'Fast food'**
  String get catFastfood;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// No description provided for @tabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get tabSaved;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'What is in your kitchen?'**
  String get createTitle;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type what you have, or tap the suggestions.'**
  String get createSubtitle;

  /// No description provided for @ingredientHint.
  ///
  /// In en, this message translates to:
  /// **'Add an ingredient'**
  String get ingredientHint;

  /// No description provided for @liveBannerOn.
  ///
  /// In en, this message translates to:
  /// **'Live AI writes this recipe for you'**
  String get liveBannerOn;

  /// No description provided for @liveBannerOff.
  ///
  /// In en, this message translates to:
  /// **'Live AI is off, using the local library'**
  String get liveBannerOff;

  /// No description provided for @generateRecipe.
  ///
  /// In en, this message translates to:
  /// **'Generate Recipe'**
  String get generateRecipe;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Writing your recipe'**
  String get generating;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noResultsTitle;

  /// No description provided for @noSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes'**
  String get noSavedTitle;

  /// No description provided for @noSavedBody.
  ///
  /// In en, this message translates to:
  /// **'Recipes you save will show up here.'**
  String get noSavedBody;

  /// No description provided for @saveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save Recipe'**
  String get saveRecipe;

  /// No description provided for @savedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedRecipe;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @fromLibrary.
  ///
  /// In en, this message translates to:
  /// **'From the library'**
  String get fromLibrary;

  /// No description provided for @fromYourIdea.
  ///
  /// In en, this message translates to:
  /// **'from your idea'**
  String get fromYourIdea;

  /// No description provided for @grokPick.
  ///
  /// In en, this message translates to:
  /// **'Grok\'s pick'**
  String get grokPick;

  /// No description provided for @inKitchen.
  ///
  /// In en, this message translates to:
  /// **'in your kitchen'**
  String get inKitchen;

  /// No description provided for @needToBuy.
  ///
  /// In en, this message translates to:
  /// **'YOU MAY NEED TO BUY'**
  String get needToBuy;

  /// No description provided for @totalKcal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalKcal;

  /// No description provided for @perServing.
  ///
  /// In en, this message translates to:
  /// **'per serving'**
  String get perServing;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @timeMin.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeMin;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @servings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get servings;

  /// No description provided for @methodHeading.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodHeading;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'Method · {count} steps'**
  String stepsCount(int count);

  /// No description provided for @liveAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Live AI'**
  String get liveAiTitle;

  /// No description provided for @liveAiOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get liveAiOn;

  /// No description provided for @liveAiOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get liveAiOff;

  /// No description provided for @liveAiBusy.
  ///
  /// In en, this message translates to:
  /// **'working'**
  String get liveAiBusy;

  /// No description provided for @noEndpoint.
  ///
  /// In en, this message translates to:
  /// **'no endpoint'**
  String get noEndpoint;

  /// No description provided for @useLiveGeneration.
  ///
  /// In en, this message translates to:
  /// **'Use live generation'**
  String get useLiveGeneration;

  /// No description provided for @useLiveGenerationBody.
  ///
  /// In en, this message translates to:
  /// **'Groq writes new recipes and dish ideas. The bundled library of 191 recipes works with this off, and the app opens that way by default.'**
  String get useLiveGenerationBody;

  /// No description provided for @keyStaysLocal.
  ///
  /// In en, this message translates to:
  /// **'Your key stays on your own machine, inside the proxy server, and is never part of this app.'**
  String get keyStaysLocal;

  /// No description provided for @endpointLabel.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get endpointLabel;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @endpointSaved.
  ///
  /// In en, this message translates to:
  /// **'Endpoint saved'**
  String get endpointSaved;

  /// No description provided for @connectedOk.
  ///
  /// In en, this message translates to:
  /// **'Connected to the AI service'**
  String get connectedOk;

  /// No description provided for @noEndpointSet.
  ///
  /// In en, this message translates to:
  /// **'No endpoint set'**
  String get noEndpointSet;

  /// No description provided for @startProxyTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the proxy with:'**
  String get startProxyTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataBody.
  ///
  /// In en, this message translates to:
  /// **'CookSmart has no account, no sign-in and no server of its own. We do not use analytics, advertising or crash reporting, and we do not collect or sell personal information.'**
  String get yourDataBody;

  /// No description provided for @staysOnPhone.
  ///
  /// In en, this message translates to:
  /// **'What stays on your phone'**
  String get staysOnPhone;

  /// No description provided for @staysOnPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your ingredient lists, favourites, saved recipes and the endpoint you have chosen are stored only on this device, in its private app storage. Removing the app deletes all of it.'**
  String get staysOnPhoneBody;

  /// No description provided for @optionalLive.
  ///
  /// In en, this message translates to:
  /// **'Optional live recipe generation'**
  String get optionalLive;

  /// No description provided for @optionalLiveBody.
  ///
  /// In en, this message translates to:
  /// **'If you turn on live generation, the ingredients and dish you ask for are sent to an AI service through a small proxy server that you run yourself on your own computer. Your API key stays in that proxy and is never part of this app. Turn live generation off and nothing leaves your phone at all.'**
  String get optionalLiveBody;

  /// No description provided for @foodPhotos.
  ///
  /// In en, this message translates to:
  /// **'Food photographs'**
  String get foodPhotos;

  /// No description provided for @foodPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'The recipe photographs bundled with the app come from TheMealDB and Wikipedia, under their respective licences, with the author and licence recorded alongside the app source. Recipes written by the AI service get a photograph looked up from the same sources.'**
  String get foodPhotosBody;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @childrenBody.
  ///
  /// In en, this message translates to:
  /// **'CookSmart is intended for a general audience. Because the app collects no data from anyone, it collects none from children either.'**
  String get childrenBody;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your rights and choices'**
  String get yourRights;

  /// No description provided for @yourRightsBody.
  ///
  /// In en, this message translates to:
  /// **'Since no personal information is collected, there is nothing to disclose, correct or delete on request. You can erase everything the app stores at any time by clearing the app\'s storage in your device settings, or by uninstalling it.'**
  String get yourRightsBody;

  /// No description provided for @policyChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes to this policy'**
  String get policyChanges;

  /// No description provided for @policyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'If this policy changes, the updated text will appear on the Privacy screen inside the app and in the release notes for the version you have installed.'**
  String get policyChangesBody;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactBody.
  ///
  /// In en, this message translates to:
  /// **'Questions about this policy can be sent to the contact address given on the app\'s Google Play Store listing.'**
  String get contactBody;

  /// No description provided for @policyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated 29 September 2026'**
  String get policyLastUpdated;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String searchResults(int count);

  /// No description provided for @photoBy.
  ///
  /// In en, this message translates to:
  /// **'Recipe by Groq · photo from TheMealDB'**
  String get photoBy;

  /// No description provided for @lookingUpPhoto.
  ///
  /// In en, this message translates to:
  /// **'Looking up a photo…'**
  String get lookingUpPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @lookingForAnother.
  ///
  /// In en, this message translates to:
  /// **'Looking for another photo…'**
  String get lookingForAnother;

  /// No description provided for @photoOf.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoOf;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String pageOf(int index, int total);

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @tipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tipTitle;

  /// No description provided for @tipBody.
  ///
  /// In en, this message translates to:
  /// **'Add what you have. If something is missing we will tell you exactly what to buy.'**
  String get tipBody;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add {ingredient}'**
  String addIngredient(String ingredient);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the AI service. Check your connection.'**
  String get networkError;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
