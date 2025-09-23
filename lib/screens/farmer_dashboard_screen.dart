import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../services/weather_service.dart';
import '../widgets/weather_forecast_tile.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  final Map<String, List<Map<String, dynamic>>> _weatherData = {};
  String _selectedRange = '1M';

  @override
  void initState() {
    super.initState();
    _loadHarvestsAndWeather();
  }

  Future<void> _loadHarvestsAndWeather() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final harvests = await FirebaseFirestore.instance
          .collection('Ongoing_Trans_Far')
          .doc(userId)
          .get();

      if (!harvests.exists) return;

      final harvestData = harvests.data()?['transactions'] as List<dynamic>?;
      if (harvestData == null) return;

      for (var harvest in harvestData) {
        // Get weather data for each harvest
        try {
          final weatherForecast = await _weatherService.get5DayForecast(
            harvest['Location']['latitude'] ?? 0.0,
            harvest['Location']['longitude'] ?? 0.0,
          );

          final processedForecast = _weatherService.process7DayForecast(weatherForecast);
          
          setState(() {
            _weatherData[harvest['Transaction ID']] = processedForecast;
          });
        } catch (e) {
          print('Error fetching weather for harvest: $e');
        }
      }
    } catch (e) {
      print('Error loading harvests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          AppLocalizations.of(context)!.farmerDashboard,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _GlassIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
          )
        ],
      ),
      floatingActionButton: _GlassFab(
        label: '+ Add Harvest',
        onTap: () => Navigator.pushNamed(context, '/addHarvest'),
      ),
      body: Stack(
        children: [
          // Full screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/green_leaves_051.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent white overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          // Content
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filters row similar to finance apps
                    Row(
                      children: [
                        _RangeChip(label: '1W', selected: _selectedRange == '1W', onTap: () => setState(() => _selectedRange = '1W')),
                        const SizedBox(width: 8),
                        _RangeChip(label: '1M', selected: _selectedRange == '1M', onTap: () => setState(() => _selectedRange = '1M')),
                        const SizedBox(width: 8),
                        _RangeChip(label: '3M', selected: _selectedRange == '3M', onTap: () => setState(() => _selectedRange = '3M')),
                        const SizedBox(width: 8),
                        _RangeChip(label: '1Y', selected: _selectedRange == '1Y', onTap: () => setState(() => _selectedRange = '1Y')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Crop Demand Trends Section with green accent
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Color(0xFF02C697), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.cropDemandTrends,
                          style: const TextStyle(
                            color: Color(0xFF02C697),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Horizontally scrollable glassy cards
                    Container(
                      height: 200,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: [
                          _ModernDemandCard(
                            crop: 'Tomato',
                            subtitle: '4-Week Demand Forecast',
                            spark: _demoSeries('Tomato', _selectedRange),
                            avgPercentage: 78,
                          ),
                          const SizedBox(width: 16),
                          _ModernDemandCard(
                            crop: 'Carrot',
                            subtitle: '4-Week Demand Forecast',
                            spark: _demoSeries('Carrot', _selectedRange),
                            avgPercentage: 76,
                          ),
                          const SizedBox(width: 16),
                          _ModernDemandCard(
                            crop: 'Brinjal',
                            subtitle: '4-Week Demand Forecast',
                            spark: _demoSeries('Brinjal', _selectedRange),
                            avgPercentage: 64,
                          ),
                          const SizedBox(width: 16),
                          _ModernDemandCard(
                            crop: 'Beans',
                            subtitle: '4-Week Demand Forecast',
                            spark: _demoSeries('Beans', _selectedRange),
                            avgPercentage: 82,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Color(0xFF02C697), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.ongoingTransactions,
                          style: const TextStyle(
                            color: Color(0xFF02C697),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Ongoing_Trans_Far')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text(AppLocalizations.of(context)!.somethingWentWrong, style: const TextStyle(color: Colors.white)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        if (data == null || !data.containsKey('transactions')) {
                          return _EmptyState();
                        }
                        final transactions = List<Map<String, dynamic>>.from(data['transactions']);

                        return Column(
                          children: [
                            for (final harvest in transactions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GlassCard(
                                  child: _TransactionTile(
                                    harvest: harvest,
                                    weatherFirst: (_weatherData[harvest['Transaction ID']] ?? const []) .cast<Map<String, dynamic>?>().whereType<Map<String, dynamic>>().cast<Map<String, dynamic>>().isNotEmpty
                                        ? _weatherData[harvest['Transaction ID']]!.first
                                        : null,
                                    getIcon: (cond) => _weatherService.getWeatherIcon(cond),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create demo series for the chart cards
  List<FlSpot> _demoSeries(String crop, String range) {
    final base = {
      'Tomato': [1.0, 1.6, 1.4, 1.9, 2.2, 2.0, 2.6, 2.3],
      'Carrot': [1.2, 1.1, 1.5, 1.7, 1.6, 1.8, 2.1, 2.4],
      'Brinjal': [0.8, 1.0, 1.2, 1.1, 1.5, 1.7, 1.6, 1.9],
      'Beans': [0.9, 1.2, 1.1, 1.6, 1.8, 1.7, 2.0, 2.2],
    }[crop] ?? [1, 1.2, 1.1, 1.3, 1.5, 1.4, 1.7, 1.9];

    int take = switch (range) { '1W' => 7, '1M' => 8, '3M' => 8, '1Y' => 8, _ => 8 };
    final used = base.take(take).toList();
    return [for (int i = 0; i < used.length; i++) FlSpot(i.toDouble(), used[i].toDouble())];
  }
}

// ===================== UI pieces =====================

class _BackgroundImage extends StatelessWidget {
  final String primary;
  final String fallback;
  const _BackgroundImage({required this.primary, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      primary,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected 
                ? const Color(0xFF02C697).withOpacity(0.3)
                : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected 
                  ? const Color(0xFF02C697).withOpacity(0.5)
                  : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF02C697) : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernDemandCard extends StatelessWidget {
  final String crop;
  final String subtitle;
  final List<FlSpot> spark;
  final int avgPercentage;
  
  const _ModernDemandCard({
    required this.crop,
    required this.subtitle,
    required this.spark,
    required this.avgPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF02C697).withOpacity(0.15),
                  const Color(0xFF4CAF50).withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF02C697).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF02C697).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop name
                Text(
                  crop,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20), // Dark green
                  ),
                ),
                const SizedBox(height: 4),
                
                // Subtitle
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF2E7D32).withOpacity(0.8), // Medium green
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Line chart
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: spark.first.x,
                      maxX: spark.last.x,
                      minY: spark.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.2,
                      maxY: spark.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spark,
                          isCurved: true,
                          barWidth: 3,
                          color: const Color(0xFF02C697),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFF4CAF50), // Green stroke
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF4CAF50).withOpacity(0.4), // Light green
                                const Color(0xFF81C784).withOpacity(0.1), // Very light green
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Average percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Avg: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF2E7D32).withOpacity(0.8), // Medium green
                      ),
                    ),
                    Text(
                      '$avgPercentage%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20), // Dark green
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  final String crop;
  final Color color;
  final List<FlSpot> spark;
  const _DemandCard({required this.crop, required this.color, required this.spark});

  @override
  Widget build(BuildContext context) {
    final avg = (spark.map((e) => e.y).fold(0.0, (a, b) => a + b) / spark.length);
    return SizedBox(
      width: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crop, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: spark.first.x,
                      maxX: spark.last.x,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spark,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.white,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.cyanAccent.withOpacity(0.35),
                                color.withOpacity(0.05),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('${(avg * 12).toStringAsFixed(1)}% avg', style: TextStyle(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> harvest;
  final Map<String, dynamic>? weatherFirst;
  final IconData Function(String) getIcon;
  const _TransactionTile({required this.harvest, required this.weatherFirst, required this.getIcon});

  @override
  Widget build(BuildContext context) {
    final crop = harvest['Crop'] ?? 'Unknown Crop';
    final qty = (harvest['Quantity Sold (1kg)'] ?? 0).toString();
    final date = harvest['Date'] != null
        ? (harvest['Date'] as Timestamp).toDate().toString().split(' ')[0]
        : 'No date';
    final status = (harvest['Status'] ?? 'Pending').toString();
    final customer = (harvest['Customer Name'] ?? 'Customer').toString();
    final contact = (harvest['Customer Contact'] ?? '').toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: const Icon(Icons.local_florist, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(crop, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _InfoChip(icon: Icons.scale, label: '$qty kg'),
                  _InfoChip(icon: Icons.event, label: date),
                  if (customer.isNotEmpty) _InfoChip(icon: Icons.person_outline, label: customer),
                  if (contact.isNotEmpty) _InfoChip(icon: Icons.call, label: contact),
                  if (weatherFirst != null)
                    _InfoChip(
                      icon: getIcon((weatherFirst!['condition'] ?? '').toString()),
                      label: '${(weatherFirst!['temp'] as num?)?.toStringAsFixed(1) ?? '--'}°C',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status.toLowerCase()) {
      case 'in transit':
        c = Colors.orangeAccent;
        break;
      case 'delivered':
        c = Colors.greenAccent;
        break;
      case 'pending':
      default:
        c = Colors.tealAccent;
    }
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w700)),
    );
  }
}

class _GlassFab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GlassFab({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.18),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.addHarvestButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.eco, size: 64, color: Colors.white.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noHarvestsYet, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.addFirstHarvest, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}
