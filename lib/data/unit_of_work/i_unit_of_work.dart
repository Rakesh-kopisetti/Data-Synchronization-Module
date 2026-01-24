import 'package:offline_sync_app/data/repositories/i_local_repository.dart';
import 'package:offline_sync_app/data/repositories/i_remote_repository.dart';

abstract class IUnitOfWork {
  ILocalRepository get localRepository;
  IRemoteRepository get remoteRepository;

  Future<void> saveChanges();
  Future<void> rollback();
  void dispose();
}
