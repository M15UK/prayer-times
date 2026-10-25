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
}
