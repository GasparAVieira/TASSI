import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'api_client.dart';
import 'auth_service.dart';

class BeaconDevice {
  final String id;
  final String name;
  final int rssi;

  BeaconDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

class BeaconService {
  final auth = AuthService();
  final String targetLocationId;

  static const String _fallbackUuid = "39ED98FF-2900-441A-802F-9C398FC199D2";

  BeaconService({
    required this.targetLocationId,
  });

  final StreamController<BeaconDevice> _controller = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _navigationController =
  StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get navigationStream => _navigationController.stream;

  Stream<BeaconDevice> get stream => _controller.stream;

  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  String? _lastBeaconId;

  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> startScanning() async {
    /*if (_isScanning) return;

    await requestPermissions();

    _isScanning = true;

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 0),
      continuousUpdates: true,
    );*/


    Timer(Duration(seconds: 1), () {
      _sendBeaconToBackend(uuid: _fallbackUuid);
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isEmpty) return;

      BeaconDevice? closestBeacon;

      for (final result in results) {
        final beacon = _parseIBeacon(result);
        if (beacon == null) continue;

        if (closestBeacon == null || beacon.rssi > closestBeacon.rssi) {
          closestBeacon = beacon;
        }
      }

      if (closestBeacon == null) return;

      _controller.add(closestBeacon);

      if (_lastBeaconId == closestBeacon.id) return;

      _lastBeaconId = closestBeacon.id;

      await _sendBeaconToBackend(
        uuid: closestBeacon.id,
        );
    });
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  void dispose() {
    stopScanning();
    _controller.close();
    _navigationController.close();
  }

  Future<void> _sendBeaconToBackend({
    required String uuid,
  }) async {
    print("SEND BEACON CHAMADO");
    try {
      final uri = Uri.parse(
        ApiClient.url("/api/v1/navigation/beacon-next",),);

      final response = await http.post(
        uri,
        headers: auth.authHeaders(),
        body: jsonEncode({
          'beacon_uuid': uuid,
          'target_location_id': targetLocationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("STATUS: ${response.statusCode}");
        print("BODY: ${response.body}");

        _navigationController.add(data);
      } else {
        print("Navigation failed: ${response.body}");
      }
    } catch (e) {
      print("Backend beacon sync error: $e");
    }
  }

  BeaconDevice? _parseIBeacon(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;

    if (!manufacturerData.containsKey(0x004C)) {
      return null; // não é Apple → não é iBeacon
    }

    final data = manufacturerData[0x004C];
    if (data == null || data.length < 25) return null;

    // iBeacon format check: 0x02 0x15
    if (data[0] != 0x02 || data[1] != 0x15) {
      return null;
    }

    final uuidBytes = data.sublist(2, 18);
    final uuid = _formatUuid(uuidBytes);

    return BeaconDevice(
      id: uuid,
      name: result.device.platformName,
      rssi: result.rssi,
    );
  }

  String _formatUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}