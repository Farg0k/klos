import '../../entity/app_settings.dart';
import '../../generated/l10n.dart';

/// Validators shared by the server settings sheets.
///
/// They return an error message for the field, or null when the value can be
/// stored. Empty input is allowed where the setting is optional.

String? validateCatalogUrl(String? value, S s) {
  final url = (value ?? '').trim();
  if (url.isEmpty) return s.validateCatalogRequired;
  if (AppSettings.parseCatalogUrl(url) == null) return s.validateCatalogScheme;
  return null;
}

String? validatePort(String? value, S s) {
  final port = int.tryParse((value ?? '').trim());
  if (port == null || port < 1024 || port > 65535) return s.validatePort;
  return null;
}

String? validateSmtpPort(String? value, S s) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return null;
  final port = int.tryParse(raw);
  if (port == null || port < 1 || port > 65535) return s.validateSmtpPort;
  return null;
}

String? validateOptionalEmail(String? value, S s, {bool allowEmpty = true}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return allowEmpty ? null : s.validateEmailRequired;
  if (!AppSettings.isValidEmail(text)) return s.validateEmailInvalid;
  return null;
}

String? validateSmtpHost(String? value, S s) {
  final host = (value ?? '').trim();
  if (host.isEmpty) return null;
  if (host.contains(' ') ||
      host.startsWith('http://') ||
      host.startsWith('https://')) {
    return s.validateSmtpHost;
  }
  return null;
}

String? validateSender(String? value, S s) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return validateOptionalEmail(value, s);
}
