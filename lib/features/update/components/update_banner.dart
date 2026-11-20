import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../bloc/update_bloc.dart';

/// The card on the home screen that announces a newer release.
///
/// It is only built when [UpdateBloc] found something, so a phone without the
/// network and without an update never sees it. The details and the licence
/// list live in the «About» sheet, which the card opens.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, required this.onOpenAbout});

  /// Opens the «About» sheet, where the notes and the install button are.
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<UpdateBloc, UpdateState>(
      buildWhen: (previous, current) =>
          previous.showsBanner != current.showsBanner ||
          previous.update?.version != current.update?.version,
      builder: (context, state) {
        final update = state.update;
        if (!state.showsBanner || update == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: scheme.primaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onOpenAbout,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.system_update, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.updateAvailable(update.version),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.updateBannerHint,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: s.close,
                    onPressed: () =>
                        context.read<UpdateBloc>().add(const UpdateDismissed()),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
