import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

/// Licence of every library bundled into the app.
///
/// Flutter collects them in [LicenseRegistry] — the same data the built-in
/// licence page reads. klos renders it in its own style instead, so the screen
/// matches the rest of the app.
Future<List<LicenseEntry>> loadLicenses() async {
  final entries = await LicenseRegistry.licenses.toList();
  entries.sort((a, b) => _label(a).compareTo(_label(b)));
  return entries;
}

/// Names of the libraries that published a licence, sorted and without
/// duplicates. Used for the summary in the «About» sheet.
Future<List<String>> loadLicensedPackages() async {
  final names = <String>{};
  for (final entry in await loadLicenses()) {
    for (final package in entry.packages) {
      final name = package.trim();
      if (name.isNotEmpty && name != 'FLUTTER') names.add(name);
    }
  }
  return names.toList()..sort();
}

/// The full licence texts, grouped per package.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  List<LicenseEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await loadLicenses();
    if (mounted) setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entries = _entries;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.licenses)),
      body: entries == null
          ? Center(child: Text(s.licensesLoading))
          : entries.isEmpty
          ? Center(child: Text(s.licensesEmpty))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  s.licensesPackages,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in entries)
                  Card(
                    child: ExpansionTile(
                      shape: shape,
                      collapsedShape: shape,
                      title: Text(
                        _label(entry),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final paragraph in entry.paragraphs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              paragraph.text,
                              style: textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

String _label(LicenseEntry entry) =>
    entry.packages.where((package) => package.trim().isNotEmpty).join(', ');
