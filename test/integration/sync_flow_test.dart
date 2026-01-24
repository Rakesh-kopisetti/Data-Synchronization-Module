import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

/// Integration test for the complete sync flow
///
/// This test simulates the end-to-end data synchronization process:
/// 1. User creates notes while offline
/// 2. Operations are queued locally
/// 3. Network comes online
/// 4. Queued operations are automatically synced
/// 5. Remote and local data are consistent
void main() {
  group('End-to-End Sync Flow Integration Tests', () {
    late MockLocalRepository localRepo;
    late MockRemoteRepository remoteRepo;
    late MockSyncOrchestrator syncOrchestrator;

    setUp(() {
      localRepo = MockLocalRepository();
      remoteRepo = MockRemoteRepository();
      syncOrchestrator = MockSyncOrchestrator(localRepo, remoteRepo);
    });

    test('Complete offline sync flow', () async {
      // Scenario 1: Offline operations
      final note1 = Note(
        id: 'note-1',
        title: 'Offline Note 1',
        content: 'Created offline',
        syncStatus: SyncStatus.pending,
      );

      final note2 = Note(
        id: 'note-2',
        title: 'Offline Note 2',
        content: 'Also created offline',
        syncStatus: SyncStatus.pending,
      );

      // User creates notes while offline
      await localRepo.saveNote(note1);
      await localRepo.saveNote(note2);

      // Verify notes are stored locally but not synced
      final localNotes = await localRepo.getAllNotes();
      expect(localNotes.length, 2);

      final pendingNotes = await localRepo.getPendingNotes();
      expect(pendingNotes.length, 2);

      // Remote should not have notes yet
      final remoteNotes = await remoteRepo.getAllRemoteNotes();
      expect(remoteNotes.length, 0);

      // Scenario 2: Network comes online, trigger sync
      await syncOrchestrator.synchronize();

      // Verify sync completed
      final syncedPendingNotes = await localRepo.getPendingNotes();
      expect(syncedPendingNotes.length, 0);

      // Verify notes are now on remote
      final syncedRemoteNotes = await remoteRepo.getAllRemoteNotes();
      expect(syncedRemoteNotes.length, 2);

      // Verify local notes are marked as synced
      final localNote1 = await localRepo.getNoteById('note-1');
      expect(localNote1?.syncStatusEnum, SyncStatus.synced);

      final localNote2 = await localRepo.getNoteById('note-2');
      expect(localNote2?.syncStatusEnum, SyncStatus.synced);
    });

    test('Update operation sync flow', () async {
      // Create and sync a note
      final note = Note(
        id: 'note-1',
        title: 'Original Title',
        content: 'Original Content',
        syncStatus: SyncStatus.synced,
      );

      await localRepo.saveNote(note);
      await remoteRepo.saveRemoteNote(note);

      // User modifies note offline
      final updated = note.copyWith(
        title: 'Updated Title',
        syncStatus: SyncStatus.pending,
      );
      await localRepo.updateNote(updated);

      // Trigger sync
      await syncOrchestrator.synchronize();

      // Verify remote is updated
      final remoteNote = await remoteRepo.getRemoteNoteById('note-1');
      expect(remoteNote?.title, 'Updated Title');

      // Verify local is marked as synced
      final localNote = await localRepo.getNoteById('note-1');
      expect(localNote?.syncStatusEnum, SyncStatus.synced);
    });

    test('Conflict resolution during sync', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));

      // Local note is older
      final localNote = Note(
        id: 'note-1',
        title: 'Local Version',
        content: 'Local',
        updatedAt: earlier,
        syncStatus: SyncStatus.pending,
      );

      // Remote note is newer
      final remoteNote = Note(
        id: 'note-1',
        title: 'Remote Version',
        content: 'Remote',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

      await localRepo.saveNote(localNote);
      await remoteRepo.saveRemoteNote(remoteNote);

      // Trigger sync (should resolve conflict, remote wins)
      await syncOrchestrator.synchronize();

      // Local should be updated to remote version
      final resolvedLocal = await localRepo.getNoteById('note-1');
      expect(resolvedLocal?.title, 'Remote Version');
      expect(resolvedLocal?.content, 'Remote');
    });

    test('Delete operation sync flow', () async {
      // Create note
      final note = Note(
        id: 'note-1',
        title: 'To Delete',
        content: 'Will be deleted',
      );

      await localRepo.saveNote(note);
      await remoteRepo.saveRemoteNote(note);

      // Soft delete locally
      await localRepo.softDeleteNote('note-1');

      // Verify soft delete (still in local but marked as deleted)
      final deletedNote = await localRepo.getNoteById('note-1');
      expect(deletedNote?.isDeleted, true);

      // Trigger sync
      await syncOrchestrator.synchronize();

      // Remote should be deleted
      final remoteNote = await remoteRepo.getRemoteNoteById('note-1');
      expect(remoteNote, null);
    });

    test('Multiple sequential operations sync', () async {
      // Create multiple notes in sequence
      const operations = 5;
      final notes = <Note>[];

      for (int i = 0; i < operations; i++) {
        final note = Note(
          id: 'note-$i',
          title: 'Note $i',
          content: 'Content $i',
        );
        notes.add(note);
        await localRepo.saveNote(note);
      }

      // Verify all pending
      final pending = await localRepo.getPendingNotes();
      expect(pending.length, operations);

      // Sync
      await syncOrchestrator.synchronize();

      // Verify all synced
      final synced = await localRepo.getPendingNotes();
      expect(synced.length, 0);

      final remoteNotes = await remoteRepo.getAllRemoteNotes();
      expect(remoteNotes.length, operations);
    });

    test('Sync with mixed operations', () async {
      // Create some notes
      final note1 = Note(id: 'note-1', title: 'Note 1', content: 'Content 1');
      final note2 = Note(id: 'note-2', title: 'Note 2', content: 'Content 2');

      await localRepo.saveNote(note1);
      await localRepo.saveNote(note2);

      // Sync first batch
      await syncOrchestrator.synchronize();

      // Verify both synced
      var pendingNotes = await localRepo.getPendingNotes();
      expect(pendingNotes.length, 0);

      // Update note1
      final updated = note1.copyWith(
        title: 'Updated Note 1',
        syncStatus: SyncStatus.pending,
      );
      await localRepo.updateNote(updated);

      // Delete note2
      await localRepo.softDeleteNote('note-2');

      // Create note3
      final note3 = Note(id: 'note-3', title: 'Note 3', content: 'Content 3');
      await localRepo.saveNote(note3);

      // Sync all changes
      await syncOrchestrator.synchronize();

      // Verify all synced
      pendingNotes = await localRepo.getPendingNotes();
      expect(pendingNotes.length, 0);

      // Verify remote state
      final remoteNote1 = await remoteRepo.getRemoteNoteById('note-1');
      expect(remoteNote1?.title, 'Updated Note 1');

      final remoteNote2 = await remoteRepo.getRemoteNoteById('note-2');
      expect(remoteNote2, null);

      final remoteNote3 = await remoteRepo.getRemoteNoteById('note-3');
      expect(remoteNote3?.title, 'Note 3');
    });
  });
}

// Mock implementations for integration testing
class MockLocalRepository {
  final Map<String, Note> _storage = {};

  Future<List<Note>> getAllNotes() async => _storage.values.toList();
  Future<Note?> getNoteById(String id) async => _storage[id];
  Future<void> saveNote(Note note) async => _storage[note.id] = note;

  Future<void> updateNote(Note note) async {
    _storage[note.id] = note;
  }

  Future<void> softDeleteNote(String id) async {
    final note = _storage[id];
    if (note != null) {
      _storage[id] = note.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pending,
      );
    }
  }

  Future<List<Note>> getPendingNotes() async {
    return _storage.values
        .where((n) => n.syncStatusEnum == SyncStatus.pending)
        .toList();
  }

  Future<void> markNoteAsSync(String id) async {
    final note = _storage[id];
    if (note != null) {
      _storage[id] = note.copyWith(syncStatus: SyncStatus.synced);
    }
  }
}

class MockRemoteRepository {
  final Map<String, Note> _storage = {};

  Future<List<Note>> getAllRemoteNotes() async {
    return _storage.values.where((n) => !n.isDeleted).toList();
  }

  Future<Note?> getRemoteNoteById(String id) async {
    final note = _storage[id];
    return note?.isDeleted == true ? null : note;
  }

  Future<void> saveRemoteNote(Note note) async => _storage[note.id] = note;

  Future<void> deleteRemoteNote(String id) async {
    _storage.remove(id);
  }
}

class MockSyncOrchestrator {
  final MockLocalRepository _localRepo;
  final MockRemoteRepository _remoteRepo;

  MockSyncOrchestrator(this._localRepo, this._remoteRepo);

  Future<void> synchronize() async {
    // Get pending operations
    final pendingNotes = await _localRepo.getPendingNotes();

    for (var note in pendingNotes) {
      if (note.isDeleted) {
        // Delete operation
        await _remoteRepo.deleteRemoteNote(note.id);
        await _localRepo.markNoteAsSync(note.id);
      } else {
        // Create or update operation
        final remoteNote = await _remoteRepo.getRemoteNoteById(note.id);

        if (remoteNote != null &&
            remoteNote.updatedAt.isAfter(note.updatedAt)) {
          // Conflict: remote is newer, use remote
          // Update local with remote
        } else {
          // No conflict or local is newer, sync to remote
          await _remoteRepo.saveRemoteNote(note);
          await _localRepo.markNoteAsSync(note.id);
        }
      }
    }
  }
}
