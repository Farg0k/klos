import 'package:flutter/material.dart';

import '../../../entity/app_settings.dart';
import '../../../generated/l10n.dart';
import '../../server_settings/catalog_sheet.dart';
import '../../server_settings/folder_sheet.dart';
import '../../server_settings/kindle_mail_sheet.dart';
import '../../server_settings/server_sheet.dart';
import '../bloc/home_bloc.dart';

/// The server settings, grouped by topic.
///
/// Everything that changes what the Kindle sees lives here, on the main
/// screen; the settings screen keeps only app preferences. Each row opens a
/// bottom sheet so the main screen stays short and readable.
class ServerSettingsCard extends StatelessWidget {
  const ServerSettingsCard({super.key, required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settings = state.settings;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s.serverSettings,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _MenuTile(
            onTap: () => showCatalogSheet(context),
            leading: const Icon(Icons.menu_book_outlined),
            title: s.catalog,
            subtitle: settings.catalogUrl?.toString() ?? s.catalogNotSet,
            active: settings.isConfigured,
          ),
          const Divider(height: 1),
          _MenuTile(
            onTap: () => showFolderSheet(context),
            leading: Icon(
              settings.hasLocalFolder
                  ? Icons.folder_open
                  : Icons.folder_outlined,
            ),
            title: s.localFiles,
            subtitle: settings.hasLocalFolder
                ? (settings.localFolderName.trim().isEmpty
                      ? s.localFolderDefaultName
                      : settings.localFolderName)
                : s.localFolderNotConnectedShort,
            active: settings.hasLocalFolder,
          ),
          const Divider(height: 1),
          _MenuTile(
            onTap: () => showServerSheet(context),
            leading: const Icon(Icons.wifi_tethering),
            title: s.localServer,
            subtitle: _serverSubtitle(settings, s),
            active: state.running,
            maxLines: 3,
          ),
          const Divider(height: 1),
          _MenuTile(
            onTap: () => showKindleMailSheet(context),
            leading: Icon(
              settings.hasKindleEmail
                  ? Icons.mark_email_read_outlined
                  : Icons.outgoing_mail,
            ),
            title: s.kindleMail,
            subtitle: _mailSubtitle(settings, s),
            active: settings.hasKindleEmail,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  static String _serverSubtitle(AppSettings settings, S s) {
    final parts = <String>['${s.port} ${settings.port}'];
    if (settings.autoStart) parts.add(s.autoStartShort);
    if (settings.keepAwake) parts.add(s.keepAwakeShort);
    if (settings.requirePin) parts.add(s.pinShort);
    return parts.join(' · ');
  }

  static String _mailSubtitle(AppSettings settings, S s) {
    if (!settings.hasKindleEmail) return s.kindleEmailMissing;
    return '${settings.kindleEmail}\n'
        '${settings.smtpConfigured ? s.deliverySmtp : s.smtpNotConfigured}';
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.active,
    this.maxLines = 2,
  });

  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool active;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: IconTheme(
        data: IconThemeData(
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
        child: leading,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      isThreeLine: maxLines > 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    );
  }
}
