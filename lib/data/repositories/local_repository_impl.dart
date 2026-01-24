import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/data/repositories/i_local_repository.dart';
import 'package:offline_sync_app/core/constants/enums.dart';
import 'dart:developer' as developer;

class LocalRepositoryImpl implements ILocalRepository {
  final Box<Note> _box;

  LocalRepositoryImpl(this._box);

  @override
  Future<List<Note>> getAllNotes() async {
    final notes = _box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    developer.log('📂 Loaded ${notes.length} notes from Hive (${_box.path})');
    return notes;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final allNotes = _box.values.toList();
    try {
      return allNotes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveNote(Note note) async {
    await _box.put(note.id, note);
    developer.log('💾 Saved note: ${note.title} to Hive at ${_box.path}');
  }

  @override
  Future<void> updateNote(Note note) async {
    await _box.put(note.id, note);
  }

  @override
  Future<void> deleteNoteById(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> softDeleteNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pending,
        operationType: OperationType.delete,
        updatedAt: DateTime.now(),
      );
      await updateNote(updatedNote);
    }
  }

  @override
  Future<List<Note>> getPendingNotes() async {
    return _box.values
        .where((n) => n.syncStatusEnum == SyncStatus.pending)
        .toList();
  }

  @override
  Future<List<Note>> getFailedNotes() async {
    return _box.values
        .where((n) => n.syncStatusEnum == SyncStatus.failed)
        .toList();
  }

  @override
  Future<void> markNoteAsSync(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        syncStatus: SyncStatus.synced,
      );
      await updateNote(updatedNote);
    }
  }

  @override
  Future<void> markNoteAsFailed(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        syncStatus: SyncStatus.failed,
      );
      await updateNote(updatedNote);
    }
  }

  @override
  Future<void> markNoteAsPending(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(
        syncStatus: SyncStatus.pending,
      );
      await updateNote(updatedNote);
    }
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    for (var note in notes) {
      await _box.put(note.id, note);
    }
  }

  @override
  Future<void> deleteNotes(List<String> ids) async {
    for (var id in ids) {
      await _box.delete(id);
    }
  }

  @override
  Future<List<Note>> getNotesModifiedAfter(DateTime dateTime) async {
    return _box.values
        .where((n) => n.updatedAt.isAfter(dateTime))
        .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<int> getTotalNoteCount() async {
    return _box.length;
  }

  @override
  Future<void> deleteOldSyncedNotes(Duration olderThan) async {
    final cutoffDate = DateTime.now().subtract(olderThan);
    final keysToDelete = <String>[];

    for (var entry in _box.toMap().entries) {
      final note = entry.value;
      if (note.syncStatusEnum == SyncStatus.synced &&
          note.updatedAt.isBefore(cutoffDate)) {
        keysToDelete.add(entry.key as String);
      }
    }

    for (var key in keysToDelete) {
      await _box.delete(key);
    }
  }
}
