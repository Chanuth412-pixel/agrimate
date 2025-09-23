import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Agrimate'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get chooseYourRole;

  /// No description provided for @selectRoleDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a role to continue. You can change this later in settings.'**
  String get selectRoleDescription;

  /// No description provided for @farmerDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage harvests, weather insights and orders.'**
  String get farmerDescription;

  /// No description provided for @customerDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse fresh produce and place orders.'**
  String get customerDescription;

  /// No description provided for @driverDescription.
  ///
  /// In en, this message translates to:
  /// **'Deliver orders and view schedules.'**
  String get driverDescription;

  /// No description provided for @welcomeBackCustomer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Customer!'**
  String get welcomeBackCustomer;

  /// No description provided for @welcomeBackFarmer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Farmer!'**
  String get welcomeBackFarmer;

  /// No description provided for @welcomeBackDriver.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Driver!'**
  String get welcomeBackDriver;

  /// No description provided for @welcomeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Customer!'**
  String get welcomeCustomer;

  /// No description provided for @welcomeFarmer.
  ///
  /// In en, this message translates to:
  /// **'Welcome Farmer!'**
  String get welcomeFarmer;

  /// No description provided for @welcomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Welcome Driver!'**
  String get welcomeDriver;

  /// No description provided for @letsGrowTogether.
  ///
  /// In en, this message translates to:
  /// **'Let\'s grow together'**
  String get letsGrowTogether;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @emailPhone.
  ///
  /// In en, this message translates to:
  /// **'Email/Phone'**
  String get emailPhone;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @profileCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully'**
  String get profileCreatedSuccessfully;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter Email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Name'**
  String get enterName;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter Location'**
  String get enterLocation;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone'**
  String get enterPhone;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @pleaseEnterField.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String pleaseEnterField(Object field);

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get pleaseSignIn;

  /// No description provided for @pleaseChooseRole.
  ///
  /// In en, this message translates to:
  /// **'Please choose your role to continue:'**
  String get pleaseChooseRole;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @customerLogin.
  ///
  /// In en, this message translates to:
  /// **'Customer Login'**
  String get customerLogin;

  /// No description provided for @driverLogin.
  ///
  /// In en, this message translates to:
  /// **'Driver Login'**
  String get driverLogin;

  /// No description provided for @farmerLogin.
  ///
  /// In en, this message translates to:
  /// **'Farmer Login'**
  String get farmerLogin;

  /// No description provided for @createDriverProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Driver Profile'**
  String get createDriverProfile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cropDemandTrends.
  ///
  /// In en, this message translates to:
  /// **'Crop Demand Trends'**
  String get cropDemandTrends;

  /// No description provided for @ongoingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Transactions'**
  String get ongoingTransactions;

  /// No description provided for @weekDemandForecast.
  ///
  /// In en, this message translates to:
  /// **'4-Week Demand Forecast'**
  String get weekDemandForecast;

  /// No description provided for @deliveryGuy.
  ///
  /// In en, this message translates to:
  /// **'Delivery Guy'**
  String get deliveryGuy;

  /// No description provided for @selfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Self Delivery'**
  String get selfDelivery;

  /// No description provided for @chooseDelivery.
  ///
  /// In en, this message translates to:
  /// **'Choose Delivery'**
  String get chooseDelivery;

  /// No description provided for @addHarvest.
  ///
  /// In en, this message translates to:
  /// **'Add Harvest'**
  String get addHarvest;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @farmerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get farmerDashboard;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noHarvestsYet.
  ///
  /// In en, this message translates to:
  /// **'No harvests yet'**
  String get noHarvestsYet;

  /// No description provided for @addFirstHarvest.
  ///
  /// In en, this message translates to:
  /// **'Add your first harvest to get started'**
  String get addFirstHarvest;

  /// No description provided for @addHarvestButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add Harvest'**
  String get addHarvestButton;

  /// No description provided for @cropName.
  ///
  /// In en, this message translates to:
  /// **'Crop Name'**
  String get cropName;

  /// No description provided for @expectedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Expected Quantity'**
  String get expectedQuantity;

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per KG'**
  String get pricePerKg;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @saveHarvest.
  ///
  /// In en, this message translates to:
  /// **'Save Harvest'**
  String get saveHarvest;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @addNewHarvest.
  ///
  /// In en, this message translates to:
  /// **'Add New Harvest'**
  String get addNewHarvest;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @previewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Preview completed! You can now submit your harvest data.'**
  String get previewCompleted;

  /// No description provided for @pleasePreviewFirst.
  ///
  /// In en, this message translates to:
  /// **'Please preview your data first before submitting!'**
  String get pleasePreviewFirst;

  /// No description provided for @dataChangedPreviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Data has changed since last preview. Please preview again.'**
  String get dataChangedPreviewAgain;

  /// No description provided for @pleaseLoginToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Please log in to submit harvest data.'**
  String get pleaseLoginToSubmit;

  /// No description provided for @harvestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Harvest data submitted successfully!'**
  String get harvestSubmittedSuccessfully;

  /// No description provided for @errorSubmittingHarvest.
  ///
  /// In en, this message translates to:
  /// **'Error submitting harvest data'**
  String get errorSubmittingHarvest;

  /// No description provided for @plantingDate.
  ///
  /// In en, this message translates to:
  /// **'Planting Date'**
  String get plantingDate;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select Crop'**
  String get selectCrop;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorOccurred;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth error'**
  String get authError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'si': return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
