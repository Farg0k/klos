import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../../platform/app_info.dart';
import '../../platform/app_update.dart';
import '../server_settings/components/settings_sheet.dart';
import 'licenses_page.dart';

/// Opens the «About» sheet.
Future<void> showAboutSheet(BuildContext context) =>
    showSettingsSheet(context, builder: (_) => const AboutSheet());

/// Shows the app version, the build number, the update check and the licences
/// of the libraries klos is built on.
///
/// The version comes from the installed package, so it always matches the APK;
/// the licences come from Flutter's [LicenseRegistry], so they never go stale.
class AboutSheet extends StatefulWidget {
  const AboutSheet({super.key, this.updateService});

  /// Replaced in tests, where the network and the installer are unavailable.
  final AppUpdateService? updateService;

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  AppInfo? _info;
  List<String>? _packages;

  late final AppUpdateService _updates =
      widget.updateService ?? AppUpdateService();

  bool _checking = false;
  AppUpdate? _update;
  int? _downloadedPercent;
  bool _installing = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AppInfo.load();
    final packages = await loadLicensedPackages();
    if (!mounted) return;
    setState(() {
      _info = info;
      _packages = packages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = _info;
    final packages = _packages;

    return SettingsSheet(
      icon: Icons.info_outline,
      title: s.aboutApp,
      children: [
        Text(s.aboutDescription),
        const SizedBox(height: 16),
        _InfoRow(label: s.appVersion, value: info?.version),
        _InfoRow(label: s.appBuild, value: info?.buildNumber),
        if (info != null && info.packageName.isNotEmpty)
          _InfoRow(label: s.appPackage, value: info.packageName),
        const SizedBox(height: 12),
        _buildUpdateSection(context, s, scheme, textTheme),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          s.licenses,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          s.licensesHint,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (packages == null)
          Text(s.licensesLoading, style: textTheme.bodySmall)
        else if (packages.isEmpty)
          Text(s.licensesEmpty, style: textTheme.bodySmall)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in packages)
                Chip(
                  label: Text(name, style: textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: scheme.outlineVariant),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LicensesPage()),
            ),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: Text(s.licensesFullText),
          ),
        ),
      ],
    );
  }

  /// The «Check for updates» block.
  ///
  /// A found release shows its notes and one button that downloads the APK and
  /// opens the Android installer; Android then updates the app in place.
  Widget _buildUpdateSection(
    BuildContext context,
    S s,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final update = _update;
    final busy = _checking || _downloadedPercent != null || _installing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (update != null) ...[
          Text(
            s.updateAvailable(update.version),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (update.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              s.updateNotes,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(update.notes, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : () => _install(update),
            icon: _installing || _downloadedPercent != null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update),
            label: Text(_buttonLabel(s)),
          ),
          const SizedBox(height: 8),
          Text(
            s.updateInstallHint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _check,
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(_checking ? s.updateChecking : s.updateCheck),
            ),
          ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(
            _message!,
            style: textTheme.bodySmall?.copyWith(
              color: _messageIsError ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _buttonLabel(S s) {
    final percent = _downloadedPercent;
    if (percent != null) return s.updateDownloading(percent);
    return s.updateDownload;
  }

  /// Asks GitHub for a newer release.
  Future<void> _check() async {
    final info = _info ?? await AppInfo.load();
    if (!mounted) return;
    setState(() {
      _checking = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final abis = await _updates.deviceAbis();
      final update = await _updates.check(
        currentVersion: info.version,
        abis: abis,
      );
      if (!mounted) return;
      setState(() {
        _update = update;
        if (update == null) _message = S.of(context).updateNone;
      });
    } on UpdateException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _describe(error, S.of(context));
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = S.of(context).updateFailed('$error');
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// Downloads the APK and hands it to the Android installer.
  Future<void> _install(AppUpdate update) async {
    setState(() {
      _downloadedPercent = 0;
      _message = null;
      _messageIsError = false;
    });

    try {
      final path = await _updates.download(
        update,
        onProgress: (percent) {
          if (mounted) setState(() => _downloadedPercent = percent);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadedPercent = null;
        _installing = true;
      });
      await _updates.install(path);
    } on UpdateException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _describe(error, S.of(context));
        _messageIsError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = S.of(context).updateInstallFailed('$error');
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _downloadedPercent = null;
          _installing = false;
        });
      }
    }
  }

  /// Turns an [UpdateProblem] into a message in the current language.
  static String _describe(UpdateException error, S s) {
    switch (error.problem) {
      case UpdateProblem.github:
        final status = int.tryParse(error.detail);
        if (status != null) return s.updateErrorGithub(status);
        return s.updateFailed(error.detail);
      case UpdateProblem.network:
        return s.updateErrorNetwork(error.detail);
      case UpdateProblem.noApk:
        return s.updateErrorNoApk;
      case UpdateProblem.download:
        return s.updateErrorDownload;
      case UpdateProblem.unknownVersion:
        return s.updateFailed(s.unknownError);
    }
  }
}

/// A label and its value, used for the version rows.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '…',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
