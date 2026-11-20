import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../platform/app_info.dart';
import '../about_sheet.dart';

/// The «About» row on the settings screen.
///
/// It shows the installed version straight away and opens [AboutSheet] with the
/// build number and the licences.
class AboutTile extends StatefulWidget {
  const AboutTile({super.key});

  @override
  State<AboutTile> createState() => _AboutTileState();
}

class _AboutTileState extends State<AboutTile> {
  AppInfo? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await AppInfo.load();
    if (mounted) setState(() => _info = info);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = _info;
    final subtitle = info == null || info.version.isEmpty
        ? s.aboutAppHint
        : '${s.appVersion} ${info.versionLabel}';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          s.aboutApp,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showAboutSheet(context),
      ),
    );
  }
}
