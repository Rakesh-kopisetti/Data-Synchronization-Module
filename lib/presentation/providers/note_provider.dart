import 'dart:async';
import 'package:flutter/material.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/data/unit_of_work/i_unit_of_work.dart';
import 'package:offline_sync_app/core/constants/enums.dart';
import 'package:uuid/uuid.dart';

class NoteProvider extends ChangeNotifier {
  final IUnitOfWork _unitOfWork;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _noteSubscription;

  NoteProvider(this._unitOfWork);

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _unitOfWork.localRepository.getAllNotes();
      _error = null;
    } catch (e) {
      _error = 'Failed to load notes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNote(String title, String content) async {
    try {
      const uuid = Uuid();
      final note = Note(
        id: uuid.v4(),
        title: title,
        content: content,
        syncStatus: SyncStatus.pending,
        operationType: OperationType.create,
      );

      await _unitOfWork.localRepository.saveNote(note);
      _notes.add(note);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create note: $e';
      notifyListeners();
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    try {
      final note = _notes.firstWhere((n) => n.id == id);
      final updatedNote = note.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        operationType: OperationType.update,
      );

      await _unitOfWork.localRepository.updateNote(updatedNote);
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notes[index] = updatedNote;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final note = _notes.firstWhere((n) => n.id == id);
      note.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.pending,
        operationType: OperationType.delete,
        updatedAt: DateTime.now(),
      );

      await _unitOfWork.localRepository.softDeleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadNotes();
  }

  @override
  void dispose() {
    _noteSubscription?.cancel();
    super.dispose();
  }
}
