// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'ආග්‍රිමේට්';

  @override
  String get login => 'ඇතුල් වන්න';

  @override
  String get signUp => 'ලියාපදිංචි වන්න';

  @override
  String get email => 'ඊමේල්';

  @override
  String get password => 'මුරපදය';

  @override
  String get forgotPassword => 'මුරපදය අමතකද?';

  @override
  String get dontHaveAccount => 'ගිණුමක් නැද්ද?';

  @override
  String get alreadyHaveAccount => 'දැනටමත් ගිණුමක් තිබේද?';

  @override
  String get selectRole => 'භූමිකාව තෝරන්න';

  @override
  String get pleaseSignIn => 'කරුණාකර ඇතුල් වීමට උත්සාහ කරන්න.';

  @override
  String get pleaseChooseRole => 'කරුණාකර ඉදිරියට යාමට ඔබේ භූමිකාව තෝරන්න:';

  @override
  String get farmer => 'ගොවියා';

  @override
  String get customer => 'පාරිභෝගිකයා';

  @override
  String get driver => 'රියදුරු';

  @override
  String pleaseEnterField(Object field) {
    return 'කරුණාකර ඔබගේ $field ඇතුළත් කරන්න';
  }

  @override
  String get customerLogin => 'පාරිභෝගික ඇතුල් වීම';

  @override
  String get driverLogin => 'රියදුරු ඇතුල් වීම';

  @override
  String get farmerLogin => 'ගොවියා ඇතුල් වීම';

  @override
  String get createDriverProfile => 'රියදුරු පැතිකඩ සාදන්න';
}
