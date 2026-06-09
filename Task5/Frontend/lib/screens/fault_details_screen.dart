import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_assistant_screen.dart';

class FaultDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> fault;

  const FaultDetailsScreen({super.key, required this.fault});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fault Code: ${fault['code']}'),
        backgroundColor: fault['severityColor'],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: (fault['severityColor'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fault['severityColor']),
                ),
                child: Text(
                  'Severity: ${fault['severity']}',
                  style: TextStyle(
                    color: fault['severityColor'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Fault Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fault Code',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fault['code'],
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: fault['severityColor'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fault['description'],
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // AI Explanation
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF1A73E8)),
                        const SizedBox(width: 8),
                        Text(
                          'AI Explanation',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A73E8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getAIExplanation(fault['code']),
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Suggested Actions
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Suggested Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._getSuggestedActions(fault['code']).map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(action)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Repair Cost Estimate
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Estimated Repair Cost',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getEstimatedCost(fault['code']),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    label: const Text('Find Mechanics'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiAssistantScreen(
                            initialFaultCode: fault['code'] as String,
                            initialFaultDescription:
                                fault['description'] as String,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Ask AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch Tutorial on YouTube'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAIExplanation(String code) {
    if (code == 'P0300') {
      return 'This fault code indicates that your engine is misfiring in multiple cylinders. This means the engine is not burning fuel properly in one or more cylinders. Common causes include faulty spark plugs, ignition coils, fuel injectors, or vacuum leaks.';
    } else if (code == 'P0420') {
      return 'This code suggests your catalytic converter is not working efficiently. The catalytic converter reduces harmful emissions. This could be due to a failing converter, oxygen sensor issues, or exhaust leaks.';
    }
    return 'This diagnostic trouble code indicates a potential issue with your vehicle. AI analysis suggests checking related components and consulting a professional mechanic for accurate diagnosis.';
  }

  List<String> _getSuggestedActions(String code) {
    if (code == 'P0300') {
      return [
        'Replace spark plugs and ignition coils',
        'Check fuel injectors for clogging',
        'Inspect for vacuum leaks',
        'Perform compression test on cylinders',
      ];
    } else if (code == 'P0420') {
      return [
        'Check oxygen sensors for proper operation',
        'Inspect catalytic converter for damage',
        'Check for exhaust system leaks',
        'Use catalytic converter cleaner as temporary solution',
      ];
    }
    return [
      'Connect professional diagnostic tool for detailed scan',
      'Check related components visually',
      'Clear code and test drive to verify if issue persists',
      'Consult a certified mechanic',
    ];
  }

  String _getEstimatedCost(String code) {
    if (code == 'P0300') {
      return 'XAF 75,000 - 200,000';
    } else if (code == 'P0420') {
      return 'XAF 250,000 - 600,000';
    }
    return 'Varies - Get quote from mechanic';
  }
}