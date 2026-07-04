import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/dtc_record.dart';
import '../utils/io_helper.dart';

/// Web fallback for the 5 demo codes when SQLite is unavailable.
const Map<String, DtcRecord> _webDemoRecords = {
  'P0300': DtcRecord(
    code: 'P0300',
    manufacturer: 'GENERIC',
    description: 'Random/Multiple Cylinder Misfire Detected',
    type: 'P',
    locale: 'en',
    isGeneric: true,
  ),
  'P0420': DtcRecord(
    code: 'P0420',
    manufacturer: 'GENERIC',
    description: 'Catalyst System Efficiency Below Threshold (Bank 1)',
    type: 'P',
    locale: 'en',
    isGeneric: true,
  ),
  'P0171': DtcRecord(
    code: 'P0171',
    manufacturer: 'GENERIC',
    description: 'System Too Lean (Bank 1)',
    type: 'P',
    locale: 'en',
    isGeneric: true,
  ),
  'P0442': DtcRecord(
    code: 'P0442',
    manufacturer: 'GENERIC',
    description: 'Evaporative Emission Control System Leak Detected (small leak)',
    type: 'P',
    locale: 'en',
    isGeneric: true,
  ),
  'P0128': DtcRecord(
    code: 'P0128',
    manufacturer: 'GENERIC',
    description: 'Coolant Thermostat (Coolant Temperature Below Thermostat Regulating Temperature)',
    type: 'P',
    locale: 'en',
    isGeneric: true,
  ),
};

class DtcDatabaseService {
  DtcDatabaseService._();

  static final DtcDatabaseService instance = DtcDatabaseService._();

  static const _assetPath = 'database/dtc_codes.db';
  static const _dbFileName = 'dtc_codes.db';

  Database? _db;
  bool _initialized = false;

  bool get isAvailable => _initialized && _db != null;
  bool get isWebFallback => kIsWeb;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    if (isDesktopPlatform) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _resolveDatabasePath();
    _db = await openDatabase(dbPath, readOnly: true);
    _initialized = true;
  }

  Future<String> _resolveDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, _dbFileName);

    if (!await databaseFileExists(dbPath)) {
      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List();
      await writeDatabaseFile(dbPath, bytes);
    }

    return dbPath;
  }

  Future<DtcRecord?> lookup({
    required String code,
    required String manufacturer,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final normalizedManufacturer = manufacturer.trim().toUpperCase();

    if (kIsWeb) {
      return _lookupWeb(normalizedCode, normalizedManufacturer);
    }

    if (_db == null) return null;

    final specific = await _db!.rawQuery(
      '''
      SELECT code, manufacturer, description, type, locale, is_generic, source_file
      FROM dtc_definitions
      WHERE code = ? AND UPPER(manufacturer) = ? AND locale = 'en'
      LIMIT 1
      ''',
      [normalizedCode, normalizedManufacturer],
    );

    if (specific.isNotEmpty) {
      return DtcRecord.fromMap(specific.first);
    }

    final generic = await _db!.rawQuery(
      '''
      SELECT code, description, type
      FROM generic_codes
      WHERE code = ?
      LIMIT 1
      ''',
      [normalizedCode],
    );

    if (generic.isNotEmpty) {
      final row = generic.first;
      return DtcRecord(
        code: row['code'] as String,
        manufacturer: 'GENERIC',
        description: row['description'] as String,
        type: row['type'] as String? ?? 'P',
        locale: 'en',
        isGeneric: true,
      );
    }

    return null;
  }

  DtcRecord? _lookupWeb(String code, String manufacturer) {
    if (_webDemoRecords.containsKey(code)) {
      final demo = _webDemoRecords[code]!;
      if (manufacturer == 'GENERIC' || manufacturer == 'TOYOTA') {
        return demo;
      }
      return demo.copyWithManufacturer(manufacturer);
    }
    return null;
  }

  Future<List<String>> getManufacturers() async {
    if (kIsWeb || _db == null) {
      return const [
        'TOYOTA',
        'BMW',
        'BUICK',
        'FORD',
        'HONDA',
        'CHEVROLET',
        'NISSAN',
        'MERCEDES-BENZ',
        'VOLKSWAGEN',
        'HYUNDAI',
      ];
    }

    final rows = await _db!.rawQuery(
      '''
      SELECT DISTINCT manufacturer
      FROM dtc_definitions
      WHERE locale = 'en'
      ORDER BY manufacturer ASC
      ''',
    );

    return rows
        .map((r) => (r['manufacturer'] as String).toUpperCase())
        .toSet()
        .toList();
  }
}

extension on DtcRecord {
  DtcRecord copyWithManufacturer(String manufacturer) {
    return DtcRecord(
      code: code,
      manufacturer: manufacturer,
      description: description,
      type: type,
      locale: locale,
      isGeneric: isGeneric,
      sourceFile: sourceFile,
    );
  }
}
