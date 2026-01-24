import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

// Mock UnitOfWork for testing
class MockUnitOfWork {
  final Map<String, Note> _localStorage = {};
  final Map<String, Note> _remoteStorage = {};

  Future<void> createNote(Note note) async {
    _localStorage[note.id] = note;
  }

  Future<void> updateNote(Note note) async {
    final localNote = _localStorage[note.id];
    if (localNote != null) {
      _localStorage[note.id] = note;
    }
  }

  Future<void> syncNote(Note note) async {
    if (note.syncStatusEnum == SyncStatus.pending) {
      _remoteStorage[note.id] = note;
      _localStorage[note.id] = note.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  Future<void> resolveConflict(Note local, Note remote) async {
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      _localStorage[local.id] = remote.copyWith(syncStatus: SyncStatus.synced);
    } else {
      _remoteStorage[local.id] = local;
      _localStorage[local.id] = local.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  Future<void> commit() async {
    // Commit changes
  }

  Future<void> rollback() async {
    _localStorage.clear();
    _remoteStorage.clear();
  }

  Note? getLocalNote(String id) => _localStorage[id];
  Note? getRemoteNote(String id) => _remoteStorage[id];

  List<Note> getPendingNotes() =>
      _localStorage.values.where((n) => n.syncStatusEnum == SyncStatus.pending).toList();
}

void main() {
  group('Unit of Work Tests', () {
    late MockUnitOfWork unitOfWork;

    setUp(() {
      unitOfWork = MockUnitOfWork();
    });

    test('Create note adds to local storage', () async {
      final note = Note(
        id: 'test-1',
        title: 'Test',
        content: 'Content',
      );

      await unitOfWork.createNote(note);
      final retrieved = unitOfWork.getLocalNote('test-1');

      expect(retrieved, note);
    });

    test('Sync note moves from local pending to synced', () async {
      final note = Note(
        id: 'test-1',
        title: 'Test',
        content: 'Content',
        syncStatus: SyncStatus.pending,
      );

      await unitOfWork.createNote(note);
      await unitOfWork.syncNote(note);

      final localNote = unitOfWork.getLocalNote('test-1');
      final remoteNote = unitOfWork.getRemoteNote('test-1');

      expect(localNote?.syncStatusEnum, SyncStatus.synced);
      expect(remoteNote?.syncStatusEnum, SyncStatus.pending);
    });

    test('Resolve conflict uses remote when newer', () async {
      final older = DateTime.now();
      final newer = older.add(const Duration(hours: 1));

      final localNote = Note(
        id: 'test-1',
        title: 'Local',
        content: 'Local',
        updatedAt: older,
        syncStatus: SyncStatus.pending,
      );

      final remoteNote = Note(
        id: 'test-1',
        title: 'Remote',
        content: 'Remote',
        updatedAt: newer,
        syncStatus: SyncStatus.synced,
      );

      await unitOfWork.createNote(localNote);
      await unitOfWork.resolveConflict(localNote, remoteNote);

      final resolved = unitOfWork.getLocalNote('test-1');
      expect(resolved?.title, 'Remote');
      expect(resolved?.syncStatusEnum, SyncStatus.synced);
    });

    test('Get pending notes returns only pending', () async {
      final pending1 = Note(
        id: 'test-1',
        title: 'Pending 1',
        content: 'Pending',
        syncStatus: SyncStatus.pending,
      );
      final pending2 = Note(
        id: 'test-2',
        title: 'Pending 2',
        content: 'Pending',
        syncStatus: SyncStatus.pending,
      );
      final synced = Note(
        id: 'test-3',
        title: 'Synced',
        content: 'Synced',
        syncStatus: SyncStatus.synced,
      );

      await unitOfWork.createNote(pending1);
      await unitOfWork.createNote(pending2);
      await unitOfWork.createNote(synced);

      final pending = unitOfWork.getPendingNotes();
      expect(pending.length, 2);
      expect(pending, contains(pending1));
      expect(pending, contains(pending2));
    });

    test('Rollback clears all storage', () async {
      final note = Note(
        id: 'test-1',
        title: 'Test',
        content: 'Content',
      );

      await unitOfWork.createNote(note);
      await unitOfWork.rollback();

      expect(unitOfWork.getLocalNote('test-1'), null);
      expect(unitOfWork.getRemoteNote('test-1'), null);
    });
  });
}
