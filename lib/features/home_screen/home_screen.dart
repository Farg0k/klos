import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../generated/l10n.dart';
import '../server_settings/components/settings_sheet.dart';
import '../settings_screen/settings_screen.dart';
import 'bloc/home_bloc.dart';
import 'components/addresses_card.dart';
import 'components/library_card.dart';
import 'components/log_card.dart';
import 'components/server_settings_card.dart';
import 'components/status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return PopScope(
          canPop: !state.running,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmExit(context);
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('KLOS'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => _openSettings(context),
                  tooltip: s.settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                IconButton(
                  onPressed: () => _showHelp(context, state),
                  tooltip: s.help,
                  icon: const Icon(Icons.help_outline),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                StatusCard(
                  state: state,
                  onStart: () =>
                      context.read<HomeBloc>().add(const HomeStartRequested()),
                  onStop: () =>
                      context.read<HomeBloc>().add(const HomeStopRequested()),
                ),
                if (state.lastError != null)
                  ErrorCard(message: state.lastError!),
                AddressesCard(state: state),
                LibraryCard(state: state),
                ServerSettingsCard(state: state),
                LogCard(
                  state: state,
                  onClear: () => context.read<HomeBloc>().add(
                    const HomeClearLogsRequested(),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    s.tagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final s = S.of(context);
    final bloc = context.read<HomeBloc>();
    final stop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.exitDialogTitle),
        content: Text(s.exitDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.stopAndExit),
          ),
        ],
      ),
    );
    if (stop != true) return;

    await bloc.shutdown();
    SystemNavigator.pop();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  void _showHelp(BuildContext context, HomeState state) {
    final s = S.of(context);
    final port = state.settings.port;
    final address = state.addresses.isEmpty
        ? s.addressPlaceholder(port)
        : state.addresses.first.urlFor(port);

    showSettingsSheet(
      context,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SettingsSheet(
          icon: Icons.help_outline,
          title: s.helpTitle,
          children: [
            Text(s.helpStep1),
            const SizedBox(height: 8),
            Text(s.helpStep2),
            const SizedBox(height: 8),
            Text(s.helpStep3),
            const SizedBox(height: 4),
            SelectableText(
              address,
              style: textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(s.helpStep4),
            const SizedBox(height: 8),
            Text(s.helpStep5),
            const SizedBox(height: 12),
            Text(s.webHelpActions, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(s.webHelpFavorites, style: textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(s.helpTip, style: textTheme.bodySmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(s.close),
              ),
            ),
          ],
        );
      },
    );
  }
}
