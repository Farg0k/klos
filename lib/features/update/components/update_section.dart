import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../../../platform/app_update.dart';
import '../bloc/update_bloc.dart';
import '../release_notes.dart';
import 'release_notes_view.dart';
import 'update_message.dart';

/// The «check for updates / download and install» block of the «About» sheet.
///
/// It reads [UpdateBloc], so the state the automatic check found at launch is
/// already here: opening the sheet after the app started shows the release
/// without asking GitHub again.
class UpdateSection extends StatelessWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<UpdateBloc, UpdateState>(
      builder: (context, state) {
        final update = state.update;
        final percent = state.downloadPercent;
        final seeingChecking = state.status == UpdateStatus.checking;

        if (update == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: state.busy
                      ? null
                      : () => context.read<UpdateBloc>().add(
                          const UpdateCheckRequested(),
                        ),
                  icon: seeingChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    seeingChecking ? s.updateChecking : s.updateCheck,
                  ),
                ),
              ),
              if (state.status == UpdateStatus.upToDate) ...[
                const SizedBox(height: 10),
                Text(
                  s.updateNone,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  describeUpdateError(state.error!, s),
                  style: textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.updateAvailable(update.version),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (parseReleaseNotes(update.notes).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                s.updateNotes,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              ReleaseNotesView(markdown: update.notes),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.busy
                  ? null
                  : () => context.read<UpdateBloc>().add(
                      const UpdateInstallRequested(),
                    ),
              icon: percent != null || state.installing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update),
              label: Text(
                percent == null
                    ? s.updateDownload
                    : s.updateDownloading(percent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.updateInstallHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              Text(
                state.error!.problem == UpdateProblem.download
                    ? s.updateInstallFailed(
                        describeUpdateError(state.error!, s),
                      )
                    : describeUpdateError(state.error!, s),
                style: textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
