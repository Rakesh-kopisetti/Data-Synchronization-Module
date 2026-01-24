import 'package:flutter/material.dart';
import 'package:offline_sync_app/data/models/note_model.dart';
import 'package:offline_sync_app/core/constants/enums.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final syncStatusColor = note.syncStatusEnum == SyncStatus.synced
        ? Colors.green
        : note.syncStatusEnum == SyncStatus.pending
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  dateFormat.format(note.updatedAt),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: syncStatusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    note.syncStatusEnum.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: syncStatusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onTap,
              child: const Text('Edit'),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
