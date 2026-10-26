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
  String get useMyLocationHint => 'أقرب جدول رسمي، أو مواقيت محسوبة لمكانك';

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
      'لا يمكن حساب مواقيت الصلاة لمكانك (مثل المناطق القريبة جدًا من القطبين). يُرجى اختيار مكان.';

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
  String get calculatedUmmAlQura => 'محسوبة على هذا الجهاز (طريقة أم القرى)';

  @override
  String get calculatedMuslimWorldLeague =>
      'محسوبة على هذا الجهاز (طريقة رابطة العالم الإسلامي)';

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
}
