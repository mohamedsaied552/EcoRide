import 'dart:async';

abstract class AppEvent {
  const AppEvent();
}

class AppNotificationEvent extends AppEvent {
  const AppNotificationEvent({
    required this.title,
    required this.body,
    required this.data,
  });

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

class MapRefreshRequestedEvent extends AppEvent {
  const MapRefreshRequestedEvent();
}

class UserLoggedOutEvent extends AppEvent {
  const UserLoggedOutEvent();
}
class WalletRefreshRequestedEvent extends AppEvent {
  const WalletRefreshRequestedEvent();
}

class AppEventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  void publish(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
