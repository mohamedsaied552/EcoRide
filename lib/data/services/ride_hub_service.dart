import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:glider/core/constants/app_constants.dart';
import 'package:glider/core/storage/token_storage.dart';
import 'package:glider/domain/entities/live_ride_update.dart';

class RideHubService {
  RideHubService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;
  HubConnection? _connection;
  String? _activeRideId;

  final StreamController<LiveRideUpdate> _updatesController =
      StreamController<LiveRideUpdate>.broadcast();

  final StreamController<double> _walletController =
      StreamController<double>.broadcast();

  Stream<LiveRideUpdate> get rideUpdates => _updatesController.stream;
  Stream<double> get walletUpdates => _walletController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  String? get activeRideId => _activeRideId;

  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('No access token for SignalR connection.');
    }

    final hubUrl = '${AppConstants.baseUrl}/hubs/rider';

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(accessTokenFactory: () async => token),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveRideTelemetry', (args) {
      if (args == null || args.isEmpty) return;
      try {
        final payload = Map<String, dynamic>.from(args[0] as Map);
        _updatesController.add(LiveRideUpdate.fromJson(payload));
      } catch (e) {
        debugPrint('SignalR: failed to parse telemetry: $e');
      }
    });

    _connection!.on('WalletBalanceUpdated', (args) {
      if (args == null || args.isEmpty) return;
      try {
        final balance = (args[0] as num).toDouble();
        _walletController.add(balance);
      } catch (e) {
        debugPrint('SignalR: failed to parse wallet update: $e');
      }
    });

    _connection!.onclose(({Exception? error}) {
      debugPrint('SignalR: connection closed. error=$error');
      _activeRideId = null;
    });

    await _connection!.start();
    debugPrint('SignalR: connected to $hubUrl');
  }

  /// Call IMMEDIATELY after API returns rideId on unlock.
  Future<void> joinRide(String rideId) async {
    _ensureConnected();
    await _connection!.invoke('JoinRideGroup', args: [rideId]);
    _activeRideId = rideId;
    debugPrint('SignalR: joined ride group $rideId');
  }

  /// Call when ride ends.
  Future<void> leaveRide(String rideId) async {
    if (_connection?.state != HubConnectionState.Connected) {
      debugPrint('SignalR: not connected, skipping leaveRide');
      _activeRideId = null;
      return; // ← مش بترمي exception
    }
    await _connection!.invoke('LeaveRideGroup', args: [rideId]);
    _activeRideId = null;
    debugPrint('SignalR: left ride group $rideId');
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
    _activeRideId = null;
  }

  void dispose() {
    disconnect();
    _updatesController.close();
    _walletController.close();
  }

  void _ensureConnected() {
    if (_connection?.state != HubConnectionState.Connected) {
      throw StateError('SignalR not connected. Call connect() first.');
    }
  }
}
