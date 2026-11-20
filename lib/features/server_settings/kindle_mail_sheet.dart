import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/expandable_header.dart';
import '../../components/info_box.dart';
import '../../entity/app_settings.dart';
import '../../generated/l10n.dart';
import '../../mail/kindle_mailer.dart';
import '../settings_screen/bloc/settings_bloc.dart';
import 'components/settings_sheet.dart';
import 'components/sheet_result.dart';
import 'validators.dart';

/// Opens the Kindle mail sheet.
Future<void> showKindleMailSheet(BuildContext context) =>
    showSettingsSheet(context, builder: (_) => const KindleMailSheet());

/// Edits the Kindle address and the optional SMTP server.
class KindleMailSheet extends StatefulWidget {
  const KindleMailSheet({super.key});

  @override
  State<KindleMailSheet> createState() => _KindleMailSheetState();
}

class _KindleMailSheetState extends SettingsSheetState<KindleMailSheet> {
  late final TextEditingController _email;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _password;
  late final TextEditingController _sender;

  /// Kindle domain shown as a fixed suffix after the editable name.
  ///
  /// It is kept from the saved address only when that really is a Kindle
  /// domain (`@kindle.com`, `@kindle.co.uk`, …). Anything else falls back to
  /// `@kindle.com`, so a stray value cannot replace the suffix.
  late String _emailDomain;

  late final FocusNode _emailFocus;
  late final FocusNode _hostFocus;
  late final FocusNode _portFocus;
  late final FocusNode _userFocus;
  late final FocusNode _passwordFocus;
  late final FocusNode _senderFocus;

  late bool _showSmtp;
  bool _obscurePassword = true;
  bool _testing = false;
  String? _message;
  bool _ok = false;

  @override
  void initFields() {
    // Only the part before the “@” is editable; the domain is a fixed suffix
    // shown in the field, so the user never types “@kindle.com” by hand.
    final storedEmail = draft.kindleEmail.trim();
    final at = storedEmail.indexOf('@');
    final storedDomain = at > 0 ? storedEmail.substring(at) : '';
    _emailDomain = AppSettings.isKindleDomain(storedDomain)
        ? storedDomain
        : AppSettings.defaultKindleDomain;
    _email = controller(at > 0 ? storedEmail.substring(0, at) : storedEmail);
    _host = controller(draft.smtpHost);
    _port = controller(draft.smtpPort.toString());
    _user = controller(draft.smtpUsername);
    _password = controller(draft.smtpPassword);
    _sender = controller(draft.senderEmail);

    _emailFocus = focusNode();
    _hostFocus = focusNode();
    _portFocus = focusNode();
    _userFocus = focusNode();
    _passwordFocus = focusNode();
    _senderFocus = focusNode();

    _showSmtp = draft.smtpHost.trim().isNotEmpty;
  }

  @override
  void syncDraft() {
    final port = int.tryParse(_port.text.trim());
    final local = _email.text.trim();
    draft = draft.copyWith(
      kindleEmail: local.isEmpty ? '' : '$local$_emailDomain',
      smtpHost: _host.text.trim(),
      // Keep the last valid port while the field is being edited.
      smtpPort: port != null && port >= 1 && port <= 65535
          ? port
          : draft.smtpPort,
      smtpUsername: _user.text.trim(),
      smtpPassword: _password.text,
      senderEmail: _sender.text.trim(),
    );
  }

  @override
  bool get canSave {
    final s = S.of(context);
    return _emailError(s) == null &&
        validateSmtpHost(_host.text, s) == null &&
        validateSmtpPort(_port.text, s) == null &&
        validateSender(_sender.text, s) == null;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = _message;

    return SettingsSheet(
      icon: Icons.alternate_email,
      title: s.kindleMail,
      onDismiss: save,
      children: [
        Text(
          s.kindleMailIntro,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          inputFormatters: const [_KindleLocalPartFormatter()],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: s.kindleEmail,
            hintText: s.kindleEmailHint,
            helperText: s.kindleEmailHelper,
            helperMaxLines: 3,
            prefixIcon: const Icon(Icons.alternate_email),
            suffixText: _emailDomain,
            border: settingsInputBorder,
            errorText: _emailError(s),
          ),
        ),
        const SizedBox(height: 12),
        InfoBox(icon: Icons.info_outline, text: s.amazonRejectsFormats),
        const Divider(height: 28),
        ExpandableHeader(
          title: s.smtpOptional,
          subtitle: _smtpConfigured
              ? s.smtpConfiguredShort
              : s.smtpNotConfiguredShort,
          expanded: _showSmtp,
          onTap: () => setState(() => _showSmtp = !_showSmtp),
        ),
        if (_showSmtp) ...[
          const SizedBox(height: 8),
          Text(
            s.smtpIntro,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _host,
            focusNode: _hostFocus,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: s.smtpHost,
              hintText: s.smtpHostHint,
              helperText: s.smtpHostHelper,
              prefixIcon: const Icon(Icons.dns_outlined),
              border: settingsInputBorder,
              errorText: _hostError(s),
            ),
          ),
          const SizedBox(height: 16),
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
              labelText: s.smtpPort,
              helperText: s.smtpPortHelper,
              prefixIcon: const Icon(Icons.settings_ethernet),
              border: settingsInputBorder,
              errorText: validateSmtpPort(_port.text, s),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.smtpSsl),
            subtitle: Text(s.smtpSslHint),
            value: draft.smtpSsl,
            onChanged: (value) => update(() {
              draft = draft.copyWith(smtpSsl: value);
              final current = _port.text.trim();
              if (value && current == '587') {
                _port.text = '465';
              } else if (!value && current == '465') {
                _port.text = '587';
              }
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _user,
            focusNode: _userFocus,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: s.smtpUsername,
              helperText: s.smtpUsernameHelper,
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
              labelText: s.smtpPassword,
              helperText: s.smtpPasswordHelper,
              helperMaxLines: 2,
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
          TextField(
            controller: _sender,
            focusNode: _senderFocus,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: s.senderEmail,
              hintText: s.senderEmailHint,
              helperText: s.senderEmailHelper,
              helperMaxLines: 2,
              prefixIcon: const Icon(Icons.outgoing_mail),
              border: settingsInputBorder,
              errorText: _senderError(s),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _testing ? null : _testMail,
            icon: _testing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(_testing ? s.sending : s.sendTestMail),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 12),
          SheetResult(message: message, ok: _ok),
        ],
      ],
    );
  }

  bool get _smtpConfigured =>
      _host.text.trim().isNotEmpty && _sender.text.trim().isNotEmpty;

  String? _emailError(S s) {
    final local = _email.text.trim();
    if (local.isEmpty) return null;
    return validateOptionalEmail('$local$_emailDomain', s);
  }

  String? _hostError(S s) {
    final text = _host.text.trim();
    if (text.isEmpty) return null;
    return validateSmtpHost(text, s);
  }

  String? _senderError(S s) {
    final text = _sender.text.trim();
    if (text.isEmpty) return null;
    return validateSender(text, s);
  }

  Future<void> _testMail() async {
    FocusScope.of(context).unfocus();
    syncDraft();

    final s = S.of(context);
    if (!canSave) {
      setState(() {
        _message = s.testMailMissing;
        _ok = false;
      });
      return;
    }
    if (!draft.emailConfigured) {
      setState(() {
        _message = s.testMailMissing;
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
      await bloc.sendTestEmail(draft);
      if (!mounted) return;
      setState(() {
        _message = s.testMailSent;
        _ok = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = KindleMailer.describeError(error);
        _ok = false;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }
}

/// Keeps only the part of a Kindle address before the “@”.
///
/// The domain is shown as a fixed suffix in the field, so the user types only
/// the name. An address pasted from Amazon (`name@kindle.com`) loses its
/// `@…` part, and a stray “@” or space cannot be entered.
class _KindleLocalPartFormatter extends TextInputFormatter {
  const _KindleLocalPartFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    final at = text.indexOf('@');
    if (at != -1) text = text.substring(0, at);
    text = text.replaceAll(RegExp(r'\s'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
