import 'package:hive_flutter/hive_flutter.dart';
import 'package:offline_sync_app/data/models/note_model.dart';

class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  late Box<Note> _notesBox;

  LocalDatabaseService._internal();

  factory LocalDatabaseService() {
    _instance ??= LocalDatabaseService._internal();
    return _instance!;
  }

  Box<Note> get notesBox => _notesBox;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(NoteAdapter());
      _notesBox = await Hive.openBox<Note>('notes');
    } catch (e) {
      throw Exception('Failed to initialize local database: $e');
    }
  }

  Future<void> close() async {
    await _notesBox.close();
  }

  // Clear all data
  Future<void> clearAll() async {
    await _notesBox.clear();
  }

  // Health check
  Future<bool> isHealthy() async {
    try {
      _notesBox.length;
      return true;
    } catch (e) {
      return false;
    }
  }
}
