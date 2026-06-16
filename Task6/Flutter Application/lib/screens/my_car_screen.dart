import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/dtc_database_service.dart';
import '../services/vehicle_profile_service.dart';
import '../theme/app_theme.dart';

class MyCarScreen extends StatefulWidget {
  const MyCarScreen({super.key});

  @override
  State<MyCarScreen> createState() => _MyCarScreenState();
}

class _MyCarScreenState extends State<MyCarScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = VehicleProfileService.instance.profile;
    final isWide = AppBreakpoints.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Car'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVehicleCard(context, profile),
                const SizedBox(height: 20),
                Text(
                  'Vehicle Health',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHealthGrid(isWide),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(isWide),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plate: ${profile.plate} • ${profile.odometerKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} km',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Manufacturer: ${profile.manufacturer}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
            onPressed: () => _showEditVehicleDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVehicleDialog(BuildContext context) async {
    final profile = VehicleProfileService.instance.profile;
    final manufacturers =
        await DtcDatabaseService.instance.getManufacturers();

    if (!context.mounted) return;

    final updated = await showDialog<VehicleProfile>(
      context: context,
      builder: (dialogContext) => _EditVehicleDialog(
        profile: profile,
        manufacturers: manufacturers,
      ),
    );

    if (updated != null && mounted) {
      await VehicleProfileService.instance.save(updated);
      setState(() {});
    }
  }

  Widget _buildHealthGrid(bool isWide) {
    final items = [
      _HealthItem('Engine', 'Good', Icons.settings_rounded, Color(0xFF43A047)),
      _HealthItem('Battery', '85%', Icons.battery_charging_full_rounded,
          Color(0xFF1A73E8)),
      _HealthItem('Brakes', 'Check Soon', Icons.disc_full_rounded,
          Color(0xFFF57C00)),
      _HealthItem('Tires', 'Good', Icons.tire_repair_rounded, Color(0xFF43A047)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.4 : 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.color, size: 28),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                item.value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(bool isWide) {
    final actions = [
      _QuickAction('Service Log', Icons.history_edu_rounded),
      _QuickAction('Documents', Icons.description_rounded),
      _QuickAction('Reminders', Icons.alarm_rounded),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(action.icon, color: AppColors.primary, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HealthItem {
  const _HealthItem(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _QuickAction {
  const _QuickAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _EditVehicleDialog extends StatefulWidget {
  const _EditVehicleDialog({
    required this.profile,
    required this.manufacturers,
  });

  final VehicleProfile profile;
  final List<String> manufacturers;

  @override
  State<_EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<_EditVehicleDialog> {
  late String _selectedManufacturer;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;

  @override
  void initState() {
    super.initState();
    _selectedManufacturer = widget.manufacturers
            .contains(widget.profile.manufacturer)
        ? widget.profile.manufacturer
        : widget.manufacturers.first;
    _modelController = TextEditingController(text: widget.profile.model);
    _yearController =
        TextEditingController(text: widget.profile.year.toString());
    _plateController = TextEditingController(text: widget.profile.plate);
  }

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _save() {
    final year =
        int.tryParse(_yearController.text.trim()) ?? widget.profile.year;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        manufacturer: _selectedManufacturer,
        model: _modelController.text.trim(),
        year: year,
        plate: _plateController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Vehicle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedManufacturer,
              decoration: const InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(),
              ),
              items: widget.manufacturers
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedManufacturer = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Plate',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
