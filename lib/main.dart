import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:offline_sync_app/data/local/local_database_service.dart';
import 'package:offline_sync_app/data/repositories/local_repository_impl.dart';
import 'package:offline_sync_app/data/repositories/remote_repository_impl.dart';
import 'package:offline_sync_app/data/unit_of_work/unit_of_work_impl.dart';
import 'package:offline_sync_app/domain/services/sync_service_impl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_sync_app/presentation/providers/note_provider.dart';
import 'package:offline_sync_app/presentation/providers/sync_provider.dart';
import 'package:offline_sync_app/presentation/screens/home_screen.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local database
  final localDbService = LocalDatabaseService();
  await localDbService.init();
  developer.log('🗄️ Hive Database initialized at: ${localDbService.notesBox.path}');

  // Initialize repositories
  final localRepo = LocalRepositoryImpl(localDbService.notesBox);
  final remoteRepo = RemoteRepositoryImpl(FirebaseFirestore.instance);

  // Initialize Unit of Work
  final unitOfWork = UnitOfWorkImpl(
    localRepository: localRepo,
    remoteRepository: remoteRepo,
  );

  // Initialize services
  final connectivity = Connectivity();
  final syncService = SyncServiceImpl(unitOfWork, connectivity);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NoteProvider(unitOfWork),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(syncService),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Sync Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
