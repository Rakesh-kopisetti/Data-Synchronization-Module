import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offline_sync_app/presentation/providers/sync_provider.dart';
import 'package:offline_sync_app/core/constants/enums.dart';

class SyncStatusBar extends StatelessWidget {
  final VoidCallback? onRefreshPressed;

  const SyncStatusBar({super.key, this.onRefreshPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final isOnline = syncProvider.isOnline;
        final backgroundColor =
            isOnline ? Colors.green.shade300 : Colors.red.shade300;
        final statusText = syncProvider.connectivityStatus == ConnectivityStatus.online
            ? 'Online'
            : syncProvider.connectivityStatus == ConnectivityStatus.offline
                ? 'Offline'
                : 'Unknown';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: backgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (syncProvider.syncMessage != null)
                      Text(
                        syncProvider.syncMessage!,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (syncProvider.isSyncing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else if (isOnline)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefreshPressed,
                )
            ],
          ),
        );
      },
    );
  }
}
