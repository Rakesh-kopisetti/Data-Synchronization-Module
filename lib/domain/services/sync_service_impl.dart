import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_sync_app/domain/services/i_sync_service.dart';
import 'package:offline_sync_app/data/unit_of_work/i_unit_of_work.dart';
import 'package:offline_sync_app/core/constants/enums.dart';
import 'package:offline_sync_app/core/constants/app_constants.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'dart:developer' as developer;

class SyncServiceImpl implements ISyncService {
  final IUnitOfWork _unitOfWork;
  final Connectivity _connectivity;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _syncTimer;
  
  ConnectivityStatus _currentConnectivityStatus = ConnectivityStatus.unknown;
  
  final StreamController<ConnectivityStatus> _connectivityStatusController =
      StreamController<ConnectivityStatus>.broadcast();
  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();

  SyncServiceImpl(this._unitOfWork, this._connectivity);

  @override
  Stream<ConnectivityStatus> get connectivityStatusStream =>
      _connectivityStatusController.stream;

  @override
  Stream<SyncEvent> get syncEventStream => _syncEventController.stream;

  @override
  ConnectivityStatus get currentConnectivityStatus => _currentConnectivityStatus;

  @override
  void startMonitoringConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((ConnectivityResult result) {
      _handleConnectivityChange(result);
    });

    // Initial check
    _checkInitialConnectivity();
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final newStatus = _mapConnectivityResult(result);
    
    if (newStatus != _currentConnectivityStatus) {
      _currentConnectivityStatus = newStatus;
      _connectivityStatusController.add(newStatus);
      
      developer.log('Connectivity changed to: $newStatus');
      
      if (newStatus == ConnectivityStatus.online) {
        developer.log('Device is now online, triggering sync');
        _startAutoSync();
      } else {
        _stopAutoSync();
      }
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      developer.log('Error checking initial connectivity: $e');
    }
  }

  ConnectivityStatus _mapConnectivityResult(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return ConnectivityStatus.offline;
    } else if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet) {
      return ConnectivityStatus.online;
    }
    return ConnectivityStatus.unknown;
  }

  void _startAutoSync() {
    _stopAutoSync();
    
    // Immediate sync
    synchronizeData();
    
    // Periodic sync
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      if (_currentConnectivityStatus == ConnectivityStatus.online) {
        synchronizeData();
      }
    });
  }

  void _stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  Future<void> synchronizeData() async {
    if (_currentConnectivityStatus != ConnectivityStatus.online) {
      developer.log('Cannot sync: not online');
      return;
    }

    try {
      _syncEventController.add(SyncEvent(
        type: SyncEventType.started,
        message: 'Synchronization started',
      ));

      developer.log('Starting data synchronization');

      // Get pending operations
      final pendingNotes = await _unitOfWork.localRepository.getPendingNotes();
      
      if (pendingNotes.isNotEmpty) {
        await _syncPendingOperations(pendingNotes);
      }

      // Pull remote changes
      await _pullRemoteChanges();

      _syncEventController.add(SyncEvent(
        type: SyncEventType.completed,
        message: 'Synchronization completed successfully',
      ));

      developer.log('Data synchronization completed');
    } catch (e) {
      developer.log('Sync error: $e', error: e);
      _syncEventController.add(SyncEvent(
        type: SyncEventType.failed,
        message: 'Synchronization failed',
        error: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _syncPendingOperations(List<Note> pendingNotes) async {
    for (var note in pendingNotes) {
      try {
        if (note.isDeleted && note.operationTypeEnum == OperationType.delete) {
          await _unitOfWork.remoteRepository.deleteRemoteNote(note.id);
          await _unitOfWork.localRepository.markNoteAsSync(note.id);
          developer.log('Deleted note: ${note.id}');
        } else if (note.operationTypeEnum == OperationType.create ||
            note.operationTypeEnum == OperationType.update) {
          // Check for conflicts
          final remoteNote = await _unitOfWork.remoteRepository.getRemoteNoteById(note.id);
          
          if (remoteNote != null &&
              remoteNote.updatedAt.isAfter(note.updatedAt)) {
            // Conflict: remote is newer
            _syncEventController.add(SyncEvent(
              type: SyncEventType.conflictResolved,
              message: 'Conflict resolved using remote version for note: ${note.id}',
            ));
            
            // Use remote version (server wins)
            await _unitOfWork.localRepository.updateNote(remoteNote.copyWith(
              syncStatus: SyncStatus.synced,
            ));
            developer.log('Conflict resolved (server wins) for note: ${note.id}');
          } else {
            // No conflict or local is newer
            await _unitOfWork.remoteRepository.saveRemoteNote(note);
            await _unitOfWork.localRepository.markNoteAsSync(note.id);
            developer.log('Synced note: ${note.id}');
          }
        }
      } catch (e) {
        developer.log('Failed to sync note ${note.id}: $e', error: e);
        await _unitOfWork.localRepository.markNoteAsFailed(note.id);
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    try {
      final remoteNotes = await _unitOfWork.remoteRepository.getAllRemoteNotes();
      
      for (var remoteNote in remoteNotes) {
        final localNote = await _unitOfWork.localRepository.getNoteById(remoteNote.id);
        
        if (localNote == null) {
          // New note from remote
          await _unitOfWork.localRepository.saveNote(remoteNote.copyWith(
            syncStatus: SyncStatus.synced,
          ));
          developer.log('Created new local note from remote: ${remoteNote.id}');
        } else if (remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          // Remote is newer
          await _unitOfWork.localRepository.updateNote(remoteNote.copyWith(
            syncStatus: SyncStatus.synced,
          ));
          developer.log('Updated local note from remote: ${remoteNote.id}');
        }
      }
    } catch (e) {
      developer.log('Failed to pull remote changes: $e', error: e);
      throw Exception('Failed to pull remote changes: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _stopAutoSync();
    await _connectivitySubscription.cancel();
    await _connectivityStatusController.close();
    await _syncEventController.close();
  }

  @override
  void stopMonitoringConnectivity() {
    _stopAutoSync();
    _connectivitySubscription.cancel();
  }
}
