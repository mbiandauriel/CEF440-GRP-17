import 'package:flutter/material.dart';

import '../models/dtc_record.dart';
import 'dtc_database_service.dart';
import 'vehicle_profile_service.dart';

Color severityColorFor(String severity) {
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

String defaultSeverityForRecord(DtcRecord record) {
  if (record.type.toUpperCase() == 'P') {
    return record.isGeneric ? 'Medium' : 'High';
  }
  return 'Medium';
}

Future<Map<String, dynamic>> enrichFaultFromDatabase({
  required String code,
  String? fallbackDescription,
  String sourceType = 'obd',
}) async {
  final manufacturer = VehicleProfileService.instance.profile.manufacturer;
  final record = await DtcDatabaseService.instance.lookup(
    code: code,
    manufacturer: manufacturer,
  );

  if (record != null) {
    final severity = defaultSeverityForRecord(record);
    return {
      'code': record.code,
      'description': record.description,
      'severity': severity,
      'severityColor': severityColorFor(severity),
      'type': sourceType,
      'dtcRecord': record,
    };
  }

  final severity = 'Medium';
  return {
    'code': code.toUpperCase(),
    'description': fallbackDescription ??
        'Fault code not found in database. Consult a mechanic for diagnosis.',
    'severity': severity,
    'severityColor': severityColorFor(severity),
    'type': sourceType,
  };
}
