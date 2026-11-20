import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../entity/app_settings.dart';
import '../../generated/l10n.dart';
import '../home_screen/bloc/home_bloc.dart';
import 'components/settings_sheet.dart';
import 'validators.dart';

/// Opens the local server sheet.
Future<void> showServerSheet(BuildContext context) =>
    showSettingsSheet(context, builder: (_) => const ServerSheet());

/// Edits the port, auto-start, automatic stop, PIN and catalog appearance.
class ServerSheet extends StatefulWidget {
  const ServerSheet({super.key});

  @override
  State<ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends SettingsSheetState<ServerSheet> {
  late final TextEditingController _port;
  late final FocusNode _portFocus;

  @override
  void initFields() {
    _port = controller(draft.port.toString());
    _portFocus = focusNode();
  }

  @override
  void syncDraft() {
    final port = int.tryParse(_port.text.trim());
    // Keep the last valid port while the field is being edited.
    draft = draft.copyWith(
      port: port != null && port >= 1024 && port <= 65535 ? port : draft.port,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SettingsSheet(
      icon: Icons.wifi_tethering,
      title: s.localServer,
      onDismiss: save,
      children: [
        TextField(
          controller: _port,
          focusNode: _portFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.port,
            helperText: s.portHelper,
            prefixIcon: const Icon(Icons.settings_ethernet),
            border: settingsInputBorder,
            errorText: validatePort(_port.text, s),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.autoStart),
          subtitle: Text(s.autoStartHint),
          value: draft.autoStart,
          onChanged: (value) => update(() {
            draft = draft.copyWith(autoStart: value);
          }),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: draft.autoStopMinutes,
          decoration: InputDecoration(
            labelText: s.autoStop,
            helperText: s.autoStopHint,
            helperMaxLines: 3,
            prefixIcon: const Icon(Icons.timer_outlined),
            border: settingsInputBorder,
          ),
          items: [
            for (final minutes in AppSettings.autoStopMinutesOptions)
              DropdownMenuItem(
                value: minutes,
                child: Text(
                  minutes == 0 ? s.autoStopOff : s.autoStopMinutes(minutes),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              update(() => draft = draft.copyWith(autoStopMinutes: value));
            }
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.pinProtection),
          subtitle: Text(s.pinProtectionHint),
          value: draft.requirePin,
          onChanged: (value) => update(() {
            draft = draft.copyWith(requirePin: value);
          }),
        ),
        if (draft.requirePin) _PinBox(),
        const Divider(height: 28),
        Text(
          s.catalogAppearance,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.showCovers),
          subtitle: Text(s.showCoversHint),
          value: draft.showCovers,
          onChanged: (value) => update(() {
            draft = draft.copyWith(showCovers: value);
          }),
        ),
      ],
    );
  }
}

/// Shows the current PIN and lets the user replace it.
///
/// The code belongs to the running server, not to the settings draft, so it
/// is read from [HomeBloc] and updates when the server rotates it by itself.
class _PinBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final pin = state.pin;
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.pin_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pinCode,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (pin == null)
                      Text(
                        s.pinStartsWithServer,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        pin,
                        style: textTheme.titleLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                  ],
                ),
              ),
              if (pin != null)
                TextButton(
                  onPressed: () => context.read<HomeBloc>().add(
                    const HomePinRefreshRequested(),
                  ),
                  child: Text(s.pinRefresh),
                ),
            ],
          ),
        );
      },
    );
  }
}
