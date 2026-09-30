// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get greetingPrefix => 'يا طاهٍ، ';

  @override
  String get greetingSuffix => 'ماذا نطبخ؟';

  @override
  String get appTitle => 'CookSmart';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'طاب يومك';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get homeSubtitle => 'حوّل ما لديك في المطبخ إلى طبق يستحق التذوق.';

  @override
  String get searchHint => 'ابحث عن وصفات';

  @override
  String get recipeOfTheDay => 'وصفة اليوم';

  @override
  String get useMyKitchen => 'استخدم مطبخي';

  @override
  String get featured => 'المميزة';

  @override
  String get allRecipes => 'كل الوصفات';

  @override
  String get catAll => 'الكل';

  @override
  String get catBreakfast => 'فطور';

  @override
  String get catLunch => 'غداء';

  @override
  String get catDinner => 'عشاء';

  @override
  String get catDessert => 'حلويات';

  @override
  String get catQuick => 'أقل من ٢٠ د';

  @override
  String get catArabian => 'مأكولات عربية';

  @override
  String get catTurkish => 'مأكولات تركية';

  @override
  String get catPakistani => 'مأكولات باكستانية';

  @override
  String get catFastfood => 'وجبات سريعة';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabCreate => 'إنشاء';

  @override
  String get tabSaved => 'المحفوظات';

  @override
  String get createTitle => 'ماذا لديك في المطبخ؟';

  @override
  String get createSubtitle => 'اكتب ما لديك، أو اضغط على الاقتراحات.';

  @override
  String get ingredientHint => 'أضف مكوّنًا';

  @override
  String get liveBannerOn => 'الذكاء الاصطناعي يكتب هذه الوصفة لك';

  @override
  String get liveBannerOff => 'الذكاء الاصطناعي متوقف، نستخدم المكتبة المحلية';

  @override
  String get generateRecipe => 'أنشئ الوصفة';

  @override
  String get generating => 'نكتب وصفتك';

  @override
  String get surpriseMe => 'فاجئني';

  @override
  String get clear => 'مسح';

  @override
  String get noResultsTitle => 'لا يوجد شيء بعد';

  @override
  String get noSavedTitle => 'لا توجد وصفات محفوظة';

  @override
  String get noSavedBody => 'الوصفات التي تحفظها ستظهر هنا.';

  @override
  String get saveRecipe => 'احفظ الوصفة';

  @override
  String get savedRecipe => 'محفوظة';

  @override
  String get remove => 'إزالة';

  @override
  String get fromLibrary => 'من المكتبة';

  @override
  String get fromYourIdea => 'من فكرتك';

  @override
  String get grokPick => 'اختيار Grok';

  @override
  String get inKitchen => 'في مطبخك';

  @override
  String get needToBuy => 'قد تحتاج إلى شراء';

  @override
  String get totalKcal => 'الإجمالي';

  @override
  String get perServing => 'لكل حصة';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get timeMin => 'الوقت';

  @override
  String get difficulty => 'الصعوبة';

  @override
  String get servings => 'الأجزاء';

  @override
  String get methodHeading => 'الطريقة';

  @override
  String stepsCount(int count) {
    return '$count خطوات';
  }

  @override
  String get liveAiTitle => 'الذكاء الاصطناعي المباشر';

  @override
  String get liveAiOn => 'مفعّل';

  @override
  String get liveAiOff => 'متوقف';

  @override
  String get liveAiBusy => 'يعمل';

  @override
  String get noEndpoint => 'لا يوجد خادم';

  @override
  String get useLiveGeneration => 'استخدم التوليد المباشر';

  @override
  String get useLiveGenerationBody =>
      'يكتب Groq وصفات جديدة وأفكارًا للأطباق. تعمل المكتبة المضمّنة التي تضم ١٩١ وصفة مع إيقاف هذه الخاصية، ويبدأ التطبيق بهذه الحالة.';

  @override
  String get keyStaysLocal =>
      'يبقى مفتاحك على جهازك أنت، داخل الخادم الوسيط، ولا يكون جزءًا من هذا التطبيق أبدًا.';

  @override
  String get endpointLabel => 'الخادم';

  @override
  String get testConnection => 'اختبار الاتصال';

  @override
  String get testing => 'جارٍ الاختبار...';

  @override
  String get endpointSaved => 'تم حفظ الخادم';

  @override
  String get connectedOk => 'تم الاتصال بخدمة الذكاء الاصطناعي';

  @override
  String get noEndpointSet => 'لم يتم ضبط خادم';

  @override
  String get startProxyTitle => 'شغّل الخادم الوسيط بالأمر:';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get yourData => 'بياناتك';

  @override
  String get yourDataBody =>
      'لا يوجد في CookSmart حساب ولا تسجيل دخول ولا خادم خاص به. نحن لا نستخدم التحليلات ولا الإعلانات ولا تقارير الأعطال، ولا نجمع أي معلومات شخصية ولا نبيعها.';

  @override
  String get staysOnPhone => 'ما يبقى على هاتفك';

  @override
  String get staysOnPhoneBody =>
      'قوائم المكونات والمفضلة والوصفات المحفوظة والخادم الذي اخترته تُحفظ على هذا الجهاز فقط، ضمن مساحة التطبيق الخاصة. حذف التطبيق يمسح كل ذلك.';

  @override
  String get optionalLive => 'توليد الوصفات المباشر (اختياري)';

  @override
  String get optionalLiveBody =>
      'عند تفعيل التوليد المباشر، تُرسَل المكونات واسم الطبق الذي تطلبه إلى خدمة ذكاء اصطناعي عبر خادم وسيط صغير تشغّله أنت على حاسوبك. يبقى مفتاحك داخل ذلك الخادم ولا يكون جزءًا من التطبيق. أوقف التوليد المباشر ولا يغادر شيء هاتفك.';

  @override
  String get foodPhotos => 'صور الطعام';

  @override
  String get foodPhotosBody =>
      'صور الوصفات المضمّنة في التطبيق تأتي من TheMealDB وويكيبيديا وفق تراخيص كل مصدر، مع تسجيل اسم المصوّر والرخصة مرفقًا بكود التطبيق. أما الوصفات التي يكتبها الذكاء الاصطناعي فيُبحث لها عن صورة في المصدرين نفسيهما.';

  @override
  String get children => 'الأطفال';

  @override
  String get childrenBody =>
      'CookSmart موجّه لجميع الأعمار. وبما أن التطبيق لا يجمع بيانات من أحد، فإنه لا يجمعها من الأطفال أيضًا.';

  @override
  String get yourRights => 'حقوقك وخياراتك';

  @override
  String get yourRightsBody =>
      'لعدم جمع أي معلومات شخصية، لا يوجد ما nfصححه أو أحذفه عند الطلب. يمكنك مسح كل ما يخزّنه التطبيق في أي وقت من إعدادات الجهاز، أو بإلغاء تثبيته.';

  @override
  String get policyChanges => 'تغييرات هذه السياسة';

  @override
  String get policyChangesBody =>
      'إذا تغيّرت هذه السياسة، سيظهر النص المحدّث في شاشة الخصوصية داخل التطبيق وفي ملاحظات الإصدار للإصدار الذي ثبّته.';

  @override
  String get contact => 'التواصل';

  @override
  String get contactBody =>
      'يمكن إرسال أسئلة حول هذه السياسة إلى عنوان التواصل المذكور في صفحة التطبيق على Google Play.';

  @override
  String get policyLastUpdated => 'آخر تحديث ٢٩ سبتمبر ٢٠٢٦';

  @override
  String searchResults(int count) {
    return '$count نتائج';
  }

  @override
  String get photoBy => 'الوصفة من Groq · الصورة من TheMealDB';

  @override
  String get lookingUpPhoto => 'جارٍ البحث عن صورة...';

  @override
  String get changePhoto => 'غيّر الصورة';

  @override
  String get lookingForAnother => 'نبحث عن صورة أخرى...';

  @override
  String get photoOf => 'صورة';

  @override
  String get close => 'إغلاق';

  @override
  String pageOf(int index, int total) {
    return '$index من $total';
  }

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get tipTitle => 'نصيحة';

  @override
  String get tipBody => 'أضف ما لديك. وإذا نقص شيء فسنخبرك بما تشتريه بالضبط.';

  @override
  String addIngredient(String ingredient) {
    return 'أضف $ingredient';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get networkError =>
      'تعذّر الوصول إلى خدمة الذكاء الاصطناعي. تحقّق من اتصالك.';
}
