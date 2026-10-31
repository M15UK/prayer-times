// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مواقيت الصلاة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get startHeader => 'الأذان';

  @override
  String get jamaahHeader => 'الإقامة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get location => 'الموقع';

  @override
  String get yourLocation => 'موقعك';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get useMyLocationHint =>
      'مواقيت رسمية أو محسوبة لمكانك، حسب إعدادات حساب أوقات الصلاة';

  @override
  String get searchPlaces => 'ابحث عن مدينة أو مسجد';

  @override
  String get noPlacesFound => 'لا توجد أماكن مطابقة';

  @override
  String get choosePlace => 'اختر مكانًا';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد موقعك. اسمح بالوصول إلى الموقع، أو اختر مكانًا.';

  @override
  String get calculationUnavailable =>
      'لا يمكن حساب مواقيت الصلاة لمكانك بهذه الإعدادات (مثل المناطق القريبة جدًا من القطبين، أو إذا وقع العشاء بعد منتصف الليل). يُرجى اختيار مكان، أو تغيير حساب أوقات الصلاة في الإعدادات.';

  @override
  String get loadingTimes => 'جارٍ تحميل مواقيت الصلاة';

  @override
  String get hanafiNotPublished => 'هذا الجدول ينشر وقت العصر عند الجمهور فقط.';

  @override
  String get sourceUmmAlQura => 'تقويم أم القرى';

  @override
  String get language => 'اللغة';

  @override
  String get languagePhone => 'لغة الجهاز';

  @override
  String get asrTime => 'وقت العصر';

  @override
  String get asrStandard => 'الجمهور (الشافعي والمالكي والحنبلي)';

  @override
  String get asrStandardHint => 'وقت العصر الأبكر';

  @override
  String get asrHanafiOption => 'الحنفي';

  @override
  String get asrHanafiHint => 'وقت العصر المتأخر';

  @override
  String nextPrayerIn(String prayer, String countdown) {
    return '$prayer بعد $countdown';
  }

  @override
  String source(String name) {
    return 'المصدر: $name';
  }

  @override
  String calculatedWith(String method) {
    return 'محسوبة على هذا الجهاز (طريقة $method)';
  }

  @override
  String methodName(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'algerian': 'الجزائر',
      'dubai': 'دبي',
      'egyptian': 'الهيئة المصرية العامة للمساحة',
      'france': 'اتحاد المنظمات الإسلامية في فرنسا',
      'gulfRegion': 'منطقة الخليج',
      'indonesian': 'إندونيسيا',
      'jafari': 'الجعفرية',
      'jordan': 'الأردن',
      'karachi': 'جامعة العلوم الإسلامية بكراتشي',
      'kuwait': 'الكويت',
      'moonsightingCommittee': 'لجنة رؤية الهلال',
      'morocco': 'المغرب',
      'muslimWorldLeague': 'رابطة العالم الإسلامي',
      'northAmerica': 'الجمعية الإسلامية لأمريكا الشمالية',
      'portugal': 'البرتغال',
      'qatar': 'قطر',
      'russia': 'روسيا',
      'singapore': 'سنغافورة',
      'tehran': 'طهران',
      'tunisia': 'تونس',
      'turkiye': 'الشؤون الدينية التركية',
      'ummAlQura': 'أم القرى',
      'custom': 'مخصّصة',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String adjustedFrom(String changes, String source) {
    return 'معدّلة: $changes عن $source';
  }

  @override
  String minuteChange(String prayer, String change) {
    return '$prayer $change د';
  }

  @override
  String get listSeparator => '، ';

  @override
  String get adjustedMark => 'معدّلة';

  @override
  String get timesOutOfOrder =>
      'تعديل الدقائق جعل أوقات الصلاة غير مرتّبة. يُرجى تغييره.';

  @override
  String get calculated => 'محسوبة على هذا الجهاز';

  @override
  String hijriDate(int day, String month, int year) {
    return '$day $month $year هـ';
  }

  @override
  String hijriMonth(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'محرم',
      'm2': 'صفر',
      'm3': 'ربيع الأول',
      'm4': 'ربيع الآخر',
      'm5': 'جمادى الأولى',
      'm6': 'جمادى الآخرة',
      'm7': 'رجب',
      'm8': 'شعبان',
      'm9': 'رمضان',
      'm10': 'شوال',
      'm11': 'ذو القعدة',
      'm12': 'ذو الحجة',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get ummAlQuraCalendar => 'تقويم أم القرى';

  @override
  String get loadFailed =>
      'تعذّر تحميل مواقيت الصلاة. تحقّق من اتصالك بالإنترنت ثم حاول مرة أخرى.';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get prayerAlerts => 'تنبيهات الصلاة';

  @override
  String get prayerAlertsHint => 'إشعار عند دخول وقت كل صلاة من الصلوات الخمس';

  @override
  String get exactAlarmExplain =>
      'لتنبيهك عند دخول وقت كل صلاة تماماً، يطلب أندرويد أن تسمح لهذا التطبيق بـ«المنبّهات والتذكيرات». بدون ذلك قد تتأخر التنبيهات.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get alertsMayBeLate =>
      'قد تتأخر تنبيهات الصلاة. يمكنك السماح بالتوقيت الدقيق من إعدادات الهاتف.';

  @override
  String get notificationsBlocked =>
      'الإشعارات غير مسموح بها لهذا التطبيق، لذلك تنبيهات الصلاة متوقفة. يمكنك السماح بها من إعدادات الهاتف.';

  @override
  String get widgetOpenApp => 'افتح التطبيق لتحديث المواقيت';

  @override
  String get calculatedMark => 'محسوبة';

  @override
  String hijriMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'محرم',
      'm2': 'صفر',
      'm3': 'ربيع الأول',
      'm4': 'ربيع الآخر',
      'm5': 'جمادى الأولى',
      'm6': 'جمادى الآخرة',
      'm7': 'رجب',
      'm8': 'شعبان',
      'm9': 'رمضان',
      'm10': 'شوال',
      'm11': 'ذو القعدة',
      'm12': 'ذو الحجة',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';

  @override
  String get display => 'العرض';

  @override
  String get displayHint => 'المظهر واللون وصيغة الوقت والمواقيت المعروضة';

  @override
  String get theme => 'المظهر';

  @override
  String get asPhone => 'حسب الهاتف';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get colour => 'اللون';

  @override
  String get colourTeal => 'فيروزي';

  @override
  String get colourBlue => 'أزرق';

  @override
  String get colourGreen => 'أخضر';

  @override
  String get colourPurple => 'بنفسجي';

  @override
  String get colourAmber => 'كهرماني';

  @override
  String get colourWallpaper => 'ألوان الخلفية';

  @override
  String get colourWallpaperHint =>
      'أندرويد 12 وأحدث؛ الهواتف الأخرى تظهر باللون الفيروزي';

  @override
  String get colourHint => 'تتغير ألوان الأدوات على أندرويد 12 وأحدث';

  @override
  String get asPhoneClockHint =>
      'يظهر أي تغيير في الهاتف عند تشغيل التطبيق في المرة القادمة';

  @override
  String get timeFormat => 'صيغة الوقت';

  @override
  String get timeFormat12 => '12 ساعة (5:53 م)';

  @override
  String get timeFormat24 => '24 ساعة (17:53)';

  @override
  String get timesShown => 'المواقيت المعروضة';

  @override
  String get timesShownHint =>
      'يستمر العد التنازلي للمواقيت المخفية، وتصل تنبيهاتها كالمعتاد.';

  @override
  String get prayerCalculation => 'حساب أوقات الصلاة';

  @override
  String get prayerCalculationHint =>
      'الطريقة والعصر وخطوط العرض العليا وتعديل الدقائق';

  @override
  String get officialFirst => 'الجداول الرسمية أولًا';

  @override
  String get officialFirstOn =>
      'الأوقات الرسمية حيث تتوفر (لندن والسعودية)، وطريقتك في غيرها';

  @override
  String get officialFirstOff =>
      'طريقتك في كل مكان، مع الإشارة دائمًا إلى أنها محسوبة';

  @override
  String get method => 'الطريقة';

  @override
  String get methodAutomatic => 'تلقائي';

  @override
  String get methodAutomaticHint =>
      'أم القرى في السعودية، ورابطة العالم الإسلامي في غيرها';

  @override
  String angleOf(String prayer, String angle) {
    return '$prayer $angle';
  }

  @override
  String minutesAfterSunset(String prayer, int minutes) {
    return '$prayer بعد الغروب بـ$minutes د';
  }

  @override
  String get limitedBySeason => 'مع حدود موسمية';

  @override
  String get customAngles => 'زوايا مخصّصة';

  @override
  String get customAnglesHint => 'انخفاض الشمس تحت الأفق عند كل وقت';

  @override
  String get byAngle => 'زاوية';

  @override
  String get byMinutesAfterSunset => 'دقائق بعد الغروب';

  @override
  String get atSunset => 'عند الغروب';

  @override
  String get highLatitude => 'قاعدة خطوط العرض العليا';

  @override
  String get highLatitudeHint =>
      'للأماكن البعيدة عن خط الاستواء حيث لا تُظلم السماء بما يكفي، مثل صيف بريطانيا';

  @override
  String get highLatitudeAutomaticHint =>
      'سُبع الليل بعد خط العرض 48°، ومنتصف الليل أقرب إلى خط الاستواء';

  @override
  String get middleOfTheNight => 'منتصف الليل';

  @override
  String get middleOfTheNightHint =>
      'لا يصلح لصيف بريطانيا: يقع العشاء بعد منتصف الليل';

  @override
  String get seventhOfTheNight => 'سُبع الليل';

  @override
  String get twilightAngle => 'زاوية الشفق';

  @override
  String get minuteChanges => 'تعديل الدقائق';

  @override
  String minuteChangesHint(int max) {
    return 'قدّم وقتًا أو أخّره حتى $max دقيقة. يُشار إلى الأوقات المعدّلة بأنها معدّلة.';
  }

  @override
  String minutesValue(String minutes) {
    return '$minutes د';
  }

  @override
  String decrease(String name) {
    return 'إنقاص $name';
  }

  @override
  String increase(String name) {
    return 'زيادة $name';
  }
}
