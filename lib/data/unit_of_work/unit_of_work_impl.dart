import 'package:offline_sync_app/data/unit_of_work/i_unit_of_work.dart';
import 'package:offline_sync_app/data/repositories/i_local_repository.dart';
import 'package:offline_sync_app/data/repositories/i_remote_repository.dart';

class UnitOfWorkImpl implements IUnitOfWork {
  @override
  final ILocalRepository localRepository;

  @override
  final IRemoteRepository remoteRepository;

  final List<Future<void> Function()> _pendingOperations = [];

  UnitOfWorkImpl({
    required this.localRepository,
    required this.remoteRepository,
  });

  void addOperation(Future<void> Function() operation) {
    _pendingOperations.add(operation);
  }

  @override
  Future<void> saveChanges() async {
    try {
      for (var operation in _pendingOperations) {
        await operation();
      }
      _pendingOperations.clear();
    } catch (e) {
      await rollback();
      rethrow;
    }
  }

  @override
  Future<void> rollback() async {
    _pendingOperations.clear();
  }

  @override
  void dispose() {
    _pendingOperations.clear();
  }
}
