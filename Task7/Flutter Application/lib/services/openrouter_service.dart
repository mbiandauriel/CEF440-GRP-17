import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/dtc_record.dart';

class FaultAnalysis {
  const FaultAnalysis({
    required this.explanation,
    required this.suggestedActions,
    required this.estimatedCost,
    required this.severity,
  });

  final String explanation;
  final List<String> suggestedActions;
  final String estimatedCost;
  final String severity;

  factory FaultAnalysis.fromJson(Map<String, dynamic> json) {
    final actions = json['suggested_actions'];
    return FaultAnalysis(
      explanation: json['explanation'] as String? ?? '',
      suggestedActions: actions is List
          ? actions.map((e) => e.toString()).toList()
          : const [],
      estimatedCost: json['estimated_cost'] as String? ?? 'Varies',
      severity: json['severity'] as String? ?? 'Medium',
    );
  }
}

class OpenRouterService {
  OpenRouterService._();

  static final OpenRouterService instance = OpenRouterService._();

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<List<DashboardDetection>> analyzeDashboardImage({
    required List<int> imageBytes,
  }) async {
    if (!AppConfig.hasOpenRouterKey) {
      throw OpenRouterException(
        'OpenRouter API key not configured. Add OPENROUTER_API_KEY to your .env file.',
      );
    }

    final imageBase64 = base64Encode(imageBytes);
    final payload = {
      'model': AppConfig.openRouterVisionModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an automotive dashboard warning interpreter. '
                  'Analyze the image and detect dashboard warning indicators. '
                  'Return ONLY valid JSON with this schema: '
                  '{"detections":[{"fault_code":"P0300 or null","warning_name":"string","description":"string","severity":"Low|Medium|High|Critical","confidence":0.0}]} '
                  'If exact DTC is unknown, return null for fault_code and still provide warning_name/description/severity.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Extract dashboard warning symbols and infer likely OBD-II fault code when possible.',
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
            },
          ],
        },
      ],
      'max_tokens': 500,
      'temperature': 0.1,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://cafad.app',
        'X-Title': 'CAFAD Car Fault Diagnosis',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw OpenRouterException(
        'Vision scan failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      return const [];
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      return const [];
    }

    try {
      final cleaned =
          content.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final detections = parsed['detections'] as List<dynamic>? ?? const [];
      return detections
          .whereType<Map<String, dynamic>>()
          .map(DashboardDetection.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<FaultAnalysis> analyzeFault({
    required DtcRecord record,
    required String vehicleDisplayName,
  }) async {
    final systemPrompt = '''
You are a professional automotive diagnostic technician for the CAFAD app.
Respond ONLY with valid JSON (no markdown fences) using this schema:
{
  "explanation": "2-4 sentences in plain language for a car owner",
  "suggested_actions": ["action 1", "action 2", "action 3", "action 4"],
  "estimated_cost": "XAF min - XAF max range in Central African CFA francs",
  "severity": "Low|Medium|High|Critical"
}
Be practical, safety-conscious, and specific to the fault and vehicle.
''';

    final userPrompt = '''
Vehicle: $vehicleDisplayName
Fault code: ${record.code}
Code type: ${record.type} (${record.typeLabel})
Manufacturer context: ${record.manufacturer}
Is generic code: ${record.isGeneric ? 'Yes' : 'No'}
Official description: ${record.description}

Provide a clear diagnosis summary for the driver.
''';

    final content = await _chat(
      systemPrompt: systemPrompt,
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: 600,
    );

    return _parseFaultAnalysis(content);
  }

  Future<String> chat({
    required List<Map<String, String>> messages,
    DtcRecord? faultRecord,
    String? vehicleDisplayName,
  }) async {
    final context = faultRecord != null
        ? '''
Active fault: ${faultRecord.code} — ${faultRecord.description}
Vehicle: ${vehicleDisplayName ?? 'Unknown'}
Code type: ${faultRecord.type} (${faultRecord.typeLabel})
Manufacturer-specific: ${faultRecord.isGeneric ? 'No (generic)' : 'Yes (${faultRecord.manufacturer})'}
'''
        : 'No active fault code. Help the user with general car diagnostic questions.';

    final systemPrompt = '''
You are the CAFAD AI technician — a knowledgeable, calm, and professional auto repair guide.
Explain faults in plain language. Prioritize driver safety. Give practical next steps.
Use XAF (Central African CFA francs) when discussing costs.
Keep responses concise (2-5 short paragraphs max).

Diagnostic context:
$context
''';

    return _chat(
      systemPrompt: systemPrompt,
      messages: messages,
      maxTokens: 500,
    );
  }

  Future<String> _chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    int maxTokens = 500,
  }) async {
    if (!AppConfig.hasOpenRouterKey) {
      throw OpenRouterException(
        'OpenRouter API key not configured. Add OPENROUTER_API_KEY to your .env file.',
      );
    }

    OpenRouterException? lastError;

    for (final model in AppConfig.openRouterModelCandidates) {
      final payload = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...messages,
        ],
        'max_tokens': maxTokens,
        'temperature': 0.4,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${AppConfig.openRouterApiKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://cafad.app',
          'X-Title': 'CAFAD Car Fault Diagnosis',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        final canRetry = response.statusCode == 404 || response.statusCode == 400;
        final message = 'OpenRouter error (${response.statusCode}) on model '
            '$model: ${response.body}';
        lastError = OpenRouterException(message);
        if (canRetry) {
          continue;
        }
        throw lastError;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        lastError = OpenRouterException('Empty response from OpenRouter');
        continue;
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        lastError = OpenRouterException('No content in OpenRouter response');
        continue;
      }

      return content.trim();
    }

    throw lastError ?? OpenRouterException('Unable to get response from OpenRouter');
  }

  FaultAnalysis _parseFaultAnalysis(String content) {
    try {
      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return FaultAnalysis.fromJson(json);
    } catch (_) {
      return FaultAnalysis(
        explanation: content,
        suggestedActions: const [
          'Inspect related components visually',
          'Clear code and test drive to verify if issue persists',
          'Consult a certified mechanic',
        ],
        estimatedCost: 'Varies — get quote from mechanic',
        severity: 'Medium',
      );
    }
  }
}

class DashboardDetection {
  const DashboardDetection({
    required this.warningName,
    required this.description,
    required this.severity,
    required this.confidence,
    this.faultCode,
  });

  final String? faultCode;
  final String warningName;
  final String description;
  final String severity;
  final double confidence;

  factory DashboardDetection.fromJson(Map<String, dynamic> json) {
    final code = json['fault_code']?.toString().trim();
    return DashboardDetection(
      faultCode: (code == null || code.isEmpty || code == 'null')
          ? null
          : code.toUpperCase(),
      warningName: json['warning_name']?.toString() ?? 'Unknown Warning',
      description: json['description']?.toString() ?? 'Unknown warning light',
      severity: json['severity']?.toString() ?? 'Medium',
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0.6,
    );
  }
}

class OpenRouterException implements Exception {
  OpenRouterException(this.message);
  final String message;

  @override
  String toString() => message;
}
