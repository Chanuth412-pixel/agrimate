import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show AppLocaleProvider;
import 'customer_profile_screen.dart';
import 'farmer_profile_screen.dart';
import 'driver_profile_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> with TickerProviderStateMixin {
  // Keep a simple fade-in for page elements
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();

    // Fade-in animation for the page
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the fade animation when the screen loads
    _fadeController.forward();
  }

  _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      setState(() {
        _selectedLocale = Locale(languageCode);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??= Localizations.localeOf(context);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onFarmerButtonPressed() {
    Navigator.pushNamed(context, '/farmerLogIn');
  }

  void _onCustomerButtonPressed() {
    Navigator.pushNamed(context, '/customerLogIn');
  }

  void _onDriverButtonPressed() {  // Handle driver button press
    Navigator.pushNamed(context, '/driverLogIn');
  }

  void _changeLanguage(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    
    setState(() {
      _selectedLocale = locale;
    });
    
    AppLocaleProvider.of(context)?.setLocale(locale);
  }

  String _getLanguageDisplayName() {
    final currentLocale = _selectedLocale ?? Localizations.localeOf(context);
    switch (currentLocale.languageCode) {
      case 'si':
        return 'සිංහල';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildLanguageOption('English', const Locale('en')),
              _buildLanguageOption('සිංහල', const Locale('si')),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String languageName, Locale locale) {
    final currentLocale = _selectedLocale ?? Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () {
        _changeLanguage(locale);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Text(
              languageName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const greenDark = Color(0xFF2E7D32);
    const gradientTop = Color(0xFFDFFFD6); // #dfffd6
    const gradientBottom = Color(0xFFC0F7B0); // #c0f7b0

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Greenery gradient background
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gradientTop, gradientBottom],
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.chooseYourRole,
                    style: const TextStyle(
                      color: greenDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.selectRoleDescription,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.farmer,
                    description: AppLocalizations.of(context)!.farmerDescription,
                    imageAsset: 'assets/images/farmer.jpg',
                    gradientColors: const [Colors.transparent, Colors.transparent],
                    onSelect: _onFarmerButtonPressed,
                  ),
                  const SizedBox(height: 16),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.customer,
                    description: AppLocalizations.of(context)!.customerDescription,
                    imageAsset: 'assets/images/customer.jpg',
                    gradientColors: const [Colors.transparent, Colors.transparent],
                    onSelect: _onCustomerButtonPressed,
                  ),
                  const SizedBox(height: 16),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.driver,
                    description: AppLocalizations.of(context)!.driverDescription,
                    imageAsset: 'assets/images/Driver.jpg',
                    gradientColors: const [Colors.transparent, Colors.transparent],
                    onSelect: _onDriverButtonPressed,
                  ),
                  const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            // Modern Language selection button at the top right (painted last to stay tappable)
            Positioned(
              right: 16,
              top: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _showLanguageBottomSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language, color: greenDark, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _getLanguageDisplayName(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;
  final List<Color> gradientColors;
  final VoidCallback onSelect;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.gradientColors,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const greenDark = Color(0xFF2E7D32);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          decoration: BoxDecoration(
            // Translucent gradient to enhance glass effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Highlight overlay for specular shine
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                  ),
                ),
              ),
              // Content row
              Row(
                children: [
                  // Left: text + button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: onSelect,
                                child: Text(
                                  AppLocalizations.of(context)!.selectRole,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right: circular image
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withOpacity(0.28),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                            ),
                            // Green tint overlay for a greener glass look (increased opacity to dim more)
                            Container(color: const Color(0xFF2E7D32).withOpacity(0.32)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

