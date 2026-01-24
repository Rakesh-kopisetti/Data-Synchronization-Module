enum SyncStatus {
  pending,
  synced,
  failed,
}

enum SyncEventType {
  started,
  completed,
  failed,
  conflictResolved,
}

enum OperationType {
  create,
  update,
  delete,
}

enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }
}
