import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/obd2_service.dart';
import '../services/dashboard_scanner_service.dart';
import '../services/fault_lookup_service.dart';
import 'fault_details_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  bool _isScanning = false;
  bool _isConnecting = false;
  List<Map<String, dynamic>> _diagnosisResults = [];
  List<BluetoothDevice> _obdDevices = [];
  BluetoothDevice? _selectedDevice;
  String _connectionStatus = 'Not Connected';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.camera.request();
  }
  
  Future<void> _scanForOBD2Devices() async {
    setState(() {
      _isScanning = true;
      _obdDevices.clear();
    });
    
    _obdDevices = await OBD2Service.scanForDevices();
    
    setState(() {
      _isScanning = false;
    });
    
    if (!mounted) return;
    if (_obdDevices.isNotEmpty) {
      _showDeviceSelectionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No OBD2 devices found. Make sure your adapter is powered on.')),
      );
    }
  }
  
  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select OBD2 Device'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _obdDevices.length,
            itemBuilder: (context, index) {
              final device = _obdDevices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.blue),
                title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                subtitle: Text(device.id.toString()),
                onTap: () async {
                  Navigator.pop(context);
                  await _connectToDevice(device);
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });
    
    bool success = await OBD2Service.connectToDevice(device);
    
    setState(() {
      _isConnecting = false;
      if (success) {
        _selectedDevice = device;
        _connectionStatus = 'Connected to ${device.name}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      } else {
        _connectionStatus = 'Connection failed';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to device')),
        );
      }
    });
  }
  
  Future<void> _readFaultCodes() async {
    if (!OBD2Service.isConnected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to OBD2 device first')),
      );
      return;
    }
    
    setState(() {
      _isScanning = true;
    });
    
    List<Map<String, String>> faultCodes = await OBD2Service.readFaultCodes();
    final enriched = <Map<String, dynamic>>[];

    for (final code in faultCodes) {
      enriched.add(await enrichFaultFromDatabase(
        code: code['code']!,
        fallbackDescription: code['description'],
      ));
    }
    
    setState(() {
      _diagnosisResults = enriched;
      _isScanning = false;
    });
    
    if (!mounted) return;
    if (_diagnosisResults.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${_diagnosisResults.length} fault codes')),
      );
    }
  }

  Future<void> _runDemoScan() async {
    setState(() => _isScanning = true);

    const demoCodes = ['P0300', 'P0420'];
    final enriched = <Map<String, dynamic>>[];
    for (final code in demoCodes) {
      enriched.add(await enrichFaultFromDatabase(code: code));
    }

    setState(() {
      _diagnosisResults = enriched;
      _isScanning = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demo scan complete — ${enriched.length} faults loaded from database',
          ),
        ),
      );
    }
  }

  Future<void> _showManualLookupDialog() async {
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _LookupFaultCodeDialog(),
    );

    if (code == null || !mounted) return;

    setState(() => _isScanning = true);
    final result = await enrichFaultFromDatabase(code: code);
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      final exists =
          _diagnosisResults.any((r) => r['code'] == result['code']);
      if (!exists) {
        _diagnosisResults = [..._diagnosisResults, result];
      }
    });
  }
  
  Future<void> _scanDashboardWithCamera() async {
    // Request camera permission
    var cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }
    
    // Navigate to camera scanner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DashboardCameraScanner(),
      ),
    ).then((results) {
      if (results != null && results.isNotEmpty) {
        _applyCameraResults(List<Map<String, dynamic>>.from(results));
      }
    });
  }

  Future<void> _applyCameraResults(List<Map<String, dynamic>> results) async {
    final merged = List<Map<String, dynamic>>.from(_diagnosisResults);

    for (final result in results) {
      final faultCode = (result['faultCode'] as String?)?.toUpperCase();
      final light = result['light'] as Map<String, dynamic>;
      final description = light['description']?.toString() ?? 'Unknown warning';

      if (faultCode != null &&
          RegExp(r'^[PBCU][0-9A-F]{4}$').hasMatch(faultCode)) {
        final enriched = await enrichFaultFromDatabase(
          code: faultCode,
          fallbackDescription: description,
          sourceType: 'camera',
        );
        enriched['confidence'] = result['confidence'];
        merged.add(enriched);
      } else {
        merged.add({
          'code': light['name'].toString().toUpperCase().replaceAll(' ', '_'),
          'description': description,
          'severity': light['severity']?.toString() ?? 'Medium',
          'severityColor':
              _getSeverityColor(light['severity']?.toString() ?? 'Medium'),
          'type': 'camera',
          'confidence': result['confidence'],
        });
      }
    }

    if (!mounted) return;
    setState(() => _diagnosisResults = merged);
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red.shade900;
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }
  
  Future<void> _disconnectOBD2() async {
    await OBD2Service.disconnect();
    setState(() {
      _selectedDevice = null;
      _connectionStatus = 'Not Connected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from OBD2 device')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Diagnosis'),
        actions: [
          if (OBD2Service.isConnected())
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnectOBD2,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // OBD2 Connection Status Card
            Card(
              color: OBD2Service.isConnected() ? Colors.green.shade50 : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      OBD2Service.isConnected() ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: OBD2Service.isConnected() ? Colors.green : Colors.grey,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBD2 Status',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _selectedDevice != null
                                ? 'Connected to ${_selectedDevice!.name}'
                                : _connectionStatus,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: OBD2Service.isConnected() ? Colors.green : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!OBD2Service.isConnected())
                      ElevatedButton.icon(
                        onPressed: (_isScanning || _isConnecting) ? null : _scanForOBD2Devices,
                        icon: (_isScanning || _isConnecting)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bluetooth_searching),
                        label: Text(_isScanning
                            ? 'Scanning...'
                            : _isConnecting
                                ? 'Connecting...'
                                : 'Connect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _readFaultCodes,
                        icon: const Icon(Icons.download),
                        label: const Text('Read Codes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Demo & manual lookup (works without OBD hardware)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _runDemoScan,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Demo Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _showManualLookupDialog,
                    icon: const Icon(Icons.search),
                    label: const Text('Lookup Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Diagnosis Options
            Row(
              children: [
                Expanded(
                  child: _buildDiagnosisButton(
                    icon: Icons.camera_alt,
                    title: 'Scan Dashboard',
                    subtitle: 'Use camera to scan',
                    color: const Color(0xFFE53935),
                    onTap: _scanDashboardWithCamera,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDiagnosisButton(
                    icon: Icons.photo_library,
                    title: 'Upload Photo',
                    subtitle: 'From gallery',
                    color: const Color(0xFF43A047),
                    onTap: () async {
                      setState(() => _isScanning = true);
                      var results = await DashboardScannerService.scanFromGallery();
                      if (!mounted) return;
                      setState(() => _isScanning = false);
                      if (results.isNotEmpty) {
                        await _applyCameraResults(results);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Scanning Indicator
            if (_isScanning)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Scanning vehicle systems...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Results
            if (_diagnosisResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diagnosis Results',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _diagnosisResults.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._diagnosisResults.map((result) => _buildResultCard(result)),
            ],
            
            // No results placeholder
            if (!_isScanning && _diagnosisResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No diagnosis performed yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Connect OBD2 or scan dashboard to start',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FaultDetailsScreen(fault: result),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (result['severityColor'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result['type'] == 'camera' ? Icons.camera_alt : Icons.warning,
                  color: result['severityColor'],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          result['code'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (result['type'] == 'camera')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Camera',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      result['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (result['severityColor'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Severity: ${result['severity']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: result['severityColor'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Camera Scanner Screen
class DashboardCameraScanner extends StatefulWidget {
  const DashboardCameraScanner({super.key});

  @override
  State<DashboardCameraScanner> createState() => _DashboardCameraScannerState();
}

class _DashboardCameraScannerState extends State<DashboardCameraScanner> {
  bool _isInitialized = false;
  bool _isScanning = false;
  List<Map<String, dynamic>> _detectedLights = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }
  
  Future<void> _initCamera() async {
    bool success = await DashboardScannerService.initializeCamera();
    setState(() {
      _isInitialized = success;
    });
  }
  
  Future<void> _captureAndScan() async {
    setState(() {
      _isScanning = true;
    });
    
    _detectedLights = await DashboardScannerService.scanDashboard();
    
    setState(() {
      _isScanning = false;
    });
    
    if (_detectedLights.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detected ${_detectedLights.length} warning lights!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No warning lights detected. Try taking another photo.')),
      );
    }
  }
  
  @override
  void dispose() {
    DashboardScannerService.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () async {
              var results = await DashboardScannerService.scanFromGallery();
              if (results.isNotEmpty) {
                Navigator.pop(context, results);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: _isInitialized
                  ? DashboardScannerService.getCameraPreview()
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Position your phone to capture the dashboard warning lights clearly',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _captureAndScan,
                    icon: _isScanning
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Icon(Icons.camera),
                    label: Text(_isScanning ? 'Analyzing...' : 'Capture & Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Detection Results
          if (_detectedLights.isNotEmpty)
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected Warning Lights:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _detectedLights.length,
                      itemBuilder: (context, index) {
                        final light = _detectedLights[index]['light'];
                        final faultCode = _detectedLights[index]['faultCode'] as String?;
                        return ListTile(
                          leading: Text(light['icon'], style: const TextStyle(fontSize: 24)),
                          title: Text(light['name']),
                          subtitle: Text(
                            faultCode != null && faultCode.isNotEmpty
                                ? '${light['description']}\nLikely code: $faultCode'
                                : light['description'],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(light['severity']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              light['severity'],
                              style: TextStyle(
                                color: _getSeverityColor(light['severity']),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _detectedLights);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Use These Results'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical': return Colors.red.shade900;
      case 'High': return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }
}

class _LookupFaultCodeDialog extends StatefulWidget {
  const _LookupFaultCodeDialog();

  @override
  State<_LookupFaultCodeDialog> createState() => _LookupFaultCodeDialogState();
}

class _LookupFaultCodeDialogState extends State<_LookupFaultCodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lookup Fault Code'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Fault code (e.g. P0300)',
            hintText: 'P0300',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a fault code';
            }
            if (!RegExp(r'^[PBCU][0-9A-F]{4}$', caseSensitive: false)
                .hasMatch(value.trim())) {
              return 'Enter a valid OBD-II code (e.g. P0300)';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lookup'),
        ),
      ],
    );
  }
}