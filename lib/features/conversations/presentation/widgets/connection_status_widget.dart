// lib/features/conversations/presentation/widgets/connection_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/real_time_providers.dart';

class ConnectionStatusWidget extends ConsumerWidget {
  final bool showAsSnackbar;
  final bool showIcon;

  const ConnectionStatusWidget({
    super.key,
    this.showAsSnackbar = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);

    return connectionStatus.when(
      data: (isConnected) {
        String statusText;
        Color statusColor;
        IconData statusIcon;

        if (isConnected) {
          statusText = 'Bağlı';
          statusColor = Colors.green;
          statusIcon = Icons.wifi;
        } else {
          statusText = 'Çevrimdışı';
          statusColor = Colors.red;
          statusIcon = Icons.wifi_off;
        }

        if (showAsSnackbar && !isConnected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(statusIcon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(statusText),
                  ],
                ),
                backgroundColor: statusColor,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
              ],
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 4),
            ],
            const Text(
              'Bağlanıyor...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              const Icon(Icons.error, size: 14, color: Colors.red),
              const SizedBox(width: 4),
            ],
            const Text(
              'Bağlantı Hatası',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A simpler version for the app bar or status bar
class MiniConnectionStatus extends ConsumerWidget {
  const MiniConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionStatusProvider);

    return connectionStatus.when(
      data: (isConnected) {
        Color statusColor;
        IconData statusIcon;

        if (isConnected) {
          statusColor = Colors.green;
          statusIcon = Icons.circle;
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.circle;
        }

        return Icon(statusIcon, size: 8, color: statusColor);
      },
      loading: () => const SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(strokeWidth: 1),
      ),
      error: (_, __) => const Icon(Icons.circle, size: 8, color: Colors.red),
    );
  }
}
