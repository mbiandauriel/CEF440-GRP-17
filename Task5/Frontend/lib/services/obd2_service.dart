import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OBD2Service {
  static BluetoothDevice? _connectedDevice;
  static BluetoothCharacteristic? _obdCharacteristic;
  static StreamSubscription<List<int>>? _notificationSubscription;
  
  // Common OBD2 ELM327 commands
  static const Map<String, String> obdCommands = {
    'engine_rpm': '01 0C',
    'vehicle_speed': '01 0D',
    'coolant_temp': '01 05',
    'engine_load': '01 04',
    'fuel_level': '01 2F',
    'fault_codes': '03',  // Request stored DTCs
  };
  
  // Scan for OBD2 devices
  static Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> devices = [];
    
    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    
    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Filter for OBD2 devices (ELM327, OBDLink, etc.)
        if (r.device.name.toLowerCase().contains('obd') ||
            r.device.name.toLowerCase().contains('elm327') ||
            r.device.name.toLowerCase().contains('vgate') ||
            r.device.name.toLowerCase().contains('icar')) {
          if (!devices.contains(r.device)) {
            devices.add(r.device);
          }
        }
      }
    });
    
    // Wait for scan to complete
    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    
    return devices;
  }
  
  // Connect to OBD2 device
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;
      
      // Discover services and characteristics
      List<BluetoothService> services = await device.discoverServices();
      
      // Find the OBD2 characteristic (usually ELM327 uses specific UUIDs)
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Common OBD2 characteristic UUIDs
          if (characteristic.uuid.toString().toLowerCase().contains('ff') ||
              characteristic.uuid.toString().toLowerCase() == '0000fff1-0000-1000-8000-00805f9b34fb') {
            _obdCharacteristic = characteristic;
            
            // Enable notifications
            await characteristic.setNotifyValue(true);
            _notificationSubscription = characteristic.value.listen((value) {
              _handleObdResponse(value);
            });
            
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }
  
  // Send command to OBD2
  static Future<String?> sendCommand(String command) async {
    if (_obdCharacteristic == null) return null;
    
    try {
      // Convert command to bytes (ELM327 expects hex commands with carriage return)
      List<int> bytes = utf8.encode('$command\r');
      await _obdCharacteristic!.write(bytes);
      
      // Wait for response
      await Future.delayed(const Duration(milliseconds: 500));
      return null;
    } catch (e) {
      print('Command error: $e');
      return null;
    }
  }
  
  // Handle OBD2 responses
  static void _handleObdResponse(List<int> data) {
    String response = utf8.decode(data);
    print('OBD2 Response: $response');
    // Parse response based on command type
  }
  
  // Read Diagnostic Trouble Codes
  static Future<List<Map<String, String>>> readFaultCodes() async {
    List<Map<String, String>> faultCodes = [];
    
    try {
      // Send command to read DTCs
      await sendCommand('03');
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, you would parse the response
      // Sample response format: "43 01 02 03 04 05 06 07"
      
      // For demo purposes, return sample codes
      faultCodes = [
        {'code': 'P0300', 'description': 'Random/Multiple Cylinder Misfire Detected'},
        {'code': 'P0420', 'description': 'Catalyst System Efficiency Below Threshold'},
      ];
      
    } catch (e) {
      print('Error reading fault codes: $e');
    }
    
    return faultCodes;
  }
  
  // Clear fault codes
  static Future<bool> clearFaultCodes() async {
    try {
      await sendCommand('04'); // ELM327 command to clear DTCs
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Error clearing codes: $e');
      return false;
    }
  }
  
  // Get real-time engine data
  static Future<Map<String, dynamic>> getLiveData() async {
    Map<String, dynamic> data = {};
    
    try {
      // Read engine RPM
      await sendCommand(obdCommands['engine_rpm']!);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Read vehicle speed
      await sendCommand(obdCommands['vehicle_speed']!);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Read coolant temperature
      await sendCommand(obdCommands['coolant_temp']!);
      
    } catch (e) {
      print('Error reading live data: $e');
    }
    
    return data;
  }
  
  // Disconnect from OBD2 device
  static Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _obdCharacteristic = null;
  }
  
  // Check if connected
  static bool isConnected() {
    return _connectedDevice != null && _connectedDevice!.isConnected;
  }
}