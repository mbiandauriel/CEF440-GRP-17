class DtcRecord {
  const DtcRecord({
    required this.code,
    required this.manufacturer,
    required this.description,
    required this.type,
    required this.locale,
    required this.isGeneric,
    this.sourceFile,
  });

  final String code;
  final String manufacturer;
  final String description;
  final String type;
  final String locale;
  final bool isGeneric;
  final String? sourceFile;

  factory DtcRecord.fromMap(Map<String, dynamic> map) {
    return DtcRecord(
      code: map['code'] as String? ?? '',
      manufacturer: map['manufacturer'] as String? ?? 'GENERIC',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'P',
      locale: map['locale'] as String? ?? 'en',
      isGeneric: _parseBool(map['is_generic']),
      sourceFile: map['source_file'] as String?,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'manufacturer': manufacturer,
        'description': description,
        'type': type,
        'locale': locale,
        'is_generic': isGeneric ? 1 : 0,
        if (sourceFile != null) 'source_file': sourceFile,
      };

  String get typeLabel {
    switch (type.toUpperCase()) {
      case 'P':
        return 'Powertrain';
      case 'B':
        return 'Body';
      case 'C':
        return 'Chassis';
      case 'U':
        return 'Network';
      default:
        return type;
    }
  }
}
