import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

// Mock repositories for testing
class MockLocalRepository {
  final Map<String, Note> _storage = {};

  Future<List<Note>> getAllNotes() async => _storage.values.toList();
  Future<Note?> getNoteById(String id) async => _storage[id];

  Future<void> saveNote(Note note) async {
    _storage[note.id] = note;
  }

  Future<void> updateNote(Note note) async {
    _storage[note.id] = note;
  }

  Future<void> deleteNoteById(String id) async {
    _storage.remove(id);
  }

  Future<void> markNoteAsSync(String id) async {
    final note = _storage[id];
    if (note != null) {
      _storage[id] = note.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  Future<void> markNoteAsFailed(String id) async {
    final note = _storage[id];
    if (note != null) {
      _storage[id] = note.copyWith(syncStatus: SyncStatus.failed);
    }
  }

  Future<List<Note>> getPendingNotes() async {
    return _storage.values
        .where((n) => n.syncStatusEnum == SyncStatus.pending)
        .toList();
  }

  Future<List<Note>> getFailedNotes() async {
    return _storage.values
        .where((n) => n.syncStatusEnum == SyncStatus.failed)
        .toList();
  }
}

void main() {
  group('Local Repository Tests', () {
    late MockLocalRepository mockRepository;

    setUp(() {
      mockRepository = MockLocalRepository();
    });

    test('Save note stores it in storage', () async {
      final note = Note(
        id: 'test-1',
        title: 'Test Note',
        content: 'Test Content',
      );

      await mockRepository.saveNote(note);
      final retrieved = await mockRepository.getNoteById('test-1');

      expect(retrieved, note);
    });

    test('Get all notes returns all stored notes', () async {
      final note1 = Note(id: 'test-1', title: 'Note 1', content: 'Content 1');
      final note2 = Note(id: 'test-2', title: 'Note 2', content: 'Content 2');

      await mockRepository.saveNote(note1);
      await mockRepository.saveNote(note2);
      final notes = await mockRepository.getAllNotes();

      expect(notes, contains(note1));
      expect(notes, contains(note2));
      expect(notes.length, 2);
    });

    test('Update note modifies existing note', () async {
      final note = Note(id: 'test-1', title: 'Original', content: 'Original');
      await mockRepository.saveNote(note);

      final updated = note.copyWith(title: 'Updated');
      await mockRepository.updateNote(updated);

      final retrieved = await mockRepository.getNoteById('test-1');
      expect(retrieved?.title, 'Updated');
    });

    test('Delete note removes it from storage', () async {
      final note = Note(id: 'test-1', title: 'Test', content: 'Test');
      await mockRepository.saveNote(note);

      await mockRepository.deleteNoteById('test-1');
      final retrieved = await mockRepository.getNoteById('test-1');

      expect(retrieved, null);
    });

    test('Mark note as sync updates sync status', () async {
      final note = Note(id: 'test-1', title: 'Test', content: 'Test');
      await mockRepository.saveNote(note);

      await mockRepository.markNoteAsSync('test-1');
      final retrieved = await mockRepository.getNoteById('test-1');

      expect(retrieved?.syncStatusEnum, SyncStatus.synced);
    });

    test('Get pending notes returns only pending notes', () async {
      final pending = Note(
        id: 'test-1',
        title: 'Pending',
        content: 'Pending',
        syncStatus: SyncStatus.pending,
      );
      final synced = Note(
        id: 'test-2',
        title: 'Synced',
        content: 'Synced',
        syncStatus: SyncStatus.synced,
      );

      await mockRepository.saveNote(pending);
      await mockRepository.saveNote(synced);

      final pendingNotes = await mockRepository.getPendingNotes();
      expect(pendingNotes.length, 1);
      expect(pendingNotes[0].id, 'test-1');
    });

    test('Get failed notes returns only failed notes', () async {
      final failed = Note(
        id: 'test-1',
        title: 'Failed',
        content: 'Failed',
        syncStatus: SyncStatus.failed,
      );
      final synced = Note(
        id: 'test-2',
        title: 'Synced',
        content: 'Synced',
        syncStatus: SyncStatus.synced,
      );

      await mockRepository.saveNote(failed);
      await mockRepository.saveNote(synced);

      final failedNotes = await mockRepository.getFailedNotes();
      expect(failedNotes.length, 1);
      expect(failedNotes[0].id, 'test-1');
    });
  });
}
