import 'package:offline_sync_app/data/models/note_model.dart';

abstract class ILocalRepository {
  // CRUD Operations
  Future<List<Note>> getAllNotes();
  Future<Note?> getNoteById(String id);
  Future<void> saveNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNoteById(String id);
  Future<void> softDeleteNote(String id);

  // Sync Operations
  Future<List<Note>> getPendingNotes();
  Future<List<Note>> getFailedNotes();
  Future<void> markNoteAsSync(String id);
  Future<void> markNoteAsFailed(String id);
  Future<void> markNoteAsPending(String id);

  // Batch Operations
  Future<void> saveNotes(List<Note> notes);
  Future<void> deleteNotes(List<String> ids);

  // Query Operations
  Future<List<Note>> getNotesModifiedAfter(DateTime dateTime);
  Future<int> getTotalNoteCount();
  Future<void> deleteOldSyncedNotes(Duration olderThan);
}
