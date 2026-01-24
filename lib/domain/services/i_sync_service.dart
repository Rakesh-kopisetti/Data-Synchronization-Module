import 'package:offline_sync_app/core/constants/enums.dart';

abstract class ISyncService {
  Stream<ConnectivityStatus> get connectivityStatusStream;
  Stream<SyncEvent> get syncEventStream;
  ConnectivityStatus get currentConnectivityStatus;

  Future<void> synchronizeData();
  void startMonitoringConnectivity();
  void stopMonitoringConnectivity();
  Future<void> dispose();
}

class SyncEvent {
  final SyncEventType type;
  final String? message;
  final Exception? error;

  SyncEvent({
    required this.type,
    this.message,
    this.error,
  });
}
