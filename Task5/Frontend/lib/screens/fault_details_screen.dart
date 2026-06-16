import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/youtube_links.dart';
import '../models/dtc_record.dart';
import '../services/openrouter_service.dart';
import '../services/vehicle_profile_service.dart';
import 'ai_assistant_screen.dart';

class FaultDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> fault;

  const FaultDetailsScreen({super.key, required this.fault});

  @override
  State<FaultDetailsScreen> createState() => _FaultDetailsScreenState();
}

class _FaultDetailsScreenState extends State<FaultDetailsScreen> {
  bool _isLoadingAi = true;
  String _aiExplanation = '';
  List<String> _suggestedActions = [];
  String _estimatedCost = 'Loading...';
  String? _aiError;
  late String _severity;
  late Color _severityColor;

  DtcRecord? get _dtcRecord => widget.fault['dtcRecord'] as DtcRecord?;

  @override
  void initState() {
    super.initState();
    _severity = widget.fault['severity'] as String? ?? 'Medium';
    _severityColor =
        widget.fault['severityColor'] as Color? ?? Colors.orange;
    _loadAiAnalysis();
  }

  Future<void> _loadAiAnalysis() async {
    final record = _dtcRecord;
    if (record == null) {
      setState(() {
        _isLoadingAi = false;
        _aiExplanation =
            'This diagnostic trouble code indicates a potential issue with your vehicle. '
            'Consult a professional mechanic for accurate diagnosis.';
        _suggestedActions = const [
          'Connect professional diagnostic tool for detailed scan',
          'Check related components visually',
          'Clear code and test drive to verify if issue persists',
          'Consult a certified mechanic',
        ];
        _estimatedCost = 'Varies — get quote from mechanic';
      });
      return;
    }

    try {
      final analysis = await OpenRouterService.instance.analyzeFault(
        record: record,
        vehicleDisplayName:
            VehicleProfileService.instance.profile.displayName,
      );
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
        _aiExplanation = analysis.explanation;
        _suggestedActions = analysis.suggestedActions;
        _estimatedCost = analysis.estimatedCost;
        _severity = analysis.severity;
        _severityColor = _severityColorFor(analysis.severity);
      });
    } on OpenRouterException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
        _aiError = e.message;
        _aiExplanation = _fallbackExplanation(widget.fault['code'] as String);
        _suggestedActions = _fallbackActions(widget.fault['code'] as String);
        _estimatedCost = _fallbackCost(widget.fault['code'] as String);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAi = false;
        _aiError = e.toString();
        _aiExplanation = _fallbackExplanation(widget.fault['code'] as String);
        _suggestedActions = _fallbackActions(widget.fault['code'] as String);
        _estimatedCost = _fallbackCost(widget.fault['code'] as String);
      });
    }
  }

  Color _severityColorFor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red.shade900;
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openYoutube() async {
    final url = youtubeUrlForCode(widget.fault['code'] as String);
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fault = widget.fault;
    final code = fault['code'] as String;
    final hasYoutube = hasYoutubeTutorial(code);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fault Code: $code'),
        backgroundColor: _severityColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _severityColor),
                ),
                child: Text(
                  'Severity: $_severity',
                  style: TextStyle(
                    color: _severityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                      code,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _severityColor,
                      ),
                    ),
                    if (_dtcRecord != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_dtcRecord!.typeLabel} • ${_dtcRecord!.manufacturer}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      fault['description'] as String,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF1A73E8)),
                        const SizedBox(width: 8),
                        Text(
                          'AI Explanation',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A73E8),
                          ),
                        ),
                        if (_isLoadingAi) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    if (_aiError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _aiError!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _isLoadingAi ? 'Analyzing fault with AI...' : _aiExplanation,
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    ..._suggestedActions.map(
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
                      _estimatedCost,
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
                            initialFaultCode: code,
                            initialFaultDescription:
                                fault['description'] as String,
                            faultRecord: _dtcRecord,
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
            if (hasYoutube) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openYoutube,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch Tutorial on YouTube'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fallbackExplanation(String code) {
    if (code == 'P0300') {
      return 'This fault code indicates that your engine is misfiring in multiple cylinders.';
    } else if (code == 'P0420') {
      return 'This code suggests your catalytic converter is not working efficiently.';
    }
    return 'This diagnostic trouble code indicates a potential issue with your vehicle.';
  }

  List<String> _fallbackActions(String code) {
    if (code == 'P0300') {
      return const [
        'Replace spark plugs and ignition coils',
        'Check fuel injectors for clogging',
        'Inspect for vacuum leaks',
      ];
    } else if (code == 'P0420') {
      return const [
        'Check oxygen sensors for proper operation',
        'Inspect catalytic converter for damage',
        'Check for exhaust system leaks',
      ];
    }
    return const [
      'Check related components visually',
      'Consult a certified mechanic',
    ];
  }

  String _fallbackCost(String code) {
    if (code == 'P0300') return 'XAF 75,000 - 200,000';
    if (code == 'P0420') return 'XAF 250,000 - 600,000';
    return 'Varies — get quote from mechanic';
  }
}
