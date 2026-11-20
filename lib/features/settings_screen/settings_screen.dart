import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/info_box.dart';
import '../../components/settings_card.dart';
import '../../entity/app_settings.dart';
import '../../generated/l10n.dart';
import '../about/components/about_tile.dart';
import 'bloc/settings_bloc.dart';

/// App preferences: the interface language, the theme and the wake lock.
///
/// Everything that changes the local server or what the Kindle sees is edited
/// on the main screen instead, in the server settings sheets.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppLanguage _language;
  late AppThemeMode _themeMode;
  late bool _keepAwake;
  bool _justSaved = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsBloc>().state.settings;
    _language = settings.language;
    _themeMode = settings.themeMode;
    _keepAwake = settings.keepAwake;
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).saveFailed(state.error!))),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.settings),
          actions: [
            AnimatedOpacity(
              opacity: _justSaved ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Tooltip(
                  message: s.settingsSaved,
                  child: Icon(Icons.check_circle, color: scheme.primary),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              s.settingsAutoSaveHint,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SettingsCard(
              icon: Icons.language,
              title: s.language,
              children: [
                DropdownButtonFormField<AppLanguage>(
                  initialValue: _language,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.language),
                    helperText: s.languageHint,
                    helperMaxLines: 2,
                    border: _inputBorder,
                  ),
                  items: [
                    for (final language in AppLanguage.values)
                      DropdownMenuItem(
                        value: language,
                        child: Text(_languageLabel(language, s)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _update(() => _language = value);
                    }
                  },
                ),
              ],
            ),
            SettingsCard(
              icon: Icons.brightness_6_outlined,
              title: s.theme,
              children: [
                Text(
                  s.themeHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<AppThemeMode>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(s.themeSystem),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(s.themeLight),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(s.themeDark),
                    ),
                  ],
                  selected: {_themeMode},
                  onSelectionChanged: (selection) =>
                      _update(() => _themeMode = selection.first),
                ),
              ],
            ),
            SettingsCard(
              icon: Icons.lightbulb_outline,
              title: s.keepAwake,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.keepAwakeHint,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _keepAwake,
                      onChanged: (value) => _update(() => _keepAwake = value),
                    ),
                  ],
                ),
              ],
            ),
            const AboutTile(),
            InfoBox(icon: Icons.wifi_tethering, text: s.serverSettingsHint),
            const SizedBox(height: 12),
            InfoBox(icon: Icons.shield_outlined, text: s.securityInfo),
          ],
        ),
      ),
    );
  }

  /// Applies a local change and saves it right away.
  void _update(VoidCallback change) {
    setState(change);
    final next = context.read<SettingsBloc>().state.settings.copyWith(
      language: _language,
      themeMode: _themeMode,
      keepAwake: _keepAwake,
    );
    context.read<SettingsBloc>().add(SettingsSaved(next));
    _flashSaved();
  }

  void _flashSaved() {
    if (!mounted) return;
    setState(() => _justSaved = true);
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justSaved = false);
    });
  }

  static String _languageLabel(AppLanguage language, S s) {
    switch (language) {
      case AppLanguage.system:
        return s.languageSystem;
      case AppLanguage.english:
        return 'English';
      case AppLanguage.ukrainian:
        return 'Українська';
    }
  }
}

/// The 8 px radius used by the fields, matching the app theme.
const _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
);
