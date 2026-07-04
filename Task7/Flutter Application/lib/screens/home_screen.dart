import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ai_assistant_screen.dart';
import 'maintenance_screen.dart' as maintenance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onScanTap,
    required this.onNavigateToTab,
  });

  final VoidCallback onScanTap;
  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselController = PageController(viewportFraction: 0.82);
  int _carouselIndex = 0;

  static const _brands = [
    _BrandData('Toyota', Color(0xFFEB0A1E), '+10'),
    _BrandData('Mercedes', Color(0xFF242424), '+32'),
    _BrandData('BMW', Color(0xFF0066B1), '+15'),
    _BrandData('Honda', Color(0xFFE40521), '+8'),
    _BrandData('Audi', Color(0xFFBB0A30), '+12'),
  ];

  static const _services = [
    _ServiceData(
      title: 'Full Vehicle Inspection',
      description:
          'The fault of the car will be scanned with the scanner below.',
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFFC62828),
    ),
    _ServiceData(
      title: 'OBD2 Fault Scan',
      description:
          'Connect your OBD2 adapter to read and interpret diagnostic codes.',
      icon: Icons.bluetooth_connected_rounded,
      color: Color(0xFF1565C0),
    ),
    _ServiceData(
      title: 'Dashboard Warning Scan',
      description:
          'Scan your dashboard warning lights using your phone camera.',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFF2E7D32),
    ),
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final isWide = AppBreakpoints.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 32 : 16,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActionCards(context, isWide),
                            const SizedBox(height: 24),
                            _buildBrandSection(isWide),
                            const SizedBox(height: 28),
                            _buildServiceCarousel(isWide),
                            const SizedBox(height: 24),
                          ],
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          Expanded(
            child: Text(
              'Welcome!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, bool isWide) {
    final aiCard = _ActionCard(
      icon: Icons.smart_toy_outlined,
      title: 'Ask AI Assistant',
      buttonLabel: 'To AI Chat',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        );
      },
    );
    final checkupCard = _ActionCard(
      icon: Icons.calendar_month_rounded,
      title: 'Next Checkup on',
      subtitle: '09 June 2026',
      buttonLabel: 'Tap to see more',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const maintenance.MaintenanceScreen(),
          ),
        );
      },
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: aiCard),
          const SizedBox(width: 16),
          Expanded(child: checkupCard),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: aiCard),
        const SizedBox(width: 12),
        Expanded(child: checkupCard),
      ],
    );
  }

  Widget _buildBrandSection(bool isWide) {
    final cardWidth = isWide ? 110.0 : 90.0;
    final cardHeight = isWide ? 150.0 : 130.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Brands',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _brands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final brand = _brands[index];
              return _BrandCard(
                brand: brand,
                width: cardWidth,
                height: cardHeight,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCarousel(bool isWide) {
    final carouselHeight = isWide ? 320.0 : 280.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diagnostic Services',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _services.length,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemBuilder: (context, index) {
              final service = _services[index];
              final isActive = index == _carouselIndex;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 250),
                child: _ServiceCarouselCard(
                  service: service,
                  onTap: widget.onScanTap,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _services.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _carouselIndex == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _carouselIndex == i
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.car_repair_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  'CAFAD',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Car Fault Diagnosis',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _drawerTile(Icons.home_rounded, 'Home', () {
            Navigator.pop(context);
            widget.onNavigateToTab(0);
          }),
          _drawerTile(Icons.history_rounded, 'History', () {
            Navigator.pop(context);
            widget.onNavigateToTab(1);
          }),
          _drawerTile(Icons.sensors_rounded, 'Scan Vehicle', () {
            Navigator.pop(context);
            widget.onScanTap();
          }),
          _drawerTile(Icons.smart_toy_outlined, 'AI Assistant', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
            );
          }),
          _drawerTile(Icons.build_rounded, 'My Car', () {
            Navigator.pop(context);
            widget.onNavigateToTab(3);
          }),
          _drawerTile(Icons.person_rounded, 'Profile', () {
            Navigator.pop(context);
            widget.onNavigateToTab(4);
          }),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: AppColors.textPrimary),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.width,
    required this.height,
  });

  final _BrandData brand;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brand.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_filled_rounded,
              color: brand.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            brand.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            brand.count,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCarouselCard extends StatelessWidget {
  const _ServiceCarouselCard({
    required this.service,
    required this.onTap,
  });

  final _ServiceData service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      service.color.withValues(alpha: 0.15),
                      service.color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  service.icon,
                  size: 80,
                  color: service.color,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandData {
  const _BrandData(this.name, this.color, this.count);
  final String name;
  final Color color;
  final String count;
}

class _ServiceData {
  const _ServiceData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
