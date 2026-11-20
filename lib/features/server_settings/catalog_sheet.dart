import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../entity/app_settings.dart';
import '../../generated/l10n.dart';
import '../../opds/opds_client.dart';
import '../settings_screen/bloc/settings_bloc.dart';
import 'components/settings_sheet.dart';
import 'components/sheet_result.dart';
import 'validators.dart';

/// Opens the OPDS catalog sheet.
Future<void> showCatalogSheet(BuildContext context) =>
    showSettingsSheet(context, builder: (_) => const CatalogSheet());

/// Edits the OPDS catalog address and its optional Basic credentials.
class CatalogSheet extends StatefulWidget {
  const CatalogSheet({super.key});

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends SettingsSheetState<CatalogSheet> {
  late final TextEditingController _url;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final FocusNode _urlFocus;
  late final FocusNode _userFocus;
  late final FocusNode _passwordFocus;

  bool _obscurePassword = true;
  bool _testing = false;
  String? _message;
  bool _ok = false;

  @override
  void initFields() {
    _url = controller(draft.catalogUrl?.toString() ?? '');
    _user = controller(draft.username);
    _password = controller(draft.password);
    _urlFocus = focusNode();
    _userFocus = focusNode();
    _passwordFocus = focusNode();
  }

  @override
  void syncDraft() {
    final url = AppSettings.parseCatalogUrl(_url.text);
    draft = draft.copyWith(
      catalogUrl: url,
      clearCatalogUrl: url == null,
      username: _user.text.trim(),
      password: _password.text,
    );
  }

  @override
  bool get canSave {
    final url = _url.text.trim();
    return url.isEmpty || AppSettings.parseCatalogUrl(url) != null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final message = _message;

    return SettingsSheet(
      icon: Icons.menu_book_outlined,
      title: s.catalog,
      onDismiss: save,
      children: [
        TextField(
          controller: _url,
          focusNode: _urlFocus,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.catalogUrl,
            hintText: s.catalogUrlHint,
            helperText: s.catalogUrlHelper,
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.link),
            border: settingsInputBorder,
            errorText: _urlError(s),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _user,
          focusNode: _userFocus,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: s.usernameOptional,
            prefixIcon: const Icon(Icons.person_outline),
            border: settingsInputBorder,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: s.passwordOptional,
            helperText: s.storedOnDevice,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? s.showPassword : s.hidePassword,
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            border: settingsInputBorder,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _testing ? null : _test,
          icon: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check),
          label: Text(s.check),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          SheetResult(message: message, ok: _ok),
        ],
      ],
    );
  }

  /// Error shown under the address field, or null when it can be stored.
  String? _urlError(S s) {
    final text = _url.text.trim();
    if (text.isEmpty || AppSettings.parseCatalogUrl(text) != null) return null;
    return s.validateCatalogScheme;
  }

  Future<void> _test() async {
    FocusScope.of(context).unfocus();
    syncDraft();

    final s = S.of(context);
    final error = validateCatalogUrl(_url.text, s);
    if (error != null) {
      setState(() {
        _message = error;
        _ok = false;
      });
      return;
    }

    final bloc = context.read<SettingsBloc>();
    setState(() {
      _testing = true;
      _message = null;
    });
    try {
      final preview = await bloc.preview(draft);
      final nextPage = preview.hasNextPage ? s.nextPageSuffix : '';
      if (!mounted) return;
      setState(() {
        _message = s.connectionOk(preview.title, preview.entryCount, nextPage);
        _ok = true;
      });
    } on OpdsException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _ok = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = s.genericError('$error');
        _ok = false;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}
