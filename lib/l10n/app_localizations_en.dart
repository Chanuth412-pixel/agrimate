// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Agrimate';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get selectRole => 'Select Role';

  @override
  String get pleaseSignIn => 'Please sign in to continue.';

  @override
  String get pleaseChooseRole => 'Please choose your role to continue:';

  @override
  String get farmer => 'Farmer';

  @override
  String get customer => 'Customer';

  @override
  String get driver => 'Driver';

  @override
  String pleaseEnterField(Object field) {
    return 'Please enter your $field';
  }

  @override
  String get customerLogin => 'Customer Login';

  @override
  String get driverLogin => 'Driver Login';

  @override
  String get farmerLogin => 'Farmer Login';

  @override
  String get createDriverProfile => 'Create Driver Profile';
}
