import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../bloc/home_bloc.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  final HomeState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final running = state.running;

    return Card(
      color: running ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  running ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                  size: 28,
                  color: running ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    running ? s.serverRunning : s.serverStopped,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(running ? s.serverRunningHint : s.serverStoppedHint),
            if (!running && !state.configured) ...[
              const SizedBox(height: 6),
              Text(s.addCatalogFirst, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: running
                  ? OutlinedButton.icon(
                      onPressed: state.busy ? null : onStop,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(s.stopServer),
                    )
                  : FilledButton.icon(
                      onPressed: state.busy || !state.configured
                          ? null
                          : onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(s.startServer),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
