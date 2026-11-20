import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entity/app_settings.dart';
import '../../settings_screen/bloc/settings_bloc.dart';

/// The 8 px border used by the settings fields.
const settingsInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

/// Opens one of the server settings sheets from the home screen.
Future<void> showSettingsSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: builder,
  );
}

/// Frame shared by the server settings sheets.
///
/// The sheet scrolls on its own, shrinks when the keyboard opens and stays
/// below the status bar, so the same layout works on small phones.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.onDismiss,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  /// Called when the sheet is closed, so text typed in the last field is not
  /// lost.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) onDismiss?.call();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared edit-and-save behaviour of the server settings sheets.
///
/// Every sheet works on a draft copy of the stored settings. A change is saved
/// immediately, so there is no Save button: switches and chips save on tap,
/// text is saved when the field loses focus or the sheet closes, and values
/// that do not validate are never stored.
abstract class SettingsSheetState<W extends StatefulWidget> extends State<W> {
  /// Settings being edited; starts as a copy of the stored ones.
  late AppSettings draft;

  final _controllers = <TextEditingController>[];
  final _focusNodes = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    draft = context.read<SettingsBloc>().state.settings;
    initFields();
    for (final node in _focusNodes) {
      node.addListener(() {
        if (!node.hasFocus) save();
      });
    }
  }

  /// Copies the stored settings into the controllers of the sheet.
  void initFields();

  /// Copies the typed text into [draft] before it is stored.
  void syncDraft();

  /// Whether the typed values may be stored.
  bool get canSave => true;

  /// Text controller owned by the sheet and disposed with it.
  TextEditingController controller(String text) {
    final value = TextEditingController(text: text);
    _controllers.add(value);
    return value;
  }

  /// Focus node owned by the sheet and disposed with it.
  FocusNode focusNode() {
    final node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  /// Applies a local change and stores it right away.
  void update(VoidCallback change) {
    setState(change);
    save();
  }

  /// Stores the draft when every value is usable.
  void save() {
    if (!mounted) return;
    syncDraft();
    if (!canSave) return;
    context.read<SettingsBloc>().add(SettingsSaved(draft));
  }

  @override
  void dispose() {
    for (final value in _controllers) {
      value.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
