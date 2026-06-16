import 'package:shared_preferences/shared_preferences.dart';

class VehicleProfile {
  const VehicleProfile({
    required this.manufacturer,
    required this.model,
    required this.year,
    this.plate = 'ABC-1234',
    this.odometerKm = 45200,
  });

  final String manufacturer;
  final String model;
  final int year;
  final String plate;
  final int odometerKm;

  String get displayName => '$manufacturer $model $year';

  VehicleProfile copyWith({
    String? manufacturer,
    String? model,
    int? year,
    String? plate,
    int? odometerKm,
  }) {
    return VehicleProfile(
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      odometerKm: odometerKm ?? this.odometerKm,
    );
  }
}

class VehicleProfileService {
  VehicleProfileService._();

  static final VehicleProfileService instance = VehicleProfileService._();

  static const _keyManufacturer = 'vehicle_manufacturer';
  static const _keyModel = 'vehicle_model';
  static const _keyYear = 'vehicle_year';
  static const _keyPlate = 'vehicle_plate';
  static const _keyOdometer = 'vehicle_odometer';

  VehicleProfile _profile = const VehicleProfile(
    manufacturer: 'TOYOTA',
    model: 'Camry',
    year: 2020,
  );

  VehicleProfile get profile => _profile;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _profile = VehicleProfile(
      manufacturer:
          prefs.getString(_keyManufacturer)?.toUpperCase() ?? 'TOYOTA',
      model: prefs.getString(_keyModel) ?? 'Camry',
      year: prefs.getInt(_keyYear) ?? 2020,
      plate: prefs.getString(_keyPlate) ?? 'ABC-1234',
      odometerKm: prefs.getInt(_keyOdometer) ?? 45200,
    );
  }

  Future<void> save(VehicleProfile profile) async {
    _profile = profile.copyWith(
      manufacturer: profile.manufacturer.toUpperCase(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyManufacturer, _profile.manufacturer);
    await prefs.setString(_keyModel, _profile.model);
    await prefs.setInt(_keyYear, _profile.year);
    await prefs.setString(_keyPlate, _profile.plate);
    await prefs.setInt(_keyOdometer, _profile.odometerKm);
  }
}
