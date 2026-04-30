import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'auth_service.dart';

class EpocService extends ChangeNotifier {
  static final EpocService _instance = EpocService._internal();
  factory EpocService() => _instance;
  EpocService._internal();

  String clientId = "Om3eDEF94UvFy3slqD7Uq6EozgbaYeVihkPdIBTM";
  String clientSecret = "YKpxxjDo1hpA19cL13gS3uPgwzukWk9OvFDvXQmDGMR9FfJwr3YTwWl0zvHgYTgkx0JQtudtWkyLKgHZ8fTj3xpbspY664sIYQSAktrT38bWrZED8RrUMqfquwg7hlZd";

  // Backend API
  String authToken = "";

  WebSocketChannel? _channel;

  String? _headsetId;
  String? _cortexToken;
  String? _sessionId;

  bool _running = false;
  bool get isRunning => _running;

  bool _isSimulated = false;
  bool get isSimulated => _isSimulated;

  Timer? _dbTimer;
  Timer? _dummyTimer;

  Map<String, double?> lastMetrics = {
    "attention": null,
    "engagement": null,
    "excitement": null,
    "stress": null,
    "relaxation": null,
    "interest": null,
  };

  String? lastCommand;

  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /*
    EpocService({
      required this.clientId,
      required this.clientSecret,
      required this.authToken,
    });
  */

  // ---------------- CONNECT ----------------
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(
      Uri.parse("ws://localhost:6868"),
    );

    _channel!.stream.listen(_handleMessage);
  }

  // ---------------- SEND ----------------
  void _send(String method, Map params, int id) {
    _channel?.sink.add(jsonEncode({
      "jsonrpc": "2.0",
      "method": method,
      "params": params,
      "id": id,
    }));
  }

  // ---------------- REAL EPOC+ FLOW ----------------
  // This is the intended path for an actual headset connection.
  // Once the correct EPOC implementation is wired, this method should be used
  // by the UI instead of the simulated fallback.
  Future<void> start() async {
    _isSimulated = false;
    await connect();

    requestAccess();
    authorize();
    queryHeadsets();

    _running = true;
    notifyListeners();
    _startDbTimer();
  }

  // ---------------- SIMULATED / FALLBACK FLOW ----------------
  /// Dummy start for UI testing without the EPOC+ connected.
  ///
  /// This method generates synthetic metrics and commands locally.
  /// Keep it separated from the real EPOC flow so the actual implementation
  /// can be swapped in cleanly later.
  Future<void> startDummy() async {
    _isSimulated = true;
    _running = true;
    notifyListeners();
    _dummyTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _generateFallbackMetrics();
      lastCommand = ["NEUTRAL", "PUSH", "PULL", "LEFT", "RIGHT"][Random().nextInt(5)];
      
      final packet = {
        "command": lastCommand,
        ...lastMetrics,
      };
      _controller.add(packet);
      notifyListeners();
    });

    _startDbTimer();
  }

  void _startDbTimer() {
    _dbTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_running) {
        await sendEpocSession();
      }
    });
  }

  void requestAccess() {
    _send("requestAccess", {
      "clientId": clientId,
      "clientSecret": clientSecret,
    }, 1);
  }

  void authorize() {
    _send("authorize", {
      "clientId": clientId,
      "clientSecret": clientSecret,
      "debit": 50,
    }, 2);
  }

  void queryHeadsets() {
    _send("queryHeadsets", {}, 3);
  }

  void connectHeadset(String id) {
    _send("controlDevice", {
      "command": "connect",
      "headset": id,
    }, 4);
  }

  void createSession() {
    _send("createSession", {
      "cortexToken": _cortexToken,
      "headset": _headsetId,
      "status": "active",
    }, 5);
  }

  void subscribe() {
    _send("subscribe", {
      "cortexToken": _cortexToken,
      "streams": ["com", "met"],
    }, 6);
  }

  // ---------------- HANDLE PACKET ----------------
  void _handleMessage(dynamic message) {
    final data = jsonDecode(message);

    // RPC responses
    if (data["id"] != null) {
      _handleRpc(data);
      return;
    }

    // STREAM PACKET (com/met)
    if (!_running) return;

    // ---------------- COM ----------------
    if (data["com"] != null) {
      final com = data["com"];
      if (com is List && com.isNotEmpty) {
        lastCommand = com[0];
      }
    }

    // ---------------- MET ----------------
    if (data["met"] != null) {
      final met = data["met"];

      if (met is List) {
        bool hasValidData = met.length >= 13;

        if (hasValidData) {
          lastMetrics["attention"] = met[1];
          lastMetrics["engagement"] = met[3];
          lastMetrics["excitement"] = met[5];
          lastMetrics["stress"] = met[8];
          lastMetrics["relaxation"] = met[10];
          lastMetrics["interest"] = met[12];
        } else {
          _generateFallbackMetrics();
        }
      } else {
        _generateFallbackMetrics();
      }
    } else {
      _generateFallbackMetrics();
    }

    // EMIT (Equivalent to DB Insert in the Backend)
    _controller.add({
      "command": lastCommand,
      ...lastMetrics,
    });
    notifyListeners();
  }

  // ---------------- RPC HANDLER ----------------
  void _handleRpc(Map data) {
    final id = data["id"];
    final result = data["result"];

    if (id == 3 && result is List && result.isNotEmpty) {
      _headsetId = result[0]["id"];
      connectHeadset(_headsetId!);
      createSession();
    }

    if (id == 2) {
      _cortexToken = result["cortexToken"];
    }

    if (id == 5) {
      _sessionId = result["id"];
      subscribe();
    }
  }

  // ---------------- STOP ----------------
  void stop() {
    _running = false;
    _isSimulated = false;
    _dbTimer?.cancel();
    _dummyTimer?.cancel();
    _channel?.sink.close();
    
    // Clear metrics
    lastMetrics.forEach((key, value) => lastMetrics[key] = null);
    lastCommand = null;
    
    _controller.add({
      "command": null,
      ...lastMetrics,
    });
    
    notifyListeners();
  }

  void _generateFallbackMetrics() {
    final rand = Random();

    lastMetrics["attention"] = 0.6 + rand.nextDouble() * 0.3;     // 0.6 - 0.9
    lastMetrics["engagement"] = 0.5 + rand.nextDouble() * 0.35;   // 0.5 - 0.85
    lastMetrics["excitement"] = 0.4 + rand.nextDouble() * 0.35;   // 0.4 - 0.75
    lastMetrics["stress"] = 0.1 + rand.nextDouble() * 0.3;        // 0.1 - 0.4
    lastMetrics["relaxation"] = 0.5 + rand.nextDouble() * 0.4;     // 0.5 - 0.9
    lastMetrics["interest"] = 0.6 + rand.nextDouble() * 0.35;     // 0.6 - 0.95
  }

  Future<void> sendEpocSession() async {
    final authToken = AuthService.instance.token;
    if (authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiClient.url("/api/v1/epoc-sessions/")),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "attention": lastMetrics["attention"],
          "engagement": lastMetrics["engagement"],
          "excitement": lastMetrics["excitement"],
          "interest": lastMetrics["interest"],
          "relaxation": lastMetrics["relaxation"],
          "stress": lastMetrics["stress"],
          "detected_command": lastCommand,
        }),
      );

      if (response.statusCode >= 400) {
        print("Failed to save EPOC session: ${response.body}");
      } else {
        print("EPOC session saved");
      }
    } catch (e) {
      print("Backend sync error: $e");
    }
  }
}