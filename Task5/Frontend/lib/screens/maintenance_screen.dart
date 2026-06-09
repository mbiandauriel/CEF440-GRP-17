import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: History

  final List<Map<String, dynamic>> _upcomingServices = [
    {
      'title': 'Oil Change',
      'vehicle': 'Toyota Camry',
      'dueDate': '2024-03-15',
      'odometer': '25,000 km',
      'icon': Icons.opacity,
      'color': Colors.blue,
    },
    {
      'title': 'Tire Rotation',
      'vehicle': 'Toyota Camry',
      'dueDate': '2024-03-20',
      'odometer': '25,500 km',
      'icon': Icons.build,
      'color': Colors.orange,
    },
    {
      'title': 'Brake Inspection',
      'vehicle': 'Honda CR-V',
      'dueDate': '2024-03-25',
      'odometer': '45,000 km',
      'icon': Icons.car_repair,
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _serviceHistory = [
    {
      'title': 'Oil Change',
      'vehicle': 'Toyota Camry',
      'date': '2024-01-10',
      'odometer': '20,000 km',
      'cost': 'XAF 45,000',
      'mechanic': 'AutoPro Garage',
    },
    {
      'title': 'Air Filter Replacement',
      'vehicle': 'Toyota Camry',
      'date': '2024-01-10',
      'odometer': '20,000 km',
      'cost': 'XAF 12,000',
      'mechanic': 'AutoPro Garage',
    },
    {
      'title': 'Tire Rotation',
      'vehicle': 'Honda CR-V',
      'date': '2023-12-05',
      'odometer': '40,000 km',
      'cost': 'XAF 8,000',
      'mechanic': 'Speedy Lube',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tracker'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Upcoming', 0),
                ),
                Expanded(
                  child: _buildTabButton('History', 1),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedTab == 0 ? _buildUpcomingTab() : _buildHistoryTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _addServiceRecord();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        backgroundColor: const Color(0xFF1A73E8),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF1A73E8) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return _upcomingServices.isEmpty
        ? _buildEmptyState('No upcoming services', 'All maintenance is up to date!')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _upcomingServices.length,
            itemBuilder: (context, index) {
              final service = _upcomingServices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (service['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service['icon'],
                          color: service['color'],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service['vehicle'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Due: ${service['dueDate']}',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.speed, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  service['odometer'],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Schedule'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildHistoryTab() {
    return _serviceHistory.isEmpty
        ? _buildEmptyState('No service history', 'Add your first service record')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _serviceHistory.length,
            itemBuilder: (context, index) {
              final service = _serviceHistory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  service['vehicle'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                service['date'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                service['cost'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            service['mechanic'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const Spacer(),
                          const Icon(Icons.speed, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            service['odometer'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _addServiceRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddServiceSheet(),
    );
  }
}

class AddServiceSheet extends StatelessWidget {
  const AddServiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Service Record',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Service Type',
              hintText: 'e.g., Oil Change',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Odometer Reading',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Cost',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Mechanic/Garage',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}