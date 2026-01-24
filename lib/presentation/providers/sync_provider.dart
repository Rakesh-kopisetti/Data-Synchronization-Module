import 'dart:async';
import 'package:flutter/material.dart';
import 'package:offline_sync_app/domain/services/i_sync_service.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

class SyncProvider extends ChangeNotifier {
  final ISyncService _syncService;

  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;
  String? _syncMessage;
  bool _isSyncing = false;
  String? _syncError;
  late StreamSubscription<ConnectivityStatus> _connectivitySubscription;
  late StreamSubscription<SyncEvent> _syncEventSubscription;

  SyncProvider(this._syncService) {
    _initializeListeners();
  }

  ConnectivityStatus get connectivityStatus => _connectivityStatus;
  String? get syncMessage => _syncMessage;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  bool get isOnline => _connectivityStatus == ConnectivityStatus.online;

  void _initializeListeners() {
    _connectivitySubscription = _syncService.connectivityStatusStream.listen(
      (status) {
        _connectivityStatus = status;
        _syncMessage = _getStatusMessage(status);
        notifyListeners();
      },
    );

    _syncEventSubscription = _syncService.syncEventStream.listen(
      (event) {
        _handleSyncEvent(event);
      },
    );
  }

  void _handleSyncEvent(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.started:
        _isSyncing = true;
        _syncMessage = 'Syncing...';
        _syncError = null;
        break;
      case SyncEventType.completed:
        _isSyncing = false;
        _syncMessage = 'Sync completed';
        _syncError = null;
        break;
      case SyncEventType.failed:
        _isSyncing = false;
        _syncMessage = 'Sync failed';
        _syncError = event.error?.toString() ?? 'Unknown error';
        break;
      case SyncEventType.conflictResolved:
        _syncMessage = event.message ?? 'Conflict resolved';
        break;
    }
    notifyListeners();
  }

  String _getStatusMessage(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }

  Future<void> manualSync() async {
    await _syncService.synchronizeData();
  }

  void startMonitoring() {
    _syncService.startMonitoringConnectivity();
  }

  void stopMonitoring() {
    _syncService.stopMonitoringConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _syncEventSubscription.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
