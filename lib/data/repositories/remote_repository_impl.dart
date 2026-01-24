import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/data/repositories/i_remote_repository.dart';
import 'package:offline_sync_app/core/constants/app_constants.dart';

class RemoteRepositoryImpl implements IRemoteRepository {
  final FirebaseFirestore _firestore;

  RemoteRepositoryImpl(this._firestore);

  @override
  Future<List<Note>> getAllRemoteNotes() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notesCollection)
          .where('isDeleted', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch remote notes: $e');
    }
  }

  @override
  Future<Note?> getRemoteNoteById(String id) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.notesCollection)
          .doc(id)
          .get();

      if (doc.exists) {
        return Note.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch remote note: $e');
    }
  }

  @override
  Future<void> saveRemoteNote(Note note) async {
    try {
      await _firestore
          .collection(AppConstants.notesCollection)
          .doc(note.id)
          .set(note.toFirestore());
    } catch (e) {
      throw Exception('Failed to save remote note: $e');
    }
  }

  @override
  Future<void> updateRemoteNote(Note note) async {
    try {
      await _firestore
          .collection(AppConstants.notesCollection)
          .doc(note.id)
          .update(note.toFirestore());
    } catch (e) {
      throw Exception('Failed to update remote note: $e');
    }
  }

  @override
  Future<void> deleteRemoteNote(String id) async {
    try {
      await _firestore
          .collection(AppConstants.notesCollection)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete remote note: $e');
    }
  }

  @override
  Future<List<Note>> getNotesModifiedAfter(DateTime dateTime) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.notesCollection)
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(dateTime))
          .where('isDeleted', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch modified remote notes: $e');
    }
  }

  @override
  Future<Map<String, Note>> getRemoteNotesAsMap() async {
    try {
      final notes = await getAllRemoteNotes();
      return {for (var note in notes) note.id: note};
    } catch (e) {
      throw Exception('Failed to fetch remote notes as map: $e');
    }
  }

  @override
  Future<void> saveRemoteNotes(List<Note> notes) async {
    try {
      final batch = _firestore.batch();
      for (var note in notes) {
        final ref = _firestore
            .collection(AppConstants.notesCollection)
            .doc(note.id);
        batch.set(ref, note.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save batch remote notes: $e');
    }
  }

  @override
  Future<void> deleteRemoteNotes(List<String> ids) async {
    try {
      final batch = _firestore.batch();
      for (var id in ids) {
        final ref = _firestore
            .collection(AppConstants.notesCollection)
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete batch remote notes: $e');
    }
  }
}
