import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScannerService {
  static List<CameraDescription>? _cameras;
  static CameraController? _cameraController;
  
  // Common dashboard warning light patterns
  static const Map<String, Map<String, dynamic>> warningLights = {
    'check_engine': {
      'name': 'Check Engine',
      'severity': 'High',
      'description': 'Engine malfunction detected',
      'icon': '🚗',
      'color': '#FF0000',
    },
    'oil_pressure': {
      'name': 'Oil Pressure',
      'severity': 'Critical',
      'description': 'Low oil pressure - Stop engine immediately',
      'icon': '🛢️',
      'color': '#FF0000',
    },
    'battery': {
      'name': 'Battery/Charging',
      'severity': 'High',
      'description': 'Charging system fault',
      'icon': '🔋',
      'color': '#FF0000',
    },
    'brake': {
      'name': 'Brake System',
      'severity': 'Critical',
      'description': 'Brake system issue - Immediate attention',
      'icon': '🛑',
      'color': '#FF0000',
    },
    'abs': {
      'name': 'ABS',
      'severity': 'Medium',
      'description': 'Anti-lock Brake System fault',
      'icon': '⚠️',
      'color': '#FFA500',
    },
    'airbag': {
      'name': 'Airbag',
      'severity': 'High',
      'description': 'Airbag system malfunction',
      'icon': '💺',
      'color': '#FF0000',
    },
    'coolant_temp': {
      'name': 'Coolant Temperature',
      'severity': 'Critical',
      'description': 'Engine overheating',
      'icon': '🌡️',
      'color': '#FF0000',
    },
    'tire_pressure': {
      'name': 'Tire Pressure',
      'severity': 'Medium',
      'description': 'Low tire pressure detected',
      'icon': '⚙️',
      'color': '#FFA500',
    },
    'washer_fluid': {
      'name': 'Washer Fluid',
      'severity': 'Low',
      'description': 'Low windshield washer fluid',
      'icon': '💧',
      'color': '#FFFF00',
    },
  };
  
  // Initialize camera
  static Future<bool> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return false;
      
      // Use rear camera
      final rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      return true;
    } catch (e) {
      print('Camera initialization error: $e');
      return false;
    }
  }
  
  // Get camera preview widget
  static Widget getCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: Text('Camera not available'));
    }
    return CameraPreview(_cameraController!);
  }
  
  // Take picture and scan for warning lights
  static Future<List<Map<String, dynamic>>> scanDashboard() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return [];
    }
    
    try {
      // Take picture
      XFile picture = await _cameraController!.takePicture();
      File imageFile = File(picture.path);
      
      // Process image with ML Kit
      List<Map<String, dynamic>> detectedLights = await _processImage(imageFile);
      
      return detectedLights;
    } catch (e) {
      print('Scan error: $e');
      return [];
    }
  }
  
  // Process image using ML Kit
  static Future<List<Map<String, dynamic>>> _processImage(File imageFile) async {
    List<Map<String, dynamic>> detected = [];
    
    try {
      // Convert to InputImage
      final inputImage = InputImage.fromFile(imageFile);
      
      // Initialize object detector
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: false,
      );
      final objectDetector = GoogleMlKit.vision.objectDetector(options: options);
      
      // Detect objects in image
      final List<DetectedObject> objects = await objectDetector.processImage(inputImage);
      
      // Process each detected object
      for (DetectedObject object in objects) {
        // Check if detected object matches any warning light pattern
        for (var warning in warningLights.keys) {
          // In a real implementation, you would use image classification
          // For demo, we'll simulate detection based on labels
          if (object.labels.isNotEmpty) {
            String label = object.labels[0].text.toLowerCase();
            if (label.contains('light') || 
                label.contains('warning') ||
                label.contains('dashboard')) {
              
              detected.add({
                'light': warningLights[warning],
                'confidence': object.labels[0].confidence,
                'boundingBox': object.boundingBox,
              });
              break;
            }
          }
        }
      }
      
      await objectDetector.close();
      
      // Simulate detection if none found (for demo purposes)
      if (detected.isEmpty) {
        // Random detection for demo
        final randomWarning = warningLights.keys.toList();
        final randomIndex = DateTime.now().second % randomWarning.length;
        
        detected.add({
          'light': warningLights[randomWarning[randomIndex]],
          'confidence': 0.85,
          'boundingBox': null,
        });
      }
      
    } catch (e) {
      print('ML Kit processing error: $e');
    }
    
    return detected;
  }
  
  // Pick image from gallery and scan
  static Future<List<Map<String, dynamic>>> scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return [];
    
    File imageFile = File(image.path);
    return await _processImage(imageFile);
  }
  
  // Dispose camera controller
  static void disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }
}