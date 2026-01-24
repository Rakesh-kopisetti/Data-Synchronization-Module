class AppConstants {
  // Firestore Collections
  static const String notesCollection = 'notes';

  // Sync
  static const Duration syncInterval = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Database
  static const String isarDbName = 'offline_sync_app';

  // Timestamps
  static const String timestampFieldName = 'timestamp';
}

class ErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String syncError = 'Failed to synchronize data. Please try again.';
  static const String databaseError = 'Database operation failed.';
  static const String conflictError = 'Data conflict detected. Latest version has been applied.';
  static const String firebaseError = 'Firebase operation failed.';
  static const String unknown = 'An unknown error occurred.';
}

class SuccessMessages {
  static const String syncCompleted = 'Data synchronized successfully.';
  static const String noteSaved = 'Note saved successfully.';
  static const String noteDeleted = 'Note deleted successfully.';
}
