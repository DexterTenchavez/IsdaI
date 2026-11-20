import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/recipe.dart';
import 'history_strings.dart';

/// Languages the app supports (SRS FR-27: English or Tagalog).
enum AppLang { en, tl }

/// Holds the current language, saves it on the device, and notifies
/// every screen that uses [TrContext.tr] so they rebuild instantly.
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final AppLanguage instance = AppLanguage._();

  static const String _key = 'app_language';

  AppLang _lang = AppLang.en;
  AppLang get lang => _lang;

  /// Name of a language in its own language (shown in the picker).
  static String nativeName(AppLang l) =>
      l == AppLang.en ? 'English' : 'Tagalog';

  /// Call once before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lang = prefs.getString(_key) == 'tl' ? AppLang.tl : AppLang.en;
    } catch (_) {
      _lang = AppLang.en;
    }
  }

  Future<void> set(AppLang l) async {
    if (l == _lang) return;
    _lang = l;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, l.name);
    } catch (_) {}
  }

  /// Looks up [key]. {name} placeholders are replaced from [args].
  String tr(String key, {Map<String, String>? args}) {
    final table = _lang == AppLang.tl ? _tl : _en;
    var text = table[key] ?? _en[key] ?? key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }
}

/// Put this above MaterialApp so every screen can find the language.
class AppLanguageScope extends InheritedNotifier<AppLanguage> {
  const AppLanguageScope({
    super.key,
    required AppLanguage language,
    required super.child,
  }) : super(notifier: language);

  static AppLanguage of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier ?? AppLanguage.instance;
  }
}

extension TrContext on BuildContext {
  /// Translated text. Using it makes the widget rebuild when the language changes.
  String tr(String key, {Map<String, String>? args}) =>
      AppLanguageScope.of(this).tr(key, args: args);
}

/// Recipe helpers (the Recipe model itself has no language).
String recipeTimeLabel(BuildContext c, Recipe r) {
  if (r.totalMinutes != null) {
    return c.tr('time_min', args: {'n': '${r.totalMinutes}'});
  }
  if (r.cookMinutes != null) {
    return c.tr('time_cook', args: {'n': '${r.cookMinutes}'});
  }
  return c.tr('time_none');
}

String recipeServingsLabel(BuildContext c, Recipe r) => r.servings != null
    ? c.tr('servings', args: {'n': '${r.servings}'})
    : c.tr('servings_none');

// ============================================================================
// TRANSLATIONS  (edit the wording here)
// ============================================================================

const Map<String, String> _en = {
  // Main
  'back_again': 'Press back again to exit',

  // Home
  'home_title': 'Know your catch\nis fresh',
  'home_sub': 'Offline fish freshness detection powered by on-device AI.',
  'guide1_title': 'Check the eye or gill',
  'guide1_desc':
      'IsdaAI reads freshness cues from the fish eye or gill, the two most reliable spots for spotting spoilage.',
  'guide2_title': 'Instant AI analysis',
  'guide2_desc':
      'Snap a photo and get a freshness result with a confidence score in seconds.',
  'guide3_title': 'Works fully offline',
  'guide3_desc':
      'No internet needed. The model runs entirely on your device, anywhere in the market or dock.',
  'quick_actions': 'Quick actions',
  'act_scan': 'Scan a photo',
  'act_scan_hint': 'Take or pick a picture',
  'act_live': 'Live detection',
  'act_live_hint': 'Detect fish in real time',
  'act_history': 'History',
  'act_history_hint': 'Your past results',
  'act_about': 'About IsdaAI',
  'act_about_hint': 'App info and version',

  // Camera
  'cam_hint': 'One fish at a time  •  show the eye or gills',
  'cam_model_fail': 'AI model failed to load: {error}',
  'cam_unknown': 'unknown error',
  'cam_read_fail': 'Could not read that image.',
  'cam_analyze_fail': 'Failed to analyze image.',
  'cam_wrong': 'Something went wrong: {error}',
  'cam_flash_na': 'Flash is not available on this device.',
  'species_label': 'Species',
  'act_fishinfo': 'Fish Info & Guide',
  'act_fishinfo_hint': 'Learn the 6 supported fish',
  'fishinfo_title': 'Fish Info & Guide',
  'fishinfo_species_title': 'Supported species',
  'fishinfo_guide_title': 'How to take a clear photo',
  'guide_step1': 'Scan one fish at a time.',
  'guide_step2': 'Show the whole body, the eye, and the gills.',
  'guide_step3': 'Use good light. Turn on the flash if it is dim.',
  'guide_step4':
      'Hold the phone steady and move close enough to see the eye clearly.',
  'guide_step5': 'Choose the fish species first, then take or pick the photo.',

  // Live scan
  'live_none': 'No detections (frames: {frames})',
  'live_found': '{count} found • {label} {pct}%',
  'live_stop': 'Stop Detection',
  'fresh': 'Fresh',
  'stale': 'Stale',

  // Result
  'result_title': 'Scan result',
  'badge_fresh': 'FRESH',
  'badge_stale': 'STALE',
  'species_unclear': 'Species unclear',
  'species_unknown': 'Unknown',
  'meter_fresh': 'Freshness confidence',
  'disclaimer':
      'IsdaAI gives an estimate from the photo. It is not a food-safety guarantee. If the fish smells bad or feels slimy, do not eat it.',
  'btn_recipe': 'Get Recipe Recommendation',
  'btn_scan_again': 'Scan another fish',
  'btn_retake': 'Retake photo',
  'stale_title': 'Do not eat this fish',
  'stale_body':
      'IsdaAI found signs of spoilage, so no recipe is suggested. Eating spoiled fish can make you sick.',
  'notfish_title': 'No fish detected',
  'notfish_body':
      'Point the camera at one fish and show the eye or gills, then try again.',
  'multi_title': 'Too many fish in the photo',
  'multi_body': 'Please take a photo of one fish at a time.',
  'low_title': "Couldn't tell clearly",
  'low_body':
      'The photo was hard to judge. Try better light, move closer to the eye or gills, and hold steady.',
  'tips_title': 'Check it yourself too',
  'tip1': 'Eyes are clear and slightly bulging',
  'tip2': 'Gills are bright red or pink, not brown or gray',
  'tip3': 'Flesh is firm and springs back when pressed',
  'tip4': 'Smell is mild and sea-like, not sour or sharp',
  'result_subtitle_fresh': 'This fish shows signs of freshness.',
  'result_subtitle_stale': 'This fish shows signs of spoilage.',
  'wrong_title': 'This is not {picked}',
  'wrong_body':
      'IsdaAI thinks this fish is {detected} ({pct}% match). Pick {detected} or Auto, then scan again.',

  // Recipes
  'rec_suggestions': 'Recipe suggestions',
  'rec_all': 'All recipes',
  'rec_intro': 'Your {fish} is fresh. Here are some ways to cook it.',
  'fish_word': 'fish',
  'rec_all_intro': 'Every recipe saved in the app.',
  'chip_this': 'This fish ({species})',
  'chip_all': 'All fish',
  'chip_saved': 'Saved',
  'rec_none_saved': 'No saved recipes yet. Open a recipe and tap Save recipe.',
  'btn_view_all': 'View All Recipes',
  'detail_title': 'Recipe',
  'ingredients': 'Ingredients',
  'equipment': 'Equipment',
  'instructions': 'Instructions',
  'save': 'Save recipe',
  'remove_saved': 'Remove from saved',
  'snack_saved': 'Recipe saved',
  'snack_removed': 'Removed from saved',
  'time_min': '{n} min',
  'time_cook': '{n} min cook',
  'time_none': 'Time not listed',
  'servings': '{n} servings',
  'servings_none': 'Servings not listed',
  'prep_min': 'Prep {n} min',
  'cook_min': 'Cook {n} min',

  // About
  'about_title': 'About IsdaAI',
  'about_tagline': 'Smart Fish Freshness Detection',
  'about_version': 'Version {v}',
  'about_desc_title': 'What is IsdaAI?',
  'about_desc':
      'IsdaAI is an offline app that tells you if a fish is Fresh or Stale. Take or pick a photo of the whole body, eyes, and gills of a fish, and the AI on your phone gives you a result in seconds.',
  'about_features_title': 'Features',
  'about_f_scan': 'Scan a photo of one fish',
  'about_f_live': 'Live detection with the camera',
  'about_f_history': 'Scan history saved on your phone',
  'about_f_info': 'Fish Info & Guide',
  'about_f_recipe': 'Recipe suggestions for fresh fish',
  'about_f_lang': 'English and Tagalog, Light and Dark theme',
  'about_species_title': 'Supported fish',
  'about_species_body': 'Six species commonly found in Trinidad, Bohol.',
  'about_offline_title': 'Offline and private',
  'about_offline_body':
      'The AI runs on your phone. No internet is needed, and your scans and photos stay on this device.',
  'about_disclaimer_title': 'Please note',
  'about_project_title': 'About the project',
  'about_school': 'Trinidad Municipal College – College of Computer Studies',
  'about_capstone': 'Capstone project, 2026',
  'about_devs_title': 'Developers',
  'about_licenses': 'View open-source licenses',

  // Settings
  'settings_title': 'Settings',
  'sec_general': 'General',
  'sec_data': 'Data',
  'sec_about': 'About',
  'set_language': 'Language',
  'set_theme': 'Theme',
  'theme_light': 'Light',
  'theme_dark': 'Dark',
  'set_history': 'Scan History',
  'set_history_sub': 'View past results',
  'set_about': 'About IsdaAI',
  'set_about_sub': 'App info & version',
  'lang_choose': 'Choose language',

  // First-time tours
  'tour_next': 'Next',
  'tour_skip': 'Skip',
  'tour_done': 'Got it',
  'tour_step': '{n} of {total}',
  'set_guide_done': 'Done. The guide will show again on each screen.',
  'tour_home_welcome_t': 'Welcome to IsdaAI',
  'tour_home_welcome_b': 'Let us show you around. It takes less than a minute.',
  'tour_home_slides_t': 'Quick tips',
  'tour_home_slides_b': 'Swipe these cards to see how IsdaAI works.',
  'tour_home_scan_t': 'Scan a photo',
  'tour_home_scan_b':
      'Your main button. It opens the camera so you can take or pick a photo of a fish.',
  'tour_home_live_t': 'Live detection',
  'tour_home_live_b':
      'Point the camera at fish and see Fresh or Stale boxes in real time.',
  'tour_home_info_t': 'Fish Info & Guide',
  'tour_home_info_b':
      'Learn about the 6 supported fish and how to take a clear photo.',
  'tour_home_history_t': 'History',
  'tour_home_history_b':
      'Your saved scans are kept here. They stay on your phone.',
  'tour_home_nav_t': 'Move around',
  'tour_home_nav_b':
      'Use the bar at the bottom to switch between Home, Camera, Live detection, and Settings.',
  'tour_cam_frame_t': 'Fit one fish in the frame',
  'tour_cam_frame_b':
      'Place one fish inside the corners and show its eye and gills.',
  'tour_cam_species_t': 'Species picker',
  'tour_cam_species_b':
      'Tap to choose the fish species. Leave it on Auto and IsdaAI will guess. If you pick a species and the fish looks like another one, IsdaAI will tell you.',
  'tour_cam_flash_t': 'Flash',
  'tour_cam_flash_b':
      'Turn on the light when it is dim so the eye and gills are clear.',
  'tour_cam_gallery_t': 'Gallery',
  'tour_cam_gallery_b':
      'Pick a photo you already have instead of using the camera.',
  'tour_cam_shutter_t': 'Take the photo',
  'tour_cam_shutter_b': 'Tap to scan. The result shows up in a few seconds.',
  'tour_live_intro_t': 'Live detection',
  'tour_live_intro_b':
      'The camera checks fish all the time. A green box means Fresh and a red box means Stale.',
  'tour_live_status_t': 'Status',
  'tour_live_status_b':
      'Shows how many fish were found and the result with the highest confidence.',
  'tour_live_torch_t': 'Light',
  'tour_live_torch_b': 'Turn on the light if it is dim.',
  'tour_live_stop_t': 'Stop',
  'tour_live_stop_b': 'Tap here to stop and go back.',
  'tour_res_verdict_t': 'Your result',
  'tour_res_verdict_b':
      'Shows if the fish is Fresh or Stale, how sure the AI is, and the species.',
  'tour_res_save_t': 'Save to history',
  'tour_res_save_b': 'Keep this scan on your phone so you can open it later.',
  'tour_res_recipe_t': 'Recipe ideas',
  'tour_res_recipe_b': 'For fresh fish, get recipes that match the species.',

  ...historyEn,
};

const Map<String, String> _tl = {
  // Main
  'back_again': 'Pindutin muli ang back para lumabas',

  // Home
  'home_title': 'Alamin kung sariwa\nang huli mo',
  'home_sub':
      'Offline na pagtuklas ng kasariwaan ng isda gamit ang AI sa mismong telepono.',
  'guide1_title': 'Tingnan ang mata o hasang',
  'guide1_desc':
      'Binabasa ng IsdaAI ang mga palatandaan ng kasariwaan mula sa mata o hasang ng isda, ang dalawang pinakamaaasahang bahagi para malaman kung sira na.',
  'guide2_title': 'Agarang AI analysis',
  'guide2_desc':
      'Kumuha ng litrato at makakuha ng resulta ng kasariwaan na may confidence score sa loob ng ilang segundo.',
  'guide3_title': 'Gumagana nang walang internet',
  'guide3_desc':
      'Hindi kailangan ng internet. Tumatakbo ang model sa mismong telepono mo, saan ka man sa palengke o pantalan.',
  'quick_actions': 'Mabilisang aksyon',
  'act_scan': 'Mag-scan ng litrato',
  'act_scan_hint': 'Kumuha o pumili ng larawan',
  'act_live': 'Live detection',
  'act_live_hint': 'Tuklasin ang isda nang real time',
  'act_history': 'Kasaysayan',
  'act_history_hint': 'Mga nakaraang resulta mo',
  'act_about': 'Tungkol sa IsdaAI',
  'act_about_hint': 'Impormasyon at bersyon ng app',

  // Camera
  'cam_hint': 'Isang isda lang  •  ipakita ang mata o hasang',
  'cam_model_fail': 'Hindi na-load ang AI model: {error}',
  'cam_unknown': 'hindi kilalang error',
  'cam_read_fail': 'Hindi mabasa ang larawang iyon.',
  'cam_analyze_fail': 'Hindi na-analyze ang larawan.',
  'cam_wrong': 'May nangyaring mali: {error}',
  'cam_flash_na': 'Walang flash ang device na ito.',
  'species_label': 'Uri',
  'act_fishinfo': 'Impormasyon at Gabay sa Isda',
  'act_fishinfo_hint': 'Alamin ang 6 na sinusuportahang isda',
  'fishinfo_title': 'Impormasyon at Gabay sa Isda',
  'fishinfo_species_title': 'Mga sinusuportahang isda',
  'fishinfo_guide_title': 'Paano kumuha ng malinaw na litrato',
  'guide_step1': 'Mag-scan ng isang isda lang.',
  'guide_step2': 'Ipakita ang buong katawan, ang mata, at ang hasang.',
  'guide_step3': 'Gumamit ng sapat na liwanag. Buksan ang flash kung madilim.',
  'guide_step4':
      'Panatilihing steady ang telepono at lumapit para malinaw ang mata.',
  'guide_step5':
      'Piliin muna ang uri ng isda, saka kumuha o pumili ng litrato.',

  // Live scan
  'live_none': 'Walang natuklasan (frames: {frames})',
  'live_found': '{count} natagpuan • {label} {pct}%',
  'live_stop': 'Ihinto ang Pagtuklas',
  'fresh': 'Sariwa',
  'stale': 'Bilasa',

  // Result
  'result_title': 'Resulta ng scan',
  'badge_fresh': 'SARIWA',
  'badge_stale': 'HINDI NA SARIWA',
  'species_unclear': 'Hindi malinaw ang uri',
  'species_unknown': 'Hindi alam',
  'meter_fresh': 'Kumpiyansa sa kasariwaan',
  'disclaimer':
      'Ang IsdaAI ay nagbibigay ng tantiya mula sa litrato. Hindi ito garantiya ng kaligtasan ng pagkain. Kung masama ang amoy ng isda o malagkit ito, huwag itong kainin.',
  'btn_recipe': 'Kumuha ng Rekomendasyon ng Recipe',
  'btn_scan_again': 'Mag-scan ng ibang isda',
  'btn_retake': 'Kumuha muli ng litrato',
  'stale_title': 'Huwag kainin ang isdang ito',
  'stale_body':
      'May nakitang senyales ng pagkasira ang IsdaAI, kaya walang iminumungkahing recipe. Maaari kang magkasakit sa pagkain ng sirang isda.',
  'notfish_title': 'Walang isdang nakita',
  'notfish_body':
      'Itutok ang kamera sa isang isda at ipakita ang mata o hasang, saka subukan muli.',
  'multi_title': 'Masyadong maraming isda sa litrato',
  'multi_body': 'Mangyaring kumuha ng litrato ng isang isda lang.',
  'low_title': 'Hindi malinaw ang resulta',
  'low_body':
      'Mahirap husgahan ang litrato. Subukan ang mas maliwanag na ilaw, lumapit sa mata o hasang, at panatilihing steady ang kamay.',
  'tips_title': 'Suriin mo rin mismo',
  'tip1': 'Malinaw at bahagyang nakaumbok ang mga mata',
  'tip2': 'Matingkad na pula o rosas ang hasang, hindi kayumanggi o abo',
  'tip3': 'Matigas ang laman at bumabalik kapag pinindot',
  'tip4': 'Banayad at amoy-dagat ang amoy, hindi maasim o matapang',
  'result_subtitle_fresh': 'May mga palatandaan ng kasariwaan ang isdang ito.',
  'result_subtitle_stale': 'May mga palatandaan ng pagkasira ang isdang ito.',
  'wrong_title': 'Hindi ito {picked}',
  'wrong_body':
      'Sa tingin ng IsdaAI, {detected} ang isdang ito ({pct}% tugma). Piliin ang {detected} o Auto, saka mag-scan muli.',

  // Recipes
  'rec_suggestions': 'Mga mungkahing recipe',
  'rec_all': 'Lahat ng recipe',
  'rec_intro': 'Sariwa ang {fish} mo. Narito ang ilang paraan para lutuin ito.',
  'fish_word': 'isda',
  'rec_all_intro': 'Lahat ng recipe sa app.',
  'chip_this': 'Isdang ito ({species})',
  'chip_all': 'Lahat ng isda',
  'chip_saved': 'Naka-save',
  'rec_none_saved':
      'Wala pang naka-save na recipe. Magbukas ng recipe at pindutin ang I-save ang recipe.',
  'btn_view_all': 'Tingnan ang Lahat ng Recipe',
  'detail_title': 'Recipe',
  'ingredients': 'Mga Sangkap',
  'equipment': 'Mga Kagamitan',
  'instructions': 'Mga Hakbang',
  'save': 'I-save ang recipe',
  'remove_saved': 'Alisin sa naka-save',
  'snack_saved': 'Na-save ang recipe',
  'snack_removed': 'Inalis sa naka-save',
  'time_min': '{n} min',
  'time_cook': '{n} min na pagluluto',
  'time_none': 'Walang nakalistang oras',
  'servings': '{n} servings',
  'servings_none': 'Walang nakalistang servings',
  'prep_min': 'Paghahanda {n} min',
  'cook_min': 'Pagluluto {n} min',

  // About
  'about_title': 'Tungkol sa IsdaAI',
  'about_tagline': 'Matalinong Pagtuklas ng Kasariwaan ng Isda',
  'about_version': 'Bersyon {v}',
  'about_desc_title': 'Ano ang IsdaAI?',
  'about_desc':
      'Ang IsdaAI ay isang offline na app na nagsasabi kung sariwa o bilasa ang isda. Kumuha o pumili ng litrato ng buong katawan, mata, at hasang ng isda, at magbibigay ang AI sa telepono mo ng resulta sa loob ng ilang segundo.',
  'about_features_title': 'Mga Tampok',
  'about_f_scan': 'Mag-scan ng litrato ng isang isda',
  'about_f_live': 'Live detection gamit ang kamera',
  'about_f_history': 'Kasaysayan ng scan na naka-save sa telepono mo',
  'about_f_info': 'Impormasyon at Gabay sa Isda',
  'about_f_recipe': 'Mga mungkahing recipe para sa sariwang isda',
  'about_f_lang': 'English at Tagalog, Maliwanag at Madilim na tema',
  'about_species_title': 'Mga sinusuportahang isda',
  'about_species_body': 'Anim na uri ng isdang karaniwan sa Trinidad, Bohol.',
  'about_offline_title': 'Offline at pribado',
  'about_offline_body':
      'Tumatakbo ang AI sa mismong telepono mo. Hindi kailangan ng internet, at nananatili sa device na ito ang mga scan at litrato mo.',
  'about_disclaimer_title': 'Pakitandaan',
  'about_project_title': 'Tungkol sa proyekto',
  'about_school': 'Trinidad Municipal College – College of Computer Studies',
  'about_capstone': 'Capstone project, 2026',
  'about_devs_title': 'Mga Developer',
  'about_licenses': 'Tingnan ang mga open-source license',

  // Settings
  'settings_title': 'Mga Setting',
  'sec_general': 'Pangkalahatan',
  'sec_data': 'Datos',
  'sec_about': 'Tungkol',
  'set_language': 'Wika',
  'set_theme': 'Tema',
  'theme_light': 'Maliwanag',
  'theme_dark': 'Madilim',
  'set_history': 'Kasaysayan ng Scan',
  'set_history_sub': 'Tingnan ang mga nakaraang resulta',
  'set_about': 'Tungkol sa IsdaAI',
  'set_about_sub': 'Impormasyon at bersyon ng app',
  'lang_choose': 'Piliin ang wika',

  // First-time tours
  'tour_next': 'Susunod',
  'tour_skip': 'Laktawan',
  'tour_done': 'Sige',
  'tour_step': '{n} ng {total}',
  'set_guide_done': 'Tapos na. Lalabas muli ang gabay sa bawat screen.',
  'tour_home_welcome_t': 'Maligayang pagdating sa IsdaAI',
  'tour_home_welcome_b':
      'Ipapakita namin sa iyo ang app. Wala pang isang minuto ito.',
  'tour_home_slides_t': 'Mabilisang tips',
  'tour_home_slides_b':
      'I-swipe ang mga card na ito para makita kung paano gumagana ang IsdaAI.',
  'tour_home_scan_t': 'Mag-scan ng litrato',
  'tour_home_scan_b':
      'Ang pangunahing button. Bubuksan nito ang kamera para kumuha o pumili ng litrato ng isda.',
  'tour_home_live_t': 'Live detection',
  'tour_home_live_b':
      'Itutok ang kamera sa isda at makita ang mga kahong Sariwa o Bilasa nang real time.',
  'tour_home_info_t': 'Impormasyon at Gabay sa Isda',
  'tour_home_info_b':
      'Alamin ang 6 na sinusuportahang isda at kung paano kumuha ng malinaw na litrato.',
  'tour_home_history_t': 'Kasaysayan',
  'tour_home_history_b':
      'Dito naka-save ang mga scan mo. Nananatili ito sa telepono mo.',
  'tour_home_nav_t': 'Paglibot sa app',
  'tour_home_nav_b':
      'Gamitin ang bar sa ibaba para lumipat sa Home, Camera, Live detection, at Settings.',
  'tour_cam_frame_t': 'Ilagay ang isang isda sa frame',
  'tour_cam_frame_b':
      'Ilagay ang isang isda sa loob ng mga sulok at ipakita ang mata at hasang nito.',
  'tour_cam_species_t': 'Tagapili ng uri',
  'tour_cam_species_b':
      'Pindutin para piliin ang uri ng isda. Iwanan sa Auto at huhulaan ito ng IsdaAI. Kung pumili ka ng uri pero mukhang ibang isda ito, sasabihin ng IsdaAI.',
  'tour_cam_flash_t': 'Flash',
  'tour_cam_flash_b':
      'Buksan ang ilaw kapag madilim para malinaw ang mata at hasang.',
  'tour_cam_gallery_t': 'Gallery',
  'tour_cam_gallery_b':
      'Pumili ng litratong nasa telepono mo na sa halip na gamitin ang kamera.',
  'tour_cam_shutter_t': 'Kumuha ng litrato',
  'tour_cam_shutter_b':
      'Pindutin para mag-scan. Lalabas ang resulta sa loob ng ilang segundo.',
  'tour_live_intro_t': 'Live detection',
  'tour_live_intro_b':
      'Palaging sinusuri ng kamera ang isda. Berdeng kahon ay Sariwa at pulang kahon ay Bilasa.',
  'tour_live_status_t': 'Katayuan',
  'tour_live_status_b':
      'Ipinapakita kung ilang isda ang natagpuan at ang resultang may pinakamataas na kumpiyansa.',
  'tour_live_torch_t': 'Ilaw',
  'tour_live_torch_b': 'Buksan ang ilaw kapag madilim.',
  'tour_live_stop_t': 'Ihinto',
  'tour_live_stop_b': 'Pindutin dito para huminto at bumalik.',
  'tour_res_verdict_t': 'Ang resulta mo',
  'tour_res_verdict_b':
      'Ipinapakita kung sariwa o bilasa ang isda, gaano ka-sigurado ang AI, at ang uri.',
  'tour_res_save_t': 'I-save sa kasaysayan',
  'tour_res_save_b':
      'Itago ang scan na ito sa telepono mo para mabuksan mo ito mamaya.',
  'tour_res_recipe_t': 'Mga ideya sa recipe',
  'tour_res_recipe_b':
      'Para sa sariwang isda, kumuha ng mga recipe na tugma sa uri.',

  ...historyTl,
};
