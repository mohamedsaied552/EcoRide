import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:glider/core/constants/app_constants.dart';
import 'package:glider/core/storage/token_storage.dart';
import 'package:glider/domain/entities/live_ride_update.dart';

/// Persistent WebSocket connection for live ride telemetry.
///
/// Connects to `/ws/ride/{rideId}` on the API host (derived from [AppConstants.baseUrl])
/// and streams scooter location, duration, and cost updates from the backend.
class WebSocketService {
  WebSocketService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _activeRideId;

  final StreamController<LiveRideUpdate> _updatesController =
      StreamController<LiveRideUpdate>.broadcast();

  Stream<LiveRideUpdate> get updates => _updatesController.stream;

  bool get isConnected => _channel != null;

  String? get activeRideId => _activeRideId;

  Future<void> connect({required String rideId}) async {
    if (_activeRideId == rideId && _channel != null) {
      return;
    }

    await disconnect();

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Cannot open ride WebSocket without an access token.');
    }

    final uri = _buildRideWebSocketUri(rideId: rideId, accessToken: token);
    debugPrint('WS: connecting to $uri');
    
    debugPrint('WS: backend does not support WebSocket — skipping connection.');
    return;
    // _channel = WebSocketChannel.connect(uri);
    // _activeRideId = rideId;

    // _subscription = _channel!.stream.listen(
    //   _handleMessage,
    //   onError: (Object error, StackTrace stackTrace) {
    //     debugPrint('WS ERROR: $error');
    //     debugPrint('$stackTrace');
    //   },
    //   onDone: () {
    //     debugPrint('WS: connection closed for ride=$rideId');
    //     _channel = null;
    //     _activeRideId = null;
    //   },
    //   cancelOnError: false,
    // );
  }

  Uri _buildRideWebSocketUri({
    required String rideId,
    required String accessToken,
  }) {
    final apiUri = Uri.parse(AppConstants.baseUrl);
    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    final host = apiUri.host;
    final port = apiUri.hasPort ? apiUri.port : null;

    return Uri(
      scheme: wsScheme,
      host: host,
      port: port,
      path: '/ws/ride/$rideId',
      queryParameters: <String, String>{
        'access_token': accessToken,
      },
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> payload;
      if (message is String) {
        final decoded = jsonDecode(message);
        if (decoded is! Map) {
          return;
        }
        payload = Map<String, dynamic>.from(decoded);
      } else if (message is Map) {
        payload = Map<String, dynamic>.from(message);
      } else {
        return;
      }

      final type = (payload['type'] ?? payload['Type'] ?? 'rideUpdate')
          .toString()
          .toLowerCase();
      if (type.contains('ping') || type.contains('heartbeat')) {
        _sendPong();
        return;
      }

      _updatesController.add(LiveRideUpdate.fromJson(payload));
    } catch (error) {
      debugPrint('WS: failed to parse message: $error');
    }
  }

  void _sendPong() {
    try {
      _channel?.sink.add(jsonEncode(<String, String>{'type': 'pong'}));
    } catch (_) {
      // Ignore send failures on a closing socket.
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _activeRideId = null;
  }

  void dispose() {
    unawaited(disconnect());
    _updatesController.close();
  }
}
