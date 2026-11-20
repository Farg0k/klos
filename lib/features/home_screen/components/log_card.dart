import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../bloc/home_bloc.dart';

class LogCard extends StatelessWidget {
  const LogCard({super.key, required this.state, required this.onClear});

  final HomeState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final logs = state.logs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  s.log,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: logs.isEmpty ? null : onClear,
                  child: Text(s.clear),
                ),
              ],
            ),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 4),
                child: Text(
                  s.logEmpty,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final line in logs.take(12))
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 3),
                  child: Text(
                    line,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
