import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'ai_assistant_screen.dart';
import 'fault_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _historyItems = [
    _HistoryItem(
      title: 'Engine Misfire Detected',
      code: 'P0300',
      date: '07 June 2026',
      severity: 'High',
      source: 'OBD2 Scan',
      status: 'Unresolved',
    ),
    _HistoryItem(
      title: 'Catalyst System Efficiency',
      code: 'P0420',
      date: '02 June 2026',
      severity: 'Medium',
      source: 'OBD2 Scan',
      status: 'Reviewed',
    ),
    _HistoryItem(
      title: 'Check Engine Light',
      code: 'Dashboard',
      date: '28 May 2026',
      severity: 'Medium',
      source: 'Camera Scan',
      status: 'Resolved',
    ),
    _HistoryItem(
      title: 'Oil Pressure Warning',
      code: 'Dashboard',
      date: '15 May 2026',
      severity: 'High',
      source: 'Camera Scan',
      status: 'Resolved',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isTabletOrLarger(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Diagnosis History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppBreakpoints.contentMaxWidth(context),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            itemCount: _historyItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _HistoryCard(item: _historyItems[index]);
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final _HistoryItem item;

  Color get _severityColor {
    switch (item.severity) {
      case 'High':
        return AppColors.accent;
      case 'Medium':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (item.code != 'Dashboard') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FaultDetailsScreen(
                    fault: {
                      'code': item.code,
                      'description': item.title,
                      'severity': item.severity,
                      'severityColor': _severityColor,
                    },
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _severityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.source == 'OBD2 Scan'
                            ? Icons.bluetooth_connected_rounded
                            : Icons.camera_alt_rounded,
                        color: _severityColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${item.code} • ${item.date}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(label: item.status, color: _severityColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoTag(
                      icon: Icons.sensors_rounded,
                      label: item.source,
                    ),
                    const SizedBox(width: 8),
                    _InfoTag(
                      icon: Icons.priority_high_rounded,
                      label: item.severity,
                      color: _severityColor,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiAssistantScreen(
                              initialFaultCode: item.code != 'Dashboard'
                                  ? item.code
                                  : null,
                              initialFaultDescription: item.title,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.smart_toy_outlined, size: 18),
                      label: Text(
                        'Ask AI',
                        style: GoogleFonts.poppins(fontSize: 13),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem {
  const _HistoryItem({
    required this.title,
    required this.code,
    required this.date,
    required this.severity,
    required this.source,
    required this.status,
  });

  final String title;
  final String code;
  final String date;
  final String severity;
  final String source;
  final String status;
}
