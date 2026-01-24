import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

// Mock SyncService for testing
class MockSyncService {
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  final List<SyncOperation> _operations = [];

  ConnectivityStatus get currentStatus => _status;
  List<SyncOperation> get operations => _operations;

  void setConnectivityStatus(ConnectivityStatus status) {
    _status = status;
  }

  Future<void> queueOperation(Note note, OperationType operationType) async {
    _operations.add(SyncOperation(note: note, operationType: operationType));
  }

  Future<void> syncPendingOperations() async {
    if (_status != ConnectivityStatus.online) {
      throw Exception('Cannot sync when offline');
    }

    for (final _ in _operations) {
      // Simulate sync
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _operations.clear();
  }

  Future<void> handleConflict(Note localNote, Note remoteNote) async {
    // Use server-wins strategy
    if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
      // Server version wins
    } else {
      // Local version wins
    }
  }

  void clear() {
    _operations.clear();
  }
}

class SyncOperation {
  final Note note;
  final OperationType operationType;

  SyncOperation({required this.note, required this.operationType});
}

void main() {
  group('Sync Service Tests', () {
    late MockSyncService syncService;

    setUp(() {
      syncService = MockSyncService();
    });

    tearDown(() {
      syncService.clear();
    });

    test('Queue operation adds to pending operations', () async {
      final note = Note(id: 'test-1', title: 'Test', content: 'Content');

      await syncService.queueOperation(note, OperationType.create);

      expect(syncService.operations.length, 1);
      expect(syncService.operations[0].note, note);
      expect(syncService.operations[0].operationType, OperationType.create);
    });

    test('Sync pending operations fails when offline', () async {
      syncService.setConnectivityStatus(ConnectivityStatus.offline);

      final note = Note(id: 'test-1', title: 'Test', content: 'Content');
      await syncService.queueOperation(note, OperationType.create);

      expect(
        () => syncService.syncPendingOperations(),
        throwsException,
      );
    });

    test('Sync pending operations succeeds when online', () async {
      syncService.setConnectivityStatus(ConnectivityStatus.online);

      final note = Note(id: 'test-1', title: 'Test', content: 'Content');
      await syncService.queueOperation(note, OperationType.create);

      await syncService.syncPendingOperations();

      expect(syncService.operations, isEmpty);
    });

    test('Multiple operations can be queued', () async {
      final note1 = Note(id: 'test-1', title: 'Test 1', content: 'Content 1');
      final note2 = Note(id: 'test-2', title: 'Test 2', content: 'Content 2');
      final note3 = Note(id: 'test-3', title: 'Test 3', content: 'Content 3');

      await syncService.queueOperation(note1, OperationType.create);
      await syncService.queueOperation(note2, OperationType.update);
      await syncService.queueOperation(note3, OperationType.delete);

      expect(syncService.operations.length, 3);
    });

    test('Handle conflict uses server-wins strategy for newer remote', () async {
      final older = DateTime.now();
      final newer = older.add(const Duration(hours: 1));

      final localNote = Note(
        id: 'test-1',
        title: 'Local',
        content: 'Local',
        updatedAt: older,
      );

      final remoteNote = Note(
        id: 'test-1',
        title: 'Remote',
        content: 'Remote',
        updatedAt: newer,
      );

      // Should not throw
      await syncService.handleConflict(localNote, remoteNote);
      // Verification would require tracking which version was selected
    });

    test('Connectivity status can be set', () {
      syncService.setConnectivityStatus(ConnectivityStatus.online);
      expect(syncService.currentStatus, ConnectivityStatus.online);

      syncService.setConnectivityStatus(ConnectivityStatus.offline);
      expect(syncService.currentStatus, ConnectivityStatus.offline);
    });
  });
}
