import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../../platform/app_info.dart';
import '../server_settings/components/settings_sheet.dart';
import '../update/components/update_section.dart';
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
  const AboutSheet({super.key});

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  AppInfo? _info;
  List<String>? _packages;

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
        const UpdateSection(),
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
