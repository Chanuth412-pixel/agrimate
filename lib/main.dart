import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase initialization options

// Import all the screens for routing
import 'screens/create_farmer_profile_screen.dart';
import 'screens/create_customer_profile_screen.dart';
import 'screens/farmer_profile_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/farmer_log_in_screen.dart';
import 'screens/customer_log_in_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/add_harvest_screen.dart';
import 'screens/add_crop_customer_c1.dart';
import 'screens/splash_screen.dart'; // Splash screen
import 'screens/driver_profile_screen.dart'; // Import the Driver Profile Screen
import 'screens/driver_log_in_screen.dart'; // Add this import if missing
import 'screens/scheduled_orders_screen.dart'; // Import the new scheduled orders screen
import 'screens/ongoing_transactions_screen.dart'; // Import the ongoing transactions screen
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/create_driver_profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('DEBUG: .env file loaded successfully');
    print('DEBUG: OPENAI_API_KEY exists: ${dotenv.env['OPENAI_API_KEY']?.isNotEmpty == true}');
    print('DEBUG: OPENWEATHER_API_KEY exists: ${dotenv.env['OPENWEATHER_API_KEY']?.isNotEmpty == true}');
    
    // Validate required environment variables
    if (dotenv.env['OPENAI_API_KEY']?.isEmpty ?? true) {
      print('WARNING: OPENAI_API_KEY is missing or empty in .env file');
    }
    if (dotenv.env['OPENWEATHER_API_KEY']?.isEmpty ?? true) {
      print('WARNING: OPENWEATHER_API_KEY is missing or empty in .env file');
    }
  } catch (e) {
    print('ERROR: Failed to load .env file: $e');
  }

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleProvider(
      setLocale: setLocale,
      child: MaterialApp(
        title: 'Agrimate',
        theme: ThemeData(
          useMaterial3: true, // Enable Material 3
          colorSchemeSeed: const Color(0xFF02C697),
          fontFamily: 'SFProDisplay',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 32),
            displayMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 28),
            displaySmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 24),
            headlineLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 22),
            headlineMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 20),
            headlineSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 18),
            titleLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.bold, fontSize: 20),
            titleMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w600, fontSize: 18),
            titleSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 16),
            bodyLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.normal, fontSize: 16),
            bodyMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.normal, fontSize: 14),
            bodySmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w300, fontSize: 12),
            labelLarge: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w500, fontSize: 14),
            labelMedium: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w400, fontSize: 12),
            labelSmall: TextStyle(fontFamily: 'SFProDisplay', fontWeight: FontWeight.w300, fontSize: 10),
          ),
        ),
        locale: _locale,
        initialRoute: '/',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('si'),
        ],
        routes: {
          '/': (context) => const SplashScreen(),
          '/createFarmerProfile': (context) => CreateFarmerProfileScreen(),
          '/createCustomerProfile': (context) => CreateCustomerProfileScreen(),
          '/createDriverProfile': (context) => CreateDriverProfileScreen(),
          '/farmerProfile': (context) => const FarmerProfileScreen(),
          '/addHarvest': (context) => const AddHarvestScreen(),
          '/customerProfile': (context) => const CustomerProfileScreen(),
          '/farmerLogIn': (context) => const FarmerLogInScreen(),
          '/customerLogIn': (context) => const CustomerLogInScreen(),
          '/driverLogIn': (context) => const DriverLogInScreen(),
          '/driverProfile': (context) => const DriverProfileScreen(),
          '/farmerSelection': (context) => const RoleSelectionScreen(),
          '/customerSelection': (context) => const RoleSelectionScreen(),
          '/roleSelection': (context) => const RoleSelectionScreen(),
          '/scheduledOrders': (context) => const ScheduledOrdersScreen(),
          '/ongoingTransactions': (context) => const OngoingTransactionsScreen(),
        },
        // Remove onGenerateRoute logic for /driverProfile
        onGenerateRoute: (settings) {
          return null; // Unknown route
        },
      ),
    );
  }
}

class AppLocaleProvider extends InheritedWidget {
  final void Function(Locale) setLocale;

  const AppLocaleProvider({
    required this.setLocale,
    required Widget child,
  }) : super(child: child);

  static AppLocaleProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocaleProvider>();

  @override
  bool updateShouldNotify(AppLocaleProvider oldWidget) => false;
}
