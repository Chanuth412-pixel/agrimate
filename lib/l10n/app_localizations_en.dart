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
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get selectRole => 'Select Role';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chooseYourRole => 'Choose your role';

  @override
  String get selectRoleDescription => 'Select a role to continue. You can change this later in settings.';

  @override
  String get farmerDescription => 'Manage harvests, weather insights and orders.';

  @override
  String get customerDescription => 'Browse fresh produce and place orders.';

  @override
  String get driverDescription => 'Deliver orders and view schedules.';

  @override
  String get welcomeBackCustomer => 'Welcome Back, Customer!';

  @override
  String get welcomeBackFarmer => 'Welcome Back, Farmer!';

  @override
  String get welcomeBackDriver => 'Welcome Back, Driver!';

  @override
  String get welcomeCustomer => 'Welcome Customer!';

  @override
  String get welcomeFarmer => 'Welcome Farmer!';

  @override
  String get welcomeDriver => 'Welcome Driver!';

  @override
  String get letsGrowTogether => 'Let\'s grow together';

  @override
  String get logIn => 'Log in';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get emailPhone => 'Email/Phone';

  @override
  String get name => 'Name';

  @override
  String get location => 'Location';

  @override
  String get phone => 'Phone';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get profileCreatedSuccessfully => 'Profile created successfully';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get enterEmail => 'Enter Email';

  @override
  String get enterPassword => 'Enter Password';

  @override
  String get enterName => 'Enter Name';

  @override
  String get enterLocation => 'Enter Location';

  @override
  String get enterPhone => 'Enter Phone';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String pleaseEnterField(Object field) {
    return 'Please enter $field';
  }

  @override
  String get notSpecified => 'Not specified';

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
  String get customerLogin => 'Customer Login';

  @override
  String get driverLogin => 'Driver Login';

  @override
  String get farmerLogin => 'Farmer Login';

  @override
  String get createDriverProfile => 'Create Driver Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get cropDemandTrends => 'Crop Demand Trends';

  @override
  String get ongoingTransactions => 'Ongoing Transactions';

  @override
  String get weekDemandForecast => '4-Week Demand Forecast';

  @override
  String get deliveryGuy => 'Delivery Guy';

  @override
  String get selfDelivery => 'Self Delivery';

  @override
  String get chooseDelivery => 'Choose Delivery';

  @override
  String get addHarvest => 'Add Harvest';

  @override
  String get quantity => 'Quantity';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get pending => 'Pending';

  @override
  String get assigned => 'Assigned';

  @override
  String get inTransit => 'In Transit';

  @override
  String get delivered => 'Delivered';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get farmerDashboard => 'Farmer Dashboard';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noHarvestsYet => 'No harvests yet';

  @override
  String get addFirstHarvest => 'Add your first harvest to get started';

  @override
  String get addHarvestButton => '+ Add Harvest';

  @override
  String get cropName => 'Crop Name';

  @override
  String get expectedQuantity => 'Expected Quantity';

  @override
  String get pricePerKg => 'Price per KG';

  @override
  String get harvestDate => 'Harvest Date';

  @override
  String get description => 'Description';

  @override
  String get saveHarvest => 'Save Harvest';

  @override
  String get myProfile => 'My Profile';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get contactInfo => 'Contact Information';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get viewDetails => 'View Details';

  @override
  String get addNewHarvest => 'Add New Harvest';

  @override
  String get preview => 'Preview';

  @override
  String get submit => 'Submit';

  @override
  String get previewCompleted => 'Preview completed! You can now submit your harvest data.';

  @override
  String get pleasePreviewFirst => 'Please preview your data first before submitting!';

  @override
  String get dataChangedPreviewAgain => 'Data has changed since last preview. Please preview again.';

  @override
  String get pleaseLoginToSubmit => 'Please log in to submit harvest data.';

  @override
  String get harvestSubmittedSuccessfully => 'Harvest data submitted successfully!';

  @override
  String get errorSubmittingHarvest => 'Error submitting harvest data';

  @override
  String get plantingDate => 'Planting Date';

  @override
  String get selectCrop => 'Select Crop';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get errorOccurred => 'Error';

  @override
  String get authError => 'Auth error';
}
