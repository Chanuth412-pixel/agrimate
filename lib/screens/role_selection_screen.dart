import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show AppLocaleProvider;

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

  void _changeLanguage(Locale locale) {
    AppLocaleProvider.of(context)?.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            // Language selection dropdown at the top right
            Positioned(
              right: 16,
              top: 8,
              child: DropdownButton<Locale>(
                value: _selectedLocale ?? Localizations.localeOf(context),
                icon: const Icon(Icons.language),
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('si'), child: Text('සිංහල')),
                ],
                onChanged: (locale) {
                  if (locale != null) _changeLanguage(locale);
                },
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
                    'Choose your role',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a role to continue. You can change this later in settings.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.farmer,
                    description: 'Manage harvests, weather insights and orders.',
                    imageAsset: 'assets/images/Farmer.jpg',
                    gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // purple
                    onSelect: _onFarmerButtonPressed,
                  ),
                  const SizedBox(height: 16),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.customer,
                    description: 'Browse fresh produce and place orders.',
                    imageAsset: 'assets/images/Customer.jpg',
                    gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)], // green
                    onSelect: _onCustomerButtonPressed,
                  ),
                  const SizedBox(height: 16),

                  _RoleCard(
                    title: AppLocalizations.of(context)!.driver,
                    description: 'Deliver orders and view schedules.',
                    imageAsset: 'assets/images/Driver.jpg',
                    gradientColors: const [Color(0xFF06BEB6), Color(0xFF48B1BF)], // teal
                    onSelect: _onDriverButtonPressed,
                  ),
                  const SizedBox(height: 8),
                    ],
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
    return Container(
      height: 118,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: text + button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: onSelect,
                      child: const Text(
                        'Select Role',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
              radius: 48,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: AssetImage(imageAsset),
            ),
          ),
        ],
      ),
    );
  }
}

