import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

void main() {
  group('Note Model Tests', () {
    test('Note creation with default values', () {
      final note = Note(
        title: 'Test',
        content: 'Content',
      );

      expect(note.title, 'Test');
      expect(note.content, 'Content');
      expect(note.isDeleted, false);
      expect(note.syncStatusEnum, SyncStatus.pending);
    });

    test('Note.toMap and Note.fromMap', () {
      final originalNote = Note(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
      );

      final map = originalNote.toMap();
      final recoveredNote = Note.fromMap(map);

      expect(recoveredNote.id, originalNote.id);
      expect(recoveredNote.title, originalNote.title);
      expect(recoveredNote.content, originalNote.content);
    });

    test('Note.copyWith creates new instance with updated values', () {
      final originalNote = Note(
        id: 'test-id',
        title: 'Original',
        content: 'Original Content',
      );

      final updatedNote = originalNote.copyWith(
        title: 'Updated',
        syncStatus: SyncStatus.synced,
      );

      expect(updatedNote.title, 'Updated');
      expect(updatedNote.content, originalNote.content);
      expect(updatedNote.syncStatusEnum, SyncStatus.synced);
    });

    test('Note equality comparison', () {
      final note1 = Note(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
      );

      final note2 = Note(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
      );

      expect(note1, note2);
    });

    test('Note toString shows expected format', () {
      final note = Note(
        id: 'test-id',
        title: 'Test',
        content: 'Content',
      );

      final string = note.toString();
      expect(string, contains('test-id'));
      expect(string, contains('Test'));
    });
  });
}
