import 'package:offline_sync_app/data/models/note_model.dart';

abstract class IRemoteRepository {
  // CRUD Operations
  Future<List<Note>> getAllRemoteNotes();
  Future<Note?> getRemoteNoteById(String id);
  Future<void> saveRemoteNote(Note note);
  Future<void> updateRemoteNote(Note note);
  Future<void> deleteRemoteNote(String id);

  // Sync Operations
  Future<List<Note>> getNotesModifiedAfter(DateTime dateTime);
  Future<Map<String, Note>> getRemoteNotesAsMap();

  // Batch Operations
  Future<void> saveRemoteNotes(List<Note> notes);
  Future<void> deleteRemoteNotes(List<String> ids);
}
