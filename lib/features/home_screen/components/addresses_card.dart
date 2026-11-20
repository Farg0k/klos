import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/l10n.dart';
import '../bloc/home_bloc.dart';

class AddressesCard extends StatelessWidget {
  const AddressesCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final port = state.settings.port;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.kindleAddress,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: state.busy
                      ? null
                      : () => context.read<HomeBloc>().add(
                          const HomeRefreshRequested(),
                        ),
                  tooltip: s.refreshAddresses,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.kindleAddressHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (state.addresses.isEmpty) ...[
              const SizedBox(height: 12),
              Text(s.noIpAddress, style: TextStyle(color: scheme.error)),
            ] else
              for (final address in state.addresses) ...[
                const SizedBox(height: 12),
                SelectableText(
                  address.urlFor(port),
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  address.interfaceName,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            if (state.pin != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.pin_outlined, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    s.pinCode,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                state.pin!,
                style: textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
              ),
              Text(
                s.pinHintOnKindle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (!state.running) ...[
              const SizedBox(height: 12),
              Text(
                s.serverOfflineHint,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
