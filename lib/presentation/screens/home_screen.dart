import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_sync_app/presentation/providers/note_provider.dart';
import 'package:offline_sync_app/presentation/providers/sync_provider.dart';
import 'package:offline_sync_app/presentation/widgets/sync_status_bar.dart';
import 'package:offline_sync_app/presentation/widgets/note_card.dart';
import 'package:offline_sync_app/presentation/screens/note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final noteProvider = context.read<NoteProvider>();
      final syncProvider = context.read<SyncProvider>();
      
      await noteProvider.loadNotes();
      syncProvider.startMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Notes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Consumer<SyncProvider>(
            builder: (context, syncProvider, _) {
              return SyncStatusBar(
                onRefreshPressed: () async {
                  await syncProvider.manualSync();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sync triggered manually')),
                    );
                  }
                },
              );
            },
          ),
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, noteProvider, _) {
                if (noteProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (noteProvider.notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first note to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await noteProvider.loadNotes();
                  },
                  child: ListView.builder(
                    itemCount: noteProvider.notes.length,
                    itemBuilder: (context, index) {
                      final note = noteProvider.notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NoteDetailScreen(note: note),
                            ),
                          );
                          if (result == true) {
                            await noteProvider.loadNotes();
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Note'),
                              content: const Text(
                                'Are you sure you want to delete this note?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await noteProvider.deleteNote(note.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Note deleted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NoteDetailScreen(note: null),
            ),
          );
          if (result == true) {
            if (mounted) {
              final noteProvider = context.read<NoteProvider>();
              await noteProvider.loadNotes();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    final syncProvider = context.read<SyncProvider>();
    syncProvider.stopMonitoring();
    super.dispose();
  }
}
