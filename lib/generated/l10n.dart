// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Refresh IP addresses`
  String get refreshAddresses {
    return Intl.message(
      'Refresh IP addresses',
      name: 'refreshAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Server settings`
  String get serverSettings {
    return Intl.message(
      'Server settings',
      name: 'serverSettings',
      desc: '',
      args: [],
    );
  }

  /// `The catalog, port, folder and Kindle delivery are set up on the main screen.`
  String get serverSettingsHint {
    return Intl.message(
      'The catalog, port, folder and Kindle delivery are set up on the main screen.',
      name: 'serverSettingsHint',
      desc: '',
      args: [],
    );
  }

  /// `Help`
  String get help {
    return Intl.message('Help', name: 'help', desc: '', args: []);
  }

  /// `klos • a local OPDS bridge for Kindle`
  String get tagline {
    return Intl.message(
      'klos • a local OPDS bridge for Kindle',
      name: 'tagline',
      desc: '',
      args: [],
    );
  }

  /// `Server is running`
  String get serverRunning {
    return Intl.message(
      'Server is running',
      name: 'serverRunning',
      desc: '',
      args: [],
    );
  }

  /// `Server is running`
  String get exitDialogTitle {
    return Intl.message(
      'Server is running',
      name: 'exitDialogTitle',
      desc: '',
      args: [],
    );
  }

  /// `If you leave the app, the server will stop and downloads to the Kindle will be interrupted. To keep the server running in the background, press “Home”, not “Back”.`
  String get exitDialogMessage {
    return Intl.message(
      'If you leave the app, the server will stop and downloads to the Kindle will be interrupted. To keep the server running in the background, press “Home”, not “Back”.',
      name: 'exitDialogMessage',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Stop and exit`
  String get stopAndExit {
    return Intl.message(
      'Stop and exit',
      name: 'stopAndExit',
      desc: '',
      args: [],
    );
  }

  /// `How to connect a Kindle`
  String get helpTitle {
    return Intl.message(
      'How to connect a Kindle',
      name: 'helpTitle',
      desc: '',
      args: [],
    );
  }

  /// `1. Connect the Kindle and the phone to the same Wi-Fi network.`
  String get helpStep1 {
    return Intl.message(
      '1. Connect the Kindle and the phone to the same Wi-Fi network.',
      name: 'helpStep1',
      desc: '',
      args: [],
    );
  }

  /// `2. On the Kindle, open Menu → Experimental Browser.`
  String get helpStep2 {
    return Intl.message(
      '2. On the Kindle, open Menu → Experimental Browser.',
      name: 'helpStep2',
      desc: '',
      args: [],
    );
  }

  /// `3. Enter the server address:`
  String get helpStep3 {
    return Intl.message(
      '3. Enter the server address:',
      name: 'helpStep3',
      desc: '',
      args: [],
    );
  }

  /// `4. Choose a book and a format. “Send by email” delivers the book to your Kindle address (via SMTP or the phone's mail app), “Convert” creates a MOBI on the phone, and “Download” saves the file to the device.`
  String get helpStep4 {
    return Intl.message(
      '4. Choose a book and a format. “Send by email” delivers the book to your Kindle address (via SMTP or the phone\'s mail app), “Convert” creates a MOBI on the phone, and “Download” saves the file to the device.',
      name: 'helpStep4',
      desc: '',
      args: [],
    );
  }

  /// `5. The file will appear in your Kindle library or in the Documents folder.`
  String get helpStep5 {
    return Intl.message(
      '5. The file will appear in your Kindle library or in the Documents folder.',
      name: 'helpStep5',
      desc: '',
      args: [],
    );
  }

  /// `Tip: if a format doesn't open, try MOBI. To send by email, set your Kindle address and add the sender address in Amazon — then klos will send emails itself. Without SMTP, the phone's mail app opens instead; this works only while klos is open. The server keeps running in the background until you stop it.`
  String get helpTip {
    return Intl.message(
      'Tip: if a format doesn\'t open, try MOBI. To send by email, set your Kindle address and add the sender address in Amazon — then klos will send emails itself. Without SMTP, the phone\'s mail app opens instead; this works only while klos is open. The server keeps running in the background until you stop it.',
      name: 'helpTip',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get close {
    return Intl.message('Close', name: 'close', desc: '', args: []);
  }

  /// `Server is stopped`
  String get serverStopped {
    return Intl.message(
      'Server is stopped',
      name: 'serverStopped',
      desc: '',
      args: [],
    );
  }

  /// `The Kindle can connect to this phone.`
  String get serverRunningHint {
    return Intl.message(
      'The Kindle can connect to this phone.',
      name: 'serverRunningHint',
      desc: '',
      args: [],
    );
  }

  /// `Start the server so the Kindle can download books.`
  String get serverStoppedHint {
    return Intl.message(
      'Start the server so the Kindle can download books.',
      name: 'serverStoppedHint',
      desc: '',
      args: [],
    );
  }

  /// `Add an OPDS catalog address or choose a folder with books.`
  String get addCatalogFirst {
    return Intl.message(
      'Add an OPDS catalog address or choose a folder with books.',
      name: 'addCatalogFirst',
      desc: '',
      args: [],
    );
  }

  /// `Stop server`
  String get stopServer {
    return Intl.message('Stop server', name: 'stopServer', desc: '', args: []);
  }

  /// `Start server`
  String get startServer {
    return Intl.message(
      'Start server',
      name: 'startServer',
      desc: '',
      args: [],
    );
  }

  /// `Kindle address`
  String get kindleAddress {
    return Intl.message(
      'Kindle address',
      name: 'kindleAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter this address in the Experimental Browser on your Kindle.`
  String get kindleAddressHint {
    return Intl.message(
      'Enter this address in the Experimental Browser on your Kindle.',
      name: 'kindleAddressHint',
      desc: '',
      args: [],
    );
  }

  /// `No IP address found. Check that Wi-Fi is connected.`
  String get noIpAddress {
    return Intl.message(
      'No IP address found. Check that Wi-Fi is connected.',
      name: 'noIpAddress',
      desc: '',
      args: [],
    );
  }

  /// `http://phone-ip:{port}/`
  String addressPlaceholder(int port) {
    return Intl.message(
      'http://phone-ip:$port/',
      name: 'addressPlaceholder',
      desc: '',
      args: [port],
    );
  }

  /// `The server is stopped — the Kindle cannot connect until you start it.`
  String get serverOfflineHint {
    return Intl.message(
      'The server is stopped — the Kindle cannot connect until you start it.',
      name: 'serverOfflineHint',
      desc: '',
      args: [],
    );
  }

  /// `OPDS catalog`
  String get catalog {
    return Intl.message('OPDS catalog', name: 'catalog', desc: '', args: []);
  }

  /// `No address added yet`
  String get catalogNotSet {
    return Intl.message(
      'No address added yet',
      name: 'catalogNotSet',
      desc: '',
      args: [],
    );
  }

  /// `No Kindle address set. Add one to receive books by email.`
  String get kindleEmailMissing {
    return Intl.message(
      'No Kindle address set. Add one to receive books by email.',
      name: 'kindleEmailMissing',
      desc: '',
      args: [],
    );
  }

  /// `SMTP is not configured — the “send by email” button will open the phone's mail app.`
  String get smtpNotConfigured {
    return Intl.message(
      'SMTP is not configured — the “send by email” button will open the phone\'s mail app.',
      name: 'smtpNotConfigured',
      desc: '',
      args: [],
    );
  }

  /// `Kindle email`
  String get kindleMail {
    return Intl.message('Kindle email', name: 'kindleMail', desc: '', args: []);
  }

  /// `Send by email via SMTP`
  String get deliverySmtp {
    return Intl.message(
      'Send by email via SMTP',
      name: 'deliverySmtp',
      desc: '',
      args: [],
    );
  }

  /// `Log`
  String get log {
    return Intl.message('Log', name: 'log', desc: '', args: []);
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `Kindle requests and downloads will appear here.`
  String get logEmpty {
    return Intl.message(
      'Kindle requests and downloads will appear here.',
      name: 'logEmpty',
      desc: '',
      args: [],
    );
  }

  /// `OPDS server`
  String get opdsServer {
    return Intl.message('OPDS server', name: 'opdsServer', desc: '', args: []);
  }

  /// `Catalog address`
  String get catalogUrl {
    return Intl.message(
      'Catalog address',
      name: 'catalogUrl',
      desc: '',
      args: [],
    );
  }

  /// `http://192.168.1.20:8080/opds`
  String get catalogUrlHint {
    return Intl.message(
      'http://192.168.1.20:8080/opds',
      name: 'catalogUrlHint',
      desc: '',
      args: [],
    );
  }

  /// `Link to an OPDS catalog (Atom XML). http:// can be omitted — it will be added automatically.`
  String get catalogUrlHelper {
    return Intl.message(
      'Link to an OPDS catalog (Atom XML). http:// can be omitted — it will be added automatically.',
      name: 'catalogUrlHelper',
      desc: '',
      args: [],
    );
  }

  /// `Username (optional)`
  String get usernameOptional {
    return Intl.message(
      'Username (optional)',
      name: 'usernameOptional',
      desc: '',
      args: [],
    );
  }

  /// `Password (optional)`
  String get passwordOptional {
    return Intl.message(
      'Password (optional)',
      name: 'passwordOptional',
      desc: '',
      args: [],
    );
  }

  /// `Stored only on this device.`
  String get storedOnDevice {
    return Intl.message(
      'Stored only on this device.',
      name: 'storedOnDevice',
      desc: '',
      args: [],
    );
  }

  /// `Show password`
  String get showPassword {
    return Intl.message(
      'Show password',
      name: 'showPassword',
      desc: '',
      args: [],
    );
  }

  /// `Hide password`
  String get hidePassword {
    return Intl.message(
      'Hide password',
      name: 'hidePassword',
      desc: '',
      args: [],
    );
  }

  /// `Local server`
  String get localServer {
    return Intl.message(
      'Local server',
      name: 'localServer',
      desc: '',
      args: [],
    );
  }

  /// `Port`
  String get port {
    return Intl.message('Port', name: 'port', desc: '', args: []);
  }

  /// `Kindle address: http://phone-ip:port/`
  String get portHelper {
    return Intl.message(
      'Kindle address: http://phone-ip:port/',
      name: 'portHelper',
      desc: '',
      args: [],
    );
  }

  /// `Start automatically`
  String get autoStart {
    return Intl.message(
      'Start automatically',
      name: 'autoStart',
      desc: '',
      args: [],
    );
  }

  /// `The server starts together with the app.`
  String get autoStartHint {
    return Intl.message(
      'The server starts together with the app.',
      name: 'autoStartHint',
      desc: '',
      args: [],
    );
  }

  /// `auto-start`
  String get autoStartShort {
    return Intl.message(
      'auto-start',
      name: 'autoStartShort',
      desc: '',
      args: [],
    );
  }

  /// `Stop after inactivity`
  String get autoStop {
    return Intl.message(
      'Stop after inactivity',
      name: 'autoStop',
      desc: '',
      args: [],
    );
  }

  /// `The server stops on its own when no device uses it for this long, so a forgotten server does not stay on the network.`
  String get autoStopHint {
    return Intl.message(
      'The server stops on its own when no device uses it for this long, so a forgotten server does not stay on the network.',
      name: 'autoStopHint',
      desc: '',
      args: [],
    );
  }

  /// `Never`
  String get autoStopOff {
    return Intl.message('Never', name: 'autoStopOff', desc: '', args: []);
  }

  /// `{minutes} min`
  String autoStopMinutes(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'autoStopMinutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Keep the screen on`
  String get keepAwake {
    return Intl.message(
      'Keep the screen on',
      name: 'keepAwake',
      desc: '',
      args: [],
    );
  }

  /// `Stops the phone from sleeping and closing the server while it runs. The screen stays lit, so the battery drains faster.`
  String get keepAwakeHint {
    return Intl.message(
      'Stops the phone from sleeping and closing the server while it runs. The screen stays lit, so the battery drains faster.',
      name: 'keepAwakeHint',
      desc: '',
      args: [],
    );
  }

  /// `screen stays on`
  String get keepAwakeShort {
    return Intl.message(
      'screen stays on',
      name: 'keepAwakeShort',
      desc: '',
      args: [],
    );
  }

  /// `PIN`
  String get pinShort {
    return Intl.message('PIN', name: 'pinShort', desc: '', args: []);
  }

  /// `PIN protection`
  String get pinProtection {
    return Intl.message(
      'PIN protection',
      name: 'pinProtection',
      desc: '',
      args: [],
    );
  }

  /// `Ask for a PIN before the Kindle can open the catalog. Recommended on a shared Wi-Fi network.`
  String get pinProtectionHint {
    return Intl.message(
      'Ask for a PIN before the Kindle can open the catalog. Recommended on a shared Wi-Fi network.',
      name: 'pinProtectionHint',
      desc: '',
      args: [],
    );
  }

  /// `PIN code`
  String get pinCode {
    return Intl.message('PIN code', name: 'pinCode', desc: '', args: []);
  }

  /// `Enter this code once in the Kindle browser. The Kindle stays signed in until the server restarts.`
  String get pinHintOnKindle {
    return Intl.message(
      'Enter this code once in the Kindle browser. The Kindle stays signed in until the server restarts.',
      name: 'pinHintOnKindle',
      desc: '',
      args: [],
    );
  }

  /// `New PIN`
  String get pinRefresh {
    return Intl.message('New PIN', name: 'pinRefresh', desc: '', args: []);
  }

  /// `The code appears here after the server starts.`
  String get pinStartsWithServer {
    return Intl.message(
      'The code appears here after the server starts.',
      name: 'pinStartsWithServer',
      desc: '',
      args: [],
    );
  }

  /// `PIN required`
  String get pinPageTitle {
    return Intl.message(
      'PIN required',
      name: 'pinPageTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter the PIN shown in the klos app on the phone.`
  String get pinPageIntro {
    return Intl.message(
      'Enter the PIN shown in the klos app on the phone.',
      name: 'pinPageIntro',
      desc: '',
      args: [],
    );
  }

  /// `The PIN protects your library from other devices on the Wi-Fi network.`
  String get pinPageHint {
    return Intl.message(
      'The PIN protects your library from other devices on the Wi-Fi network.',
      name: 'pinPageHint',
      desc: '',
      args: [],
    );
  }

  /// `Wrong PIN. Try again.`
  String get pinWrong {
    return Intl.message(
      'Wrong PIN. Try again.',
      name: 'pinWrong',
      desc: '',
      args: [],
    );
  }

  /// `Too many wrong attempts. Wait a few minutes and reload the page.`
  String get pinBlocked {
    return Intl.message(
      'Too many wrong attempts. Wait a few minutes and reload the page.',
      name: 'pinBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Unlock`
  String get pinSubmit {
    return Intl.message('Unlock', name: 'pinSubmit', desc: '', args: []);
  }

  /// `Catalog appearance`
  String get catalogAppearance {
    return Intl.message(
      'Catalog appearance',
      name: 'catalogAppearance',
      desc: '',
      args: [],
    );
  }

  /// `Show covers`
  String get showCovers {
    return Intl.message('Show covers', name: 'showCovers', desc: '', args: []);
  }

  /// `Book thumbnails in the catalog. Turn off if pages should load faster or without images.`
  String get showCoversHint {
    return Intl.message(
      'Book thumbnails in the catalog. Turn off if pages should load faster or without images.',
      name: 'showCoversHint',
      desc: '',
      args: [],
    );
  }

  /// `The “send by email” button appears next to formats the Kindle cannot open directly (EPUB, FB2, CBZ, ZIP) as soon as you set a Kindle address. If SMTP is configured, klos sends the email itself; otherwise the phone's mail app opens with the attachment and address ready. MOBI, AZW3, PDF and TXT are downloaded as regular files, and klos unpacks ZIP archives by itself.`
  String get kindleMailIntro {
    return Intl.message(
      'The “send by email” button appears next to formats the Kindle cannot open directly (EPUB, FB2, CBZ, ZIP) as soon as you set a Kindle address. If SMTP is configured, klos sends the email itself; otherwise the phone\'s mail app opens with the attachment and address ready. MOBI, AZW3, PDF and TXT are downloaded as regular files, and klos unpacks ZIP archives by itself.',
      name: 'kindleMailIntro',
      desc: '',
      args: [],
    );
  }

  /// `Kindle address`
  String get kindleEmail {
    return Intl.message(
      'Kindle address',
      name: 'kindleEmail',
      desc: '',
      args: [],
    );
  }

  /// `name`
  String get kindleEmailHint {
    return Intl.message('name', name: 'kindleEmailHint', desc: '', args: []);
  }

  /// `Find it on Amazon: Manage Your Content and Devices → Preferences → Send to Kindle Email Address.`
  String get kindleEmailHelper {
    return Intl.message(
      'Find it on Amazon: Manage Your Content and Devices → Preferences → Send to Kindle Email Address.',
      name: 'kindleEmailHelper',
      desc: '',
      args: [],
    );
  }

  /// `SMTP (optional)`
  String get smtpOptional {
    return Intl.message(
      'SMTP (optional)',
      name: 'smtpOptional',
      desc: '',
      args: [],
    );
  }

  /// `Configured — klos sends emails itself.`
  String get smtpConfiguredShort {
    return Intl.message(
      'Configured — klos sends emails itself.',
      name: 'smtpConfiguredShort',
      desc: '',
      args: [],
    );
  }

  /// `Not configured — the mail app opens instead.`
  String get smtpNotConfiguredShort {
    return Intl.message(
      'Not configured — the mail app opens instead.',
      name: 'smtpNotConfiguredShort',
      desc: '',
      args: [],
    );
  }

  /// `Fill this in so klos sends emails itself. Without SMTP, the “send by email” button opens the phone's mail app.`
  String get smtpIntro {
    return Intl.message(
      'Fill this in so klos sends emails itself. Without SMTP, the “send by email” button opens the phone\'s mail app.',
      name: 'smtpIntro',
      desc: '',
      args: [],
    );
  }

  /// `SMTP server`
  String get smtpHost {
    return Intl.message('SMTP server', name: 'smtpHost', desc: '', args: []);
  }

  /// `smtp.gmail.com`
  String get smtpHostHint {
    return Intl.message(
      'smtp.gmail.com',
      name: 'smtpHostHint',
      desc: '',
      args: [],
    );
  }

  /// `For example: smtp.gmail.com, smtp.ukr.net`
  String get smtpHostHelper {
    return Intl.message(
      'For example: smtp.gmail.com, smtp.ukr.net',
      name: 'smtpHostHelper',
      desc: '',
      args: [],
    );
  }

  /// `SMTP port`
  String get smtpPort {
    return Intl.message('SMTP port', name: 'smtpPort', desc: '', args: []);
  }

  /// `587 — STARTTLS, 465 — SSL`
  String get smtpPortHelper {
    return Intl.message(
      '587 — STARTTLS, 465 — SSL',
      name: 'smtpPortHelper',
      desc: '',
      args: [],
    );
  }

  /// `SSL/TLS immediately (port 465)`
  String get smtpSsl {
    return Intl.message(
      'SSL/TLS immediately (port 465)',
      name: 'smtpSsl',
      desc: '',
      args: [],
    );
  }

  /// `Enable for port 465. Usually off for 587: the connection is secured with STARTTLS.`
  String get smtpSslHint {
    return Intl.message(
      'Enable for port 465. Usually off for 587: the connection is secured with STARTTLS.',
      name: 'smtpSslHint',
      desc: '',
      args: [],
    );
  }

  /// `SMTP username`
  String get smtpUsername {
    return Intl.message(
      'SMTP username',
      name: 'smtpUsername',
      desc: '',
      args: [],
    );
  }

  /// `Usually your full email address.`
  String get smtpUsernameHelper {
    return Intl.message(
      'Usually your full email address.',
      name: 'smtpUsernameHelper',
      desc: '',
      args: [],
    );
  }

  /// `SMTP password`
  String get smtpPassword {
    return Intl.message(
      'SMTP password',
      name: 'smtpPassword',
      desc: '',
      args: [],
    );
  }

  /// `For Gmail, use an app password. Stored only on this device.`
  String get smtpPasswordHelper {
    return Intl.message(
      'For Gmail, use an app password. Stored only on this device.',
      name: 'smtpPasswordHelper',
      desc: '',
      args: [],
    );
  }

  /// `Sender address`
  String get senderEmail {
    return Intl.message(
      'Sender address',
      name: 'senderEmail',
      desc: '',
      args: [],
    );
  }

  /// `your.address@gmail.com`
  String get senderEmailHint {
    return Intl.message(
      'your.address@gmail.com',
      name: 'senderEmailHint',
      desc: '',
      args: [],
    );
  }

  /// `Must match the address added to Amazon as an approved sender.`
  String get senderEmailHelper {
    return Intl.message(
      'Must match the address added to Amazon as an approved sender.',
      name: 'senderEmailHelper',
      desc: '',
      args: [],
    );
  }

  /// `Sending...`
  String get sending {
    return Intl.message('Sending...', name: 'sending', desc: '', args: []);
  }

  /// `Send test email`
  String get sendTestMail {
    return Intl.message(
      'Send test email',
      name: 'sendTestMail',
      desc: '',
      args: [],
    );
  }

  /// `The server listens on the Wi-Fi network only. Without PIN protection every device on it can open the catalog, so use a trusted network. Changing the port restarts a running server.`
  String get securityInfo {
    return Intl.message(
      'The server listens on the Wi-Fi network only. Without PIN protection every device on it can open the catalog, so use a trusted network. Changing the port restarts a running server.',
      name: 'securityInfo',
      desc: '',
      args: [],
    );
  }

  /// `Changes are saved automatically.`
  String get settingsAutoSaveHint {
    return Intl.message(
      'Changes are saved automatically.',
      name: 'settingsAutoSaveHint',
      desc: '',
      args: [],
    );
  }

  /// `Checking...`
  String get checking {
    return Intl.message('Checking...', name: 'checking', desc: '', args: []);
  }

  /// `Check`
  String get check {
    return Intl.message('Check', name: 'check', desc: '', args: []);
  }

  /// `Saving...`
  String get saving {
    return Intl.message('Saving...', name: 'saving', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Settings saved`
  String get settingsSaved {
    return Intl.message(
      'Settings saved',
      name: 'settingsSaved',
      desc: '',
      args: [],
    );
  }

  /// `Could not save: {error}`
  String saveFailed(String error) {
    return Intl.message(
      'Could not save: $error',
      name: 'saveFailed',
      desc: '',
      args: [error],
    );
  }

  /// `OK: “{title}”, entries: {count}{nextPage}`
  String connectionOk(String title, int count, String nextPage) {
    return Intl.message(
      'OK: “$title”, entries: $count$nextPage',
      name: 'connectionOk',
      desc: '',
      args: [title, count, nextPage],
    );
  }

  /// `, there is a next page`
  String get nextPageSuffix {
    return Intl.message(
      ', there is a next page',
      name: 'nextPageSuffix',
      desc: '',
      args: [],
    );
  }

  /// `Error: {error}`
  String genericError(String error) {
    return Intl.message(
      'Error: $error',
      name: 'genericError',
      desc: '',
      args: [error],
    );
  }

  /// `Fill in the Kindle address, SMTP server and sender address, and select at least one format.`
  String get testMailMissing {
    return Intl.message(
      'Fill in the Kindle address, SMTP server and sender address, and select at least one format.',
      name: 'testMailMissing',
      desc: '',
      args: [],
    );
  }

  /// `The test email was handed to the SMTP server. Check your Kindle in a few minutes.`
  String get testMailSent {
    return Intl.message(
      'The test email was handed to the SMTP server. Check your Kindle in a few minutes.',
      name: 'testMailSent',
      desc: '',
      args: [],
    );
  }

  /// `Enter the OPDS catalog address`
  String get validateCatalogRequired {
    return Intl.message(
      'Enter the OPDS catalog address',
      name: 'validateCatalogRequired',
      desc: '',
      args: [],
    );
  }

  /// `The address must start with http:// or https://`
  String get validateCatalogScheme {
    return Intl.message(
      'The address must start with http:// or https://',
      name: 'validateCatalogScheme',
      desc: '',
      args: [],
    );
  }

  /// `Port must be between 1024 and 65535`
  String get validatePort {
    return Intl.message(
      'Port must be between 1024 and 65535',
      name: 'validatePort',
      desc: '',
      args: [],
    );
  }

  /// `Port must be between 1 and 65535`
  String get validateSmtpPort {
    return Intl.message(
      'Port must be between 1 and 65535',
      name: 'validateSmtpPort',
      desc: '',
      args: [],
    );
  }

  /// `Enter an address`
  String get validateEmailRequired {
    return Intl.message(
      'Enter an address',
      name: 'validateEmailRequired',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email address`
  String get validateEmailInvalid {
    return Intl.message(
      'Invalid email address',
      name: 'validateEmailInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Enter only the server address, e.g. smtp.gmail.com`
  String get validateSmtpHost {
    return Intl.message(
      'Enter only the server address, e.g. smtp.gmail.com',
      name: 'validateSmtpHost',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `System default`
  String get languageSystem {
    return Intl.message(
      'System default',
      name: 'languageSystem',
      desc: '',
      args: [],
    );
  }

  /// `Language of the app and the Kindle pages. “System default” follows the phone settings.`
  String get languageHint {
    return Intl.message(
      'Language of the app and the Kindle pages. “System default” follows the phone settings.',
      name: 'languageHint',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `“Auto” follows the phone's light or dark mode.`
  String get themeHint {
    return Intl.message(
      '“Auto” follows the phone\'s light or dark mode.',
      name: 'themeHint',
      desc: '',
      args: [],
    );
  }

  /// `Auto`
  String get themeSystem {
    return Intl.message('Auto', name: 'themeSystem', desc: '', args: []);
  }

  /// `Light`
  String get themeLight {
    return Intl.message('Light', name: 'themeLight', desc: '', args: []);
  }

  /// `Dark`
  String get themeDark {
    return Intl.message('Dark', name: 'themeDark', desc: '', args: []);
  }

  /// `About the app`
  String get aboutApp {
    return Intl.message('About the app', name: 'aboutApp', desc: '', args: []);
  }

  /// `Version, build and licences.`
  String get aboutAppHint {
    return Intl.message(
      'Version, build and licences.',
      name: 'aboutAppHint',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get appVersion {
    return Intl.message('Version', name: 'appVersion', desc: '', args: []);
  }

  /// `Build`
  String get appBuild {
    return Intl.message('Build', name: 'appBuild', desc: '', args: []);
  }

  /// `Package`
  String get appPackage {
    return Intl.message('Package', name: 'appPackage', desc: '', args: []);
  }

  /// `klos is a local OPDS server that lets a Kindle download books from the phone over Wi-Fi.`
  String get aboutDescription {
    return Intl.message(
      'klos is a local OPDS server that lets a Kindle download books from the phone over Wi-Fi.',
      name: 'aboutDescription',
      desc: '',
      args: [],
    );
  }

  /// `Licences`
  String get licenses {
    return Intl.message('Licences', name: 'licenses', desc: '', args: []);
  }

  /// `Libraries used by the app and the licences they are published under.`
  String get licensesHint {
    return Intl.message(
      'Libraries used by the app and the licences they are published under.',
      name: 'licensesHint',
      desc: '',
      args: [],
    );
  }

  /// `Full licence texts`
  String get licensesFullText {
    return Intl.message(
      'Full licence texts',
      name: 'licensesFullText',
      desc: '',
      args: [],
    );
  }

  /// `Licence texts by package`
  String get licensesPackages {
    return Intl.message(
      'Licence texts by package',
      name: 'licensesPackages',
      desc: '',
      args: [],
    );
  }

  /// `Loading licence texts…`
  String get licensesLoading {
    return Intl.message(
      'Loading licence texts…',
      name: 'licensesLoading',
      desc: '',
      args: [],
    );
  }

  /// `No licence information was found.`
  String get licensesEmpty {
    return Intl.message(
      'No licence information was found.',
      name: 'licensesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive is damaged or password-protected and cannot be opened.`
  String get zipBroken {
    return Intl.message(
      'The ZIP archive is damaged or password-protected and cannot be opened.',
      name: 'zipBroken',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive contains no usable files.`
  String get zipNoUsableFiles {
    return Intl.message(
      'The ZIP archive contains no usable files.',
      name: 'zipNoUsableFiles',
      desc: '',
      args: [],
    );
  }

  /// `A file in the ZIP archive is too large (over {megabytes} MB).`
  String zipTooLarge(int megabytes) {
    return Intl.message(
      'A file in the ZIP archive is too large (over $megabytes MB).',
      name: 'zipTooLarge',
      desc: '',
      args: [megabytes],
    );
  }

  /// `Could not unpack “{name}” from the archive.`
  String zipUnpackFailed(String name) {
    return Intl.message(
      'Could not unpack “$name” from the archive.',
      name: 'zipUnpackFailed',
      desc: '',
      args: [name],
    );
  }

  /// `The file “{name}” in the archive is empty.`
  String zipEmptyFile(String name) {
    return Intl.message(
      'The file “$name” in the archive is empty.',
      name: 'zipEmptyFile',
      desc: '',
      args: [name],
    );
  }

  /// `Could not determine the format of “{name}”.`
  String zipUnknownFormat(String name) {
    return Intl.message(
      'Could not determine the format of “$name”.',
      name: 'zipUnknownFormat',
      desc: '',
      args: [name],
    );
  }

  /// ` Found: {list}.`
  String zipFound(String list) {
    return Intl.message(
      ' Found: $list.',
      name: 'zipFound',
      desc: '',
      args: [list],
    );
  }

  /// `The ZIP archive contains only an EPUB. klos converts it to MOBI on download.`
  String get zipOnlyEpub {
    return Intl.message(
      'The ZIP archive contains only an EPUB. klos converts it to MOBI on download.',
      name: 'zipOnlyEpub',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive contains no file the Kindle opens directly (MOBI, AZW3, AZW, PDF or TXT).`
  String get zipNoKindleFile {
    return Intl.message(
      'The ZIP archive contains no file the Kindle opens directly (MOBI, AZW3, AZW, PDF or TXT).',
      name: 'zipNoKindleFile',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive contains no file Amazon accepts (EPUB, PDF, TXT, RTF, DOC/DOCX or HTML).`
  String get zipNoEmailFile {
    return Intl.message(
      'The ZIP archive contains no file Amazon accepts (EPUB, PDF, TXT, RTF, DOC/DOCX or HTML).',
      name: 'zipNoEmailFile',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive contains no EPUB or FB2, so there is nothing to convert.`
  String get zipNoConvertible {
    return Intl.message(
      'The ZIP archive contains no EPUB or FB2, so there is nothing to convert.',
      name: 'zipNoConvertible',
      desc: '',
      args: [],
    );
  }

  /// `The ZIP archive contains only an FB2. klos converts it to MOBI on download.`
  String get zipOnlyFb2 {
    return Intl.message(
      'The ZIP archive contains only an FB2. klos converts it to MOBI on download.',
      name: 'zipOnlyFb2',
      desc: '',
      args: [],
    );
  }

  /// `App started`
  String get logAppStarted {
    return Intl.message(
      'App started',
      name: 'logAppStarted',
      desc: '',
      args: [],
    );
  }

  /// `Server started on port {port}`
  String logServerStarted(int port) {
    return Intl.message(
      'Server started on port $port',
      name: 'logServerStarted',
      desc: '',
      args: [port],
    );
  }

  /// `Listening on {addresses}`
  String logServerListening(String addresses) {
    return Intl.message(
      'Listening on $addresses',
      name: 'logServerListening',
      desc: '',
      args: [addresses],
    );
  }

  /// `Could not start the server: {error}`
  String serverStartFailed(String error) {
    return Intl.message(
      'Could not start the server: $error',
      name: 'serverStartFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Server stopped`
  String get logServerStopped {
    return Intl.message(
      'Server stopped',
      name: 'logServerStopped',
      desc: '',
      args: [],
    );
  }

  /// `Server stopped automatically after inactivity`
  String get logServerAutoStopped {
    return Intl.message(
      'Server stopped automatically after inactivity',
      name: 'logServerAutoStopped',
      desc: '',
      args: [],
    );
  }

  /// `Wrong PIN from {ip}`
  String logPinFailed(String ip) {
    return Intl.message(
      'Wrong PIN from $ip',
      name: 'logPinFailed',
      desc: '',
      args: [ip],
    );
  }

  /// `Kindle signed in from {ip}`
  String logPinGranted(String ip) {
    return Intl.message(
      'Kindle signed in from $ip',
      name: 'logPinGranted',
      desc: '',
      args: [ip],
    );
  }

  /// `Too many wrong PINs from {ip}`
  String logPinBlocked(String ip) {
    return Intl.message(
      'Too many wrong PINs from $ip',
      name: 'logPinBlocked',
      desc: '',
      args: [ip],
    );
  }

  /// `PIN replaced after repeated wrong guesses`
  String get logPinRotated {
    return Intl.message(
      'PIN replaced after repeated wrong guesses',
      name: 'logPinRotated',
      desc: '',
      args: [],
    );
  }

  /// `PIN code updated`
  String get logPinChanged {
    return Intl.message(
      'PIN code updated',
      name: 'logPinChanged',
      desc: '',
      args: [],
    );
  }

  /// `Could not stop the server: {error}`
  String serverStopFailed(String error) {
    return Intl.message(
      'Could not stop the server: $error',
      name: 'serverStopFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Email: test message sent to {email}`
  String logTestMailSent(String email) {
    return Intl.message(
      'Email: test message sent to $email',
      name: 'logTestMailSent',
      desc: '',
      args: [email],
    );
  }

  /// `The klos app is not open on the phone right now. Open it on screen and try again.`
  String get appNotOpen {
    return Intl.message(
      'The klos app is not open on the phone right now. Open it on screen and try again.',
      name: 'appNotOpen',
      desc: '',
      args: [],
    );
  }

  /// `Email (mail app): “{title}”`
  String logMailApp(String title) {
    return Intl.message(
      'Email (mail app): “$title”',
      name: 'logMailApp',
      desc: '',
      args: [title],
    );
  }

  /// `Enter the OPDS catalog address.`
  String get catalogAddressRequired {
    return Intl.message(
      'Enter the OPDS catalog address.',
      name: 'catalogAddressRequired',
      desc: '',
      args: [],
    );
  }

  /// `Could not determine the IP address: {error}`
  String ipLookupFailed(String error) {
    return Intl.message(
      'Could not determine the IP address: $error',
      name: 'ipLookupFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Port {port} is already in use. Choose another port in settings.`
  String portInUse(int port) {
    return Intl.message(
      'Port $port is already in use. Choose another port in settings.',
      name: 'portInUse',
      desc: '',
      args: [port],
    );
  }

  /// `Kindle email is not configured: enter the Kindle address, SMTP server, sender address and at least one format.`
  String get mailNotConfigured {
    return Intl.message(
      'Kindle email is not configured: enter the Kindle address, SMTP server, sender address and at least one format.',
      name: 'mailNotConfigured',
      desc: '',
      args: [],
    );
  }

  /// `The book “{title}” was sent from the klos app.\n\nFile: {file}`
  String mailBody(String title, String file) {
    return Intl.message(
      'The book “$title” was sent from the klos app.\n\nFile: $file',
      name: 'mailBody',
      desc: '',
      args: [title, file],
    );
  }

  /// `First fill in the Kindle address, SMTP server and sender address, and select at least one format.`
  String get testMailNotConfigured {
    return Intl.message(
      'First fill in the Kindle address, SMTP server and sender address, and select at least one format.',
      name: 'testMailNotConfigured',
      desc: '',
      args: [],
    );
  }

  /// `klos: email check`
  String get testMailSubject {
    return Intl.message(
      'klos: email check',
      name: 'testMailSubject',
      desc: '',
      args: [],
    );
  }

  /// `This is a test email from klos.\nIf you see it on the Kindle, email is configured correctly.\n`
  String get testMailFileContent {
    return Intl.message(
      'This is a test email from klos.\nIf you see it on the Kindle, email is configured correctly.\n',
      name: 'testMailFileContent',
      desc: '',
      args: [],
    );
  }

  /// `Test email from klos.\n\nIf Amazon accepted the message, books will arrive on your Kindle.`
  String get testMailBody {
    return Intl.message(
      'Test email from klos.\n\nIf Amazon accepted the message, books will arrive on your Kindle.',
      name: 'testMailBody',
      desc: '',
      args: [],
    );
  }

  /// `The file is larger than 25 MB — Amazon does not accept such emails. Try another format or download the book directly.`
  String get mailTooLarge {
    return Intl.message(
      'The file is larger than 25 MB — Amazon does not accept such emails. Try another format or download the book directly.',
      name: 'mailTooLarge',
      desc: '',
      args: [],
    );
  }

  /// `The SMTP server rejected the login or password. For Gmail, use an app password, not your regular password.`
  String get smtpAuthRejected {
    return Intl.message(
      'The SMTP server rejected the login or password. For Gmail, use an app password, not your regular password.',
      name: 'smtpAuthRejected',
      desc: '',
      args: [],
    );
  }

  /// `The SMTP server does not support a secure connection. Check the port and the SSL switch.`
  String get smtpNoSecure {
    return Intl.message(
      'The SMTP server does not support a secure connection. Check the port and the SSL switch.',
      name: 'smtpNoSecure',
      desc: '',
      args: [],
    );
  }

  /// `The mail server rejected the message: check the Kindle and sender addresses.`
  String get smtpMessageRejected {
    return Intl.message(
      'The mail server rejected the message: check the Kindle and sender addresses.',
      name: 'smtpMessageRejected',
      desc: '',
      args: [],
    );
  }

  /// `The SMTP server did not send a greeting. Check the address and port.`
  String get smtpNoGreeting {
    return Intl.message(
      'The SMTP server did not send a greeting. Check the address and port.',
      name: 'smtpNoGreeting',
      desc: '',
      args: [],
    );
  }

  /// `Error exchanging data with the SMTP server: {error}`
  String smtpCommunication(String error) {
    return Intl.message(
      'Error exchanging data with the SMTP server: $error',
      name: 'smtpCommunication',
      desc: '',
      args: [error],
    );
  }

  /// `Could not send the email: {error}`
  String mailSendFailed(String error) {
    return Intl.message(
      'Could not send the email: $error',
      name: 'mailSendFailed',
      desc: '',
      args: [error],
    );
  }

  /// `The SMTP server is not responding (timeout).`
  String get smtpTimeout {
    return Intl.message(
      'The SMTP server is not responding (timeout).',
      name: 'smtpTimeout',
      desc: '',
      args: [],
    );
  }

  /// `TLS connection error with the SMTP server. Try another port (465 with SSL or 587 without SSL).`
  String get smtpTls {
    return Intl.message(
      'TLS connection error with the SMTP server. Try another port (465 with SSL or 587 without SSL).',
      name: 'smtpTls',
      desc: '',
      args: [],
    );
  }

  /// `Could not connect to the SMTP server: {error}`
  String smtpConnectFailed(String error) {
    return Intl.message(
      'Could not connect to the SMTP server: $error',
      name: 'smtpConnectFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Could not parse the OPDS catalog: {error}`
  String opdsParseFailed(String error) {
    return Intl.message(
      'Could not parse the OPDS catalog: $error',
      name: 'opdsParseFailed',
      desc: '',
      args: [error],
    );
  }

  /// `The OPDS server response is too large.`
  String get opdsResponseTooLarge {
    return Intl.message(
      'The OPDS server response is too large.',
      name: 'opdsResponseTooLarge',
      desc: '',
      args: [],
    );
  }

  /// `Error reading the response: {error}`
  String opdsReadFailed(String error) {
    return Intl.message(
      'Error reading the response: $error',
      name: 'opdsReadFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Only http:// and https:// addresses are supported.`
  String get onlyHttpAddresses {
    return Intl.message(
      'Only http:// and https:// addresses are supported.',
      name: 'onlyHttpAddresses',
      desc: '',
      args: [],
    );
  }

  /// `The OPDS server is not responding (timeout).`
  String get opdsTimeout {
    return Intl.message(
      'The OPDS server is not responding (timeout).',
      name: 'opdsTimeout',
      desc: '',
      args: [],
    );
  }

  /// `TLS connection error: {error}`
  String tlsError(String error) {
    return Intl.message(
      'TLS connection error: $error',
      name: 'tlsError',
      desc: '',
      args: [error],
    );
  }

  /// `Could not connect to the OPDS server: {error}`
  String opdsConnectFailed(String error) {
    return Intl.message(
      'Could not connect to the OPDS server: $error',
      name: 'opdsConnectFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Connection error: {error}`
  String connectionError(String error) {
    return Intl.message(
      'Connection error: $error',
      name: 'connectionError',
      desc: '',
      args: [error],
    );
  }

  /// `The OPDS server denied access (HTTP {status}). Check the username and password in settings.`
  String opdsAccessDenied(int status) {
    return Intl.message(
      'The OPDS server denied access (HTTP $status). Check the username and password in settings.',
      name: 'opdsAccessDenied',
      desc: '',
      args: [status],
    );
  }

  /// `The OPDS server returned HTTP {status}.`
  String opdsHttpStatus(int status) {
    return Intl.message(
      'The OPDS server returned HTTP $status.',
      name: 'opdsHttpStatus',
      desc: '',
      args: [status],
    );
  }

  /// `Untitled`
  String get untitled {
    return Intl.message('Untitled', name: 'untitled', desc: '', args: []);
  }

  /// `not an Atom/OPDS catalog`
  String get notAtomFeed {
    return Intl.message(
      'not an Atom/OPDS catalog',
      name: 'notAtomFeed',
      desc: '',
      args: [],
    );
  }

  /// `invalid JSON received`
  String get invalidJson {
    return Intl.message(
      'invalid JSON received',
      name: 'invalidJson',
      desc: '',
      args: [],
    );
  }

  /// `not an OPDS 2.0 catalog`
  String get notOpds2Feed {
    return Intl.message(
      'not an OPDS 2.0 catalog',
      name: 'notOpds2Feed',
      desc: '',
      args: [],
    );
  }

  /// `The OPDS server returned an HTML page instead of a file. You may need to log in, or access to this book is restricted.`
  String get opdsHtmlInsteadOfFile {
    return Intl.message(
      'The OPDS server returned an HTML page instead of a file. You may need to log in, or access to this book is restricted.',
      name: 'opdsHtmlInsteadOfFile',
      desc: '',
      args: [],
    );
  }

  /// `The file is not a valid EPUB (ZIP): {error}`
  String epubNotZip(String error) {
    return Intl.message(
      'The file is not a valid EPUB (ZIP): $error',
      name: 'epubNotZip',
      desc: '',
      args: [error],
    );
  }

  /// `The EPUB file is empty.`
  String get epubEmpty {
    return Intl.message(
      'The EPUB file is empty.',
      name: 'epubEmpty',
      desc: '',
      args: [],
    );
  }

  /// `The EPUB file has no OPF manifest.`
  String get epubNoOpf {
    return Intl.message(
      'The EPUB file has no OPF manifest.',
      name: 'epubNoOpf',
      desc: '',
      args: [],
    );
  }

  /// `Could not read the OPF manifest: {error}`
  String epubOpfFailed(String error) {
    return Intl.message(
      'Could not read the OPF manifest: $error',
      name: 'epubOpfFailed',
      desc: '',
      args: [error],
    );
  }

  /// `The book has no manifest.`
  String get epubNoManifest {
    return Intl.message(
      'The book has no manifest.',
      name: 'epubNoManifest',
      desc: '',
      args: [],
    );
  }

  /// `The book has no text to convert.`
  String get epubNoText {
    return Intl.message(
      'The book has no text to convert.',
      name: 'epubNoText',
      desc: '',
      args: [],
    );
  }

  /// `Could not find the book text. The EPUB may have an unusual structure or be DRM-protected.`
  String get epubTextNotFound {
    return Intl.message(
      'Could not find the book text. The EPUB may have an unusual structure or be DRM-protected.',
      name: 'epubTextNotFound',
      desc: '',
      args: [],
    );
  }

  /// `The book is DRM-protected and cannot be converted. Download another format or email the book to your Kindle.`
  String get epubDrm {
    return Intl.message(
      'The book is DRM-protected and cannot be converted. Download another format or email the book to your Kindle.',
      name: 'epubDrm',
      desc: '',
      args: [],
    );
  }

  /// `Chapter {index}`
  String epubChapter(int index) {
    return Intl.message(
      'Chapter $index',
      name: 'epubChapter',
      desc: '',
      args: [index],
    );
  }

  /// `Cover`
  String get coverLabel {
    return Intl.message('Cover', name: 'coverLabel', desc: '', args: []);
  }

  /// `Contents`
  String get contentsLabel {
    return Intl.message('Contents', name: 'contentsLabel', desc: '', args: []);
  }

  /// `Could not convert the book: {error}`
  String conversionFailed(String error) {
    return Intl.message(
      'Could not convert the book: $error',
      name: 'conversionFailed',
      desc: '',
      args: [error],
    );
  }

  /// `This format cannot be converted on the phone. EPUB and FB2 are supported.`
  String get convertUnsupportedFormat {
    return Intl.message(
      'This format cannot be converted on the phone. EPUB and FB2 are supported.',
      name: 'convertUnsupportedFormat',
      desc: '',
      args: [],
    );
  }

  /// `The book text is too large to convert.`
  String get mobiTextTooLarge {
    return Intl.message(
      'The book text is too large to convert.',
      name: 'mobiTextTooLarge',
      desc: '',
      args: [],
    );
  }

  /// `Book`
  String get bookFallbackTitle {
    return Intl.message('Book', name: 'bookFallbackTitle', desc: '', args: []);
  }

  /// `Queued...`
  String get mailStageQueued {
    return Intl.message(
      'Queued...',
      name: 'mailStageQueued',
      desc: '',
      args: [],
    );
  }

  /// `Downloading the book from OPDS...`
  String get mailStageDownloading {
    return Intl.message(
      'Downloading the book from OPDS...',
      name: 'mailStageDownloading',
      desc: '',
      args: [],
    );
  }

  /// `Sending the email to Kindle...`
  String get mailStageSending {
    return Intl.message(
      'Sending the email to Kindle...',
      name: 'mailStageSending',
      desc: '',
      args: [],
    );
  }

  /// `Email sent`
  String get mailStageDone {
    return Intl.message(
      'Email sent',
      name: 'mailStageDone',
      desc: '',
      args: [],
    );
  }

  /// `Could not send`
  String get mailStageFailed {
    return Intl.message(
      'Could not send',
      name: 'mailStageFailed',
      desc: '',
      args: [],
    );
  }

  /// `The book “{title}” from klos`
  String shareBody(String title) {
    return Intl.message(
      'The book “$title” from klos',
      name: 'shareBody',
      desc: '',
      args: [title],
    );
  }

  /// `Could not open the mail app.`
  String get shareOpenFailed {
    return Intl.message(
      'Could not open the mail app.',
      name: 'shareOpenFailed',
      desc: '',
      args: [],
    );
  }

  /// `Sending by email is only available in the Android build of klos.`
  String get shareAndroidOnly {
    return Intl.message(
      'Sending by email is only available in the Android build of klos.',
      name: 'shareAndroidOnly',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Search results:`
  String get searchResults {
    return Intl.message(
      'Search results:',
      name: 'searchResults',
      desc: '',
      args: [],
    );
  }

  /// `Search the catalog`
  String get searchCatalog {
    return Intl.message(
      'Search the catalog',
      name: 'searchCatalog',
      desc: '',
      args: [],
    );
  }

  /// `Book title or author`
  String get searchHint {
    return Intl.message(
      'Book title or author',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `The catalog is empty.`
  String get catalogEmpty {
    return Intl.message(
      'The catalog is empty.',
      name: 'catalogEmpty',
      desc: '',
      args: [],
    );
  }

  /// `&lt; Back`
  String get previousPage {
    return Intl.message('&lt; Back', name: 'previousPage', desc: '', args: []);
  }

  /// `Next &gt;`
  String get nextPage {
    return Intl.message('Next &gt;', name: 'nextPage', desc: '', args: []);
  }

  /// `Source:`
  String get source {
    return Intl.message('Source:', name: 'source', desc: '', args: []);
  }

  /// `The book is being downloaded from the OPDS catalog. This may take a few minutes.`
  String get mailDownloadingHint {
    return Intl.message(
      'The book is being downloaded from the OPDS catalog. This may take a few minutes.',
      name: 'mailDownloadingHint',
      desc: '',
      args: [],
    );
  }

  /// `The email is being handed to the SMTP server. Do not close the klos app.`
  String get mailSendingHint {
    return Intl.message(
      'The email is being handed to the SMTP server. Do not close the klos app.',
      name: 'mailSendingHint',
      desc: '',
      args: [],
    );
  }

  /// `The email was accepted by the mail server.`
  String get mailAccepted {
    return Intl.message(
      'The email was accepted by the mail server.',
      name: 'mailAccepted',
      desc: '',
      args: [],
    );
  }

  /// `The email to {email} was accepted by the mail server.`
  String mailAcceptedTo(String email) {
    return Intl.message(
      'The email to $email was accepted by the mail server.',
      name: 'mailAcceptedTo',
      desc: '',
      args: [email],
    );
  }

  /// `Amazon processes the book separately: it will appear in your Kindle library within a few minutes. If the sender address is not on the approved list in your Amazon settings, the email will be rejected.`
  String get mailAmazonHint {
    return Intl.message(
      'Amazon processes the book separately: it will appear in your Kindle library within a few minutes. If the sender address is not on the approved list in your Amazon settings, the email will be rejected.',
      name: 'mailAmazonHint',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error.`
  String get unknownError {
    return Intl.message(
      'Unknown error.',
      name: 'unknownError',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get retry {
    return Intl.message('Try again', name: 'retry', desc: '', args: []);
  }

  /// `Refresh status now`
  String get refreshStatus {
    return Intl.message(
      'Refresh status now',
      name: 'refreshStatus',
      desc: '',
      args: [],
    );
  }

  /// `The page refreshes automatically every 4 seconds.`
  String get autoRefresh {
    return Intl.message(
      'The page refreshes automatically every 4 seconds.',
      name: 'autoRefresh',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Error`
  String get errorTitle {
    return Intl.message('Error', name: 'errorTitle', desc: '', args: []);
  }

  /// `File ready`
  String get fileReady {
    return Intl.message('File ready', name: 'fileReady', desc: '', args: []);
  }

  /// `The mail app has opened on the phone. The attachment is already added — check the message and send it.`
  String get sharePrepared {
    return Intl.message(
      'The mail app has opened on the phone. The attachment is already added — check the message and send it.',
      name: 'sharePrepared',
      desc: '',
      args: [],
    );
  }

  /// `The mail app has opened on the phone. The attachment is already added, the address <b>{email}</b> is filled in — check the message and send it.`
  String sharePreparedTo(String email) {
    return Intl.message(
      'The mail app has opened on the phone. The attachment is already added, the address <b>$email</b> is filled in — check the message and send it.',
      name: 'sharePreparedTo',
      desc: '',
      args: [email],
    );
  }

  /// `If the mail app did not open, open klos on the phone screen and try again. The file is temporarily kept in the app cache.`
  String get shareHint {
    return Intl.message(
      'If the mail app did not open, open klos on the phone screen and try again. The file is temporarily kept in the app cache.',
      name: 'shareHint',
      desc: '',
      args: [],
    );
  }

  /// `No OPDS catalog has been added and no folder with books has been chosen.`
  String get notConfiguredBody {
    return Intl.message(
      'No OPDS catalog has been added and no folder with books has been chosen.',
      name: 'notConfiguredBody',
      desc: '',
      args: [],
    );
  }

  /// `Open the klos app on your phone, add the OPDS server address or choose a folder with books, then start the local server.`
  String get notConfiguredHelp {
    return Intl.message(
      'Open the klos app on your phone, add the OPDS server address or choose a folder with books, then start the local server.',
      name: 'notConfiguredHelp',
      desc: '',
      args: [],
    );
  }

  /// `Not found`
  String get notFoundTitle {
    return Intl.message('Not found', name: 'notFoundTitle', desc: '', args: []);
  }

  /// `Page not found`
  String get notFoundHeading {
    return Intl.message(
      'Page not found',
      name: 'notFoundHeading',
      desc: '',
      args: [],
    );
  }

  /// `The link may be outdated.`
  String get notFoundHint {
    return Intl.message(
      'The link may be outdated.',
      name: 'notFoundHint',
      desc: '',
      args: [],
    );
  }

  /// `{format} (download)`
  String downloadAction(String format) {
    return Intl.message(
      '$format (download)',
      name: 'downloadAction',
      desc: '',
      args: [format],
    );
  }

  /// `{format} (send by email)`
  String emailAction(String format) {
    return Intl.message(
      '$format (send by email)',
      name: 'emailAction',
      desc: '',
      args: [format],
    );
  }

  /// `Downloading…`
  String get downloadInProgress {
    return Intl.message(
      'Downloading…',
      name: 'downloadInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Please wait, this may take a minute. Don't press the button again.`
  String get actionWaitHint {
    return Intl.message(
      'Please wait, this may take a minute. Don\'t press the button again.',
      name: 'actionWaitHint',
      desc: '',
      args: [],
    );
  }

  /// `Sending…`
  String get mailInProgress {
    return Intl.message('Sending…', name: 'mailInProgress', desc: '', args: []);
  }

  /// `Get:`
  String get getBook {
    return Intl.message('Get:', name: 'getBook', desc: '', args: []);
  }

  /// `Search`
  String get searchButton {
    return Intl.message('Search', name: 'searchButton', desc: '', args: []);
  }

  /// `{count, plural, =0{0 entries} =1{1 entry} other{{count} entries}}`
  String entriesCount(int count) {
    return Intl.plural(
      count,
      zero: '0 entries',
      one: '1 entry',
      other: '$count entries',
      name: 'entriesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Send by email`
  String get sendByEmailTitle {
    return Intl.message(
      'Send by email',
      name: 'sendByEmailTitle',
      desc: '',
      args: [],
    );
  }

  /// `How to download a book`
  String get webHelpHeading {
    return Intl.message(
      'How to download a book',
      name: 'webHelpHeading',
      desc: '',
      args: [],
    );
  }

  /// `Connect the Kindle and the phone to the same Wi-Fi network.`
  String get webHelpStep1 {
    return Intl.message(
      'Connect the Kindle and the phone to the same Wi-Fi network.',
      name: 'webHelpStep1',
      desc: '',
      args: [],
    );
  }

  /// `On the Kindle, open <b>Experimental Browser</b>.`
  String get webHelpStep2 {
    return Intl.message(
      'On the Kindle, open <b>Experimental Browser</b>.',
      name: 'webHelpStep2',
      desc: '',
      args: [],
    );
  }

  /// `Enter this server address:<br><b>{address}</b>`
  String webHelpStep3(String address) {
    return Intl.message(
      'Enter this server address:<br><b>$address</b>',
      name: 'webHelpStep3',
      desc: '',
      args: [address],
    );
  }

  /// `Choose a book and a format. <b>(download)</b> saves the file to the Kindle, <b>(send by email)</b> sends it to the Kindle address — automatically via SMTP if configured, or via the phone's mail app — and <b>(convert)</b> creates a MOBI on the phone.`
  String get webHelpStep4 {
    return Intl.message(
      'Choose a book and a format. <b>(download)</b> saves the file to the Kindle, <b>(send by email)</b> sends it to the Kindle address — automatically via SMTP if configured, or via the phone\'s mail app — and <b>(convert)</b> creates a MOBI on the phone.',
      name: 'webHelpStep4',
      desc: '',
      args: [],
    );
  }

  /// `The file will appear in your Kindle library or in the <b>Documents</b> folder.`
  String get webHelpStep5 {
    return Intl.message(
      'The file will appear in your Kindle library or in the <b>Documents</b> folder.',
      name: 'webHelpStep5',
      desc: '',
      args: [],
    );
  }

  /// `If a format does not open, try MOBI or AZW3. klos unpacks ZIP archives automatically: for the Kindle it takes MOBI, AZW3, AZW, PDF or TXT, for email — EPUB, PDF, TXT, RTF, DOC/DOCX or HTML, and for conversion — EPUB. If there is only FB2 or CBZ inside, klos will say so.`
  String get webHelpFormats {
    return Intl.message(
      'If a format does not open, try MOBI or AZW3. klos unpacks ZIP archives automatically: for the Kindle it takes MOBI, AZW3, AZW, PDF or TXT, for email — EPUB, PDF, TXT, RTF, DOC/DOCX or HTML, and for conversion — EPUB. If there is only FB2 or CBZ inside, klos will say so.',
      name: 'webHelpFormats',
      desc: '',
      args: [],
    );
  }

  /// `If the catalog has a <b>Search</b> field, search works directly from the Kindle: enter an author or a book title.`
  String get webHelpSearch {
    return Intl.message(
      'If the catalog has a <b>Search</b> field, search works directly from the Kindle: enter an author or a book title.',
      name: 'webHelpSearch',
      desc: '',
      args: [],
    );
  }

  /// `Conversion simplifies complex layout and does not work with DRM. Sending via the mail app works only while the klos app is open on the phone: the file is temporarily stored in the app cache.`
  String get webHelpLimits {
    return Intl.message(
      'Conversion simplifies complex layout and does not work with DRM. Sending via the mail app works only while the klos app is open on the phone: the file is temporarily stored in the app cache.',
      name: 'webHelpLimits',
      desc: '',
      args: [],
    );
  }

  /// `Books are not stored on the phone permanently: the server only passes them from the OPDS catalog to the Kindle. The phone must be nearby and connected to the same network. While the server is on, a notification is visible in the Android notification shade.`
  String get webHelpPrivacy {
    return Intl.message(
      'Books are not stored on the phone permanently: the server only passes them from the OPDS catalog to the Kindle. The phone must be nearby and connected to the same network. While the server is on, a notification is visible in the Android notification shade.',
      name: 'webHelpPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Server error: {error}`
  String serverErrorLog(String error) {
    return Intl.message(
      'Server error: $error',
      name: 'serverErrorLog',
      desc: '',
      args: [error],
    );
  }

  /// `The {method} method is not supported.`
  String methodNotSupported(String method) {
    return Intl.message(
      'The $method method is not supported.',
      name: 'methodNotSupported',
      desc: '',
      args: [method],
    );
  }

  /// `Request error {uri}: {error}`
  String requestErrorLog(String uri, String error) {
    return Intl.message(
      'Request error $uri: $error',
      name: 'requestErrorLog',
      desc: '',
      args: [uri, error],
    );
  }

  /// `Internal server error: {error}`
  String internalServerError(String error) {
    return Intl.message(
      'Internal server error: $error',
      name: 'internalServerError',
      desc: '',
      args: [error],
    );
  }

  /// `The link has no valid image address.`
  String get badImageAddress {
    return Intl.message(
      'The link has no valid image address.',
      name: 'badImageAddress',
      desc: '',
      args: [],
    );
  }

  /// `The OPDS server returned something other than an image.`
  String get notAnImage {
    return Intl.message(
      'The OPDS server returned something other than an image.',
      name: 'notAnImage',
      desc: '',
      args: [],
    );
  }

  /// `Cover: {error}`
  String coverLog(String error) {
    return Intl.message(
      'Cover: $error',
      name: 'coverLog',
      desc: '',
      args: [error],
    );
  }

  /// `Could not fetch the image: {error}`
  String imageFetchFailed(String error) {
    return Intl.message(
      'Could not fetch the image: $error',
      name: 'imageFetchFailed',
      desc: '',
      args: [error],
    );
  }

  /// `The link has no valid catalog address.`
  String get badCatalogAddress {
    return Intl.message(
      'The link has no valid catalog address.',
      name: 'badCatalogAddress',
      desc: '',
      args: [],
    );
  }

  /// `Catalog: {title} ({count}) — {ip}`
  String catalogLog(String title, int count, String ip) {
    return Intl.message(
      'Catalog: $title ($count) — $ip',
      name: 'catalogLog',
      desc: '',
      args: [title, count, ip],
    );
  }

  /// `Catalog error {url}: {error}`
  String catalogErrorLog(String url, String error) {
    return Intl.message(
      'Catalog error $url: $error',
      name: 'catalogErrorLog',
      desc: '',
      args: [url, error],
    );
  }

  /// `The link has no valid search template.`
  String get badSearchTemplate {
    return Intl.message(
      'The link has no valid search template.',
      name: 'badSearchTemplate',
      desc: '',
      args: [],
    );
  }

  /// `Could not build the search address.`
  String get searchUrlFailed {
    return Intl.message(
      'Could not build the search address.',
      name: 'searchUrlFailed',
      desc: '',
      args: [],
    );
  }

  /// `OpenSearch: {error}`
  String openSearchLog(String error) {
    return Intl.message(
      'OpenSearch: $error',
      name: 'openSearchLog',
      desc: '',
      args: [error],
    );
  }

  /// `The link has no valid file address.`
  String get badFileAddress {
    return Intl.message(
      'The link has no valid file address.',
      name: 'badFileAddress',
      desc: '',
      args: [],
    );
  }

  /// `The file is too large to download (over 120 MB).`
  String get downloadTooLarge {
    return Intl.message(
      'The file is too large to download (over 120 MB).',
      name: 'downloadTooLarge',
      desc: '',
      args: [],
    );
  }

  /// `Download: {name} — {ip}`
  String downloadLog(String name, String ip) {
    return Intl.message(
      'Download: $name — $ip',
      name: 'downloadLog',
      desc: '',
      args: [name, ip],
    );
  }

  /// `Download: {name} — {ip} (from ZIP)`
  String downloadFromZipLog(String name, String ip) {
    return Intl.message(
      'Download: $name — $ip (from ZIP)',
      name: 'downloadFromZipLog',
      desc: '',
      args: [name, ip],
    );
  }

  /// `Could not transfer the file: {error}`
  String fileTransferFailed(String error) {
    return Intl.message(
      'Could not transfer the file: $error',
      name: 'fileTransferFailed',
      desc: '',
      args: [error],
    );
  }

  /// `File transfer interrupted: {error}`
  String fileTransferInterrupted(String error) {
    return Intl.message(
      'File transfer interrupted: $error',
      name: 'fileTransferInterrupted',
      desc: '',
      args: [error],
    );
  }

  /// `The link has no valid book address.`
  String get badBookAddress {
    return Intl.message(
      'The link has no valid book address.',
      name: 'badBookAddress',
      desc: '',
      args: [],
    );
  }

  /// `The OPDS server returned an empty file.`
  String get opdsEmptyFile {
    return Intl.message(
      'The OPDS server returned an empty file.',
      name: 'opdsEmptyFile',
      desc: '',
      args: [],
    );
  }

  /// `Conversion: “{title}” — {ip}`
  String conversionLog(String title, String ip) {
    return Intl.message(
      'Conversion: “$title” — $ip',
      name: 'conversionLog',
      desc: '',
      args: [title, ip],
    );
  }

  /// `Conversion: done “{file}” — {ip}`
  String conversionDoneLog(String file, String ip) {
    return Intl.message(
      'Conversion: done “$file” — $ip',
      name: 'conversionDoneLog',
      desc: '',
      args: [file, ip],
    );
  }

  /// `Sending by email is not available in this build of the app.`
  String get sendUnavailable {
    return Intl.message(
      'Sending by email is not available in this build of the app.',
      name: 'sendUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `The klos app is not open on the phone right now. Open it on screen and try again — the mail app will open with the message ready.`
  String get appNotOpenMailApp {
    return Intl.message(
      'The klos app is not open on the phone right now. Open it on screen and try again — the mail app will open with the message ready.',
      name: 'appNotOpenMailApp',
      desc: '',
      args: [],
    );
  }

  /// `The file is too large to send by email (over 100 MB).`
  String get tooLargeToEmail {
    return Intl.message(
      'The file is too large to send by email (over 100 MB).',
      name: 'tooLargeToEmail',
      desc: '',
      args: [],
    );
  }

  /// `Email (mail app): “{name}” — {ip}`
  String mailAppLog(String name, String ip) {
    return Intl.message(
      'Email (mail app): “$name” — $ip',
      name: 'mailAppLog',
      desc: '',
      args: [name, ip],
    );
  }

  /// `Email (mail app): “{name}” — {ip} (from ZIP)`
  String mailAppFromZipLog(String name, String ip) {
    return Intl.message(
      'Email (mail app): “$name” — $ip (from ZIP)',
      name: 'mailAppFromZipLog',
      desc: '',
      args: [name, ip],
    );
  }

  /// `Email sending error: {error}`
  String mailPrepareErrorLog(String error) {
    return Intl.message(
      'Email sending error: $error',
      name: 'mailPrepareErrorLog',
      desc: '',
      args: [error],
    );
  }

  /// `Could not prepare the file: {error}`
  String prepareFileFailed(String error) {
    return Intl.message(
      'Could not prepare the file: $error',
      name: 'prepareFileFailed',
      desc: '',
      args: [error],
    );
  }

  /// `No Kindle address is set. Open the klos app, go to “Settings” → “Kindle email” and enter the Kindle address. SMTP can be left empty: the mail app will open instead.`
  String get kindleAddressMissing {
    return Intl.message(
      'No Kindle address is set. Open the klos app, go to “Settings” → “Kindle email” and enter the Kindle address. SMTP can be left empty: the mail app will open instead.',
      name: 'kindleAddressMissing',
      desc: '',
      args: [],
    );
  }

  /// `Amazon's Send to Kindle accepts EPUB, PDF, TXT, DOC/DOCX and images by email; it does not convert FB2, CBZ or ZIP. Add the sender address to the “Approved Personal Document E-mail List” in your Amazon settings, otherwise the email will be rejected.`
  String get amazonRejectsFormats {
    return Intl.message(
      'Amazon\'s Send to Kindle accepts EPUB, PDF, TXT, DOC/DOCX and images by email; it does not convert FB2, CBZ or ZIP. Add the sender address to the “Approved Personal Document E-mail List” in your Amazon settings, otherwise the email will be rejected.',
      name: 'amazonRejectsFormats',
      desc: '',
      args: [],
    );
  }

  /// `Email: queued “{title}” — {ip}`
  String mailQueuedLog(String title, String ip) {
    return Intl.message(
      'Email: queued “$title” — $ip',
      name: 'mailQueuedLog',
      desc: '',
      args: [title, ip],
    );
  }

  /// `Kindle email is not configured.`
  String get mailNotConfiguredShort {
    return Intl.message(
      'Kindle email is not configured.',
      name: 'mailNotConfiguredShort',
      desc: '',
      args: [],
    );
  }

  /// `Email: skipped — Kindle email is not configured`
  String get mailSkippedLog {
    return Intl.message(
      'Email: skipped — Kindle email is not configured',
      name: 'mailSkippedLog',
      desc: '',
      args: [],
    );
  }

  /// `Email: downloading “{title}”`
  String mailDownloadLog(String title) {
    return Intl.message(
      'Email: downloading “$title”',
      name: 'mailDownloadLog',
      desc: '',
      args: [title],
    );
  }

  /// `Email: “{title}” sent to {email}`
  String mailSentLog(String title, String email) {
    return Intl.message(
      'Email: “$title” sent to $email',
      name: 'mailSentLog',
      desc: '',
      args: [title, email],
    );
  }

  /// `Email: error — {error}`
  String mailErrorLog(String error) {
    return Intl.message(
      'Email: error — $error',
      name: 'mailErrorLog',
      desc: '',
      args: [error],
    );
  }

  /// `Home`
  String get homeLink {
    return Intl.message('Home', name: 'homeLink', desc: '', args: []);
  }

  /// `http://phone-ip:8080/`
  String get helpAddressPlaceholder {
    return Intl.message(
      'http://phone-ip:8080/',
      name: 'helpAddressPlaceholder',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get fileFallback {
    return Intl.message('File', name: 'fileFallback', desc: '', args: []);
  }

  /// `Send book to Kindle`
  String get shareChooserTitle {
    return Intl.message(
      'Send book to Kindle',
      name: 'shareChooserTitle',
      desc: '',
      args: [],
    );
  }

  /// `No file or Kindle address was provided.`
  String get shareMissingArgs {
    return Intl.message(
      'No file or Kindle address was provided.',
      name: 'shareMissingArgs',
      desc: '',
      args: [],
    );
  }

  /// `The book file was not found.`
  String get shareMissingFile {
    return Intl.message(
      'The book file was not found.',
      name: 'shareMissingFile',
      desc: '',
      args: [],
    );
  }

  /// `Local server`
  String get notificationChannelName {
    return Intl.message(
      'Local server',
      name: 'notificationChannelName',
      desc: '',
      args: [],
    );
  }

  /// `Notifications about the OPDS server for Kindle`
  String get notificationChannelDescription {
    return Intl.message(
      'Notifications about the OPDS server for Kindle',
      name: 'notificationChannelDescription',
      desc: '',
      args: [],
    );
  }

  /// `The server is running`
  String get notificationRunning {
    return Intl.message(
      'The server is running',
      name: 'notificationRunning',
      desc: '',
      args: [],
    );
  }

  /// `The server is running · port {port}`
  String notificationRunningPort(int port) {
    return Intl.message(
      'The server is running · port $port',
      name: 'notificationRunningPort',
      desc: '',
      args: [port],
    );
  }

  /// `The ZIP archive contains too many files.`
  String get zipTooManyEntries {
    return Intl.message(
      'The ZIP archive contains too many files.',
      name: 'zipTooManyEntries',
      desc: '',
      args: [],
    );
  }

  /// `The EPUB contains too many files to convert safely.`
  String get epubTooManyEntries {
    return Intl.message(
      'The EPUB contains too many files to convert safely.',
      name: 'epubTooManyEntries',
      desc: '',
      args: [],
    );
  }

  /// `A file inside the EPUB is too large to convert.`
  String get epubEntryTooLarge {
    return Intl.message(
      'A file inside the EPUB is too large to convert.',
      name: 'epubEntryTooLarge',
      desc: '',
      args: [],
    );
  }

  /// `The EPUB expands to too much data to convert.`
  String get epubExpandsTooMuch {
    return Intl.message(
      'The EPUB expands to too much data to convert.',
      name: 'epubExpandsTooMuch',
      desc: '',
      args: [],
    );
  }

  /// `{size} B`
  String fileSizeBytes(int size) {
    return Intl.message(
      '$size B',
      name: 'fileSizeBytes',
      desc: '',
      args: [size],
    );
  }

  /// `{size} KB`
  String fileSizeKb(String size) {
    return Intl.message('$size KB', name: 'fileSizeKb', desc: '', args: [size]);
  }

  /// `{size} MB`
  String fileSizeMb(String size) {
    return Intl.message('$size MB', name: 'fileSizeMb', desc: '', args: [size]);
  }

  /// `Local files`
  String get localFiles {
    return Intl.message('Local files', name: 'localFiles', desc: '', args: []);
  }

  /// `Local folder`
  String get localFolder {
    return Intl.message(
      'Local folder',
      name: 'localFolder',
      desc: '',
      args: [],
    );
  }

  /// `Downloads`
  String get localFolderDefaultName {
    return Intl.message(
      'Downloads',
      name: 'localFolderDefaultName',
      desc: '',
      args: [],
    );
  }

  /// `↑ Up`
  String get localFolderUp {
    return Intl.message('↑ Up', name: 'localFolderUp', desc: '', args: []);
  }

  /// `Folder root`
  String get localFolderRoot {
    return Intl.message(
      'Folder root',
      name: 'localFolderRoot',
      desc: '',
      args: [],
    );
  }

  /// `No books in this folder. Subfolders are shown here too.`
  String get localFolderEmpty {
    return Intl.message(
      'No books in this folder. Subfolders are shown here too.',
      name: 'localFolderEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Folder`
  String get localFolderLabel {
    return Intl.message('Folder', name: 'localFolderLabel', desc: '', args: []);
  }

  /// `The Kindle cannot open {format} directly, and Amazon does not accept it by email. Try EPUB, MOBI or PDF instead.`
  String localFormatNeedsDelivery(String format) {
    return Intl.message(
      'The Kindle cannot open $format directly, and Amazon does not accept it by email. Try EPUB, MOBI or PDF instead.',
      name: 'localFormatNeedsDelivery',
      desc: '',
      args: [format],
    );
  }

  /// `No folder is connected yet. Open klos → Settings → Local files and choose a folder with books. On Android 11+ the Downloads folder itself cannot be selected — choose a subfolder such as Download/Books.`
  String get localFolderNotConnected {
    return Intl.message(
      'No folder is connected yet. Open klos → Settings → Local files and choose a folder with books. On Android 11+ the Downloads folder itself cannot be selected — choose a subfolder such as Download/Books.',
      name: 'localFolderNotConnected',
      desc: '',
      args: [],
    );
  }

  /// `Access not granted yet`
  String get localFolderNotConnectedShort {
    return Intl.message(
      'Access not granted yet',
      name: 'localFolderNotConnectedShort',
      desc: '',
      args: [],
    );
  }

  /// `The phone shares only the folder you confirm: Android does not let the app read all storage.`
  String get localFolderConnectHint {
    return Intl.message(
      'The phone shares only the folder you confirm: Android does not let the app read all storage.',
      name: 'localFolderConnectHint',
      desc: '',
      args: [],
    );
  }

  /// `Access granted`
  String get localFolderConnectedShort {
    return Intl.message(
      'Access granted',
      name: 'localFolderConnectedShort',
      desc: '',
      args: [],
    );
  }

  /// `This link does not belong to the selected folder.`
  String get localFolderBadLink {
    return Intl.message(
      'This link does not belong to the selected folder.',
      name: 'localFolderBadLink',
      desc: '',
      args: [],
    );
  }

  /// `Access to the folder was lost. Open klos → Settings → Local files and choose the folder again.`
  String get localFolderAccessLost {
    return Intl.message(
      'Access to the folder was lost. Open klos → Settings → Local files and choose the folder again.',
      name: 'localFolderAccessLost',
      desc: '',
      args: [],
    );
  }

  /// `Local folder: error — {error}`
  String localFolderErrorLog(String error) {
    return Intl.message(
      'Local folder: error — $error',
      name: 'localFolderErrorLog',
      desc: '',
      args: [error],
    );
  }

  /// `Local folder “{title}”: {count} entries — {ip}`
  String localCatalogLog(String title, int count, String ip) {
    return Intl.message(
      'Local folder “$title”: $count entries — $ip',
      name: 'localCatalogLog',
      desc: '',
      args: [title, count, ip],
    );
  }

  /// `Choosing a folder is available only on Android.`
  String get localFolderAndroidOnly {
    return Intl.message(
      'Choosing a folder is available only on Android.',
      name: 'localFolderAndroidOnly',
      desc: '',
      args: [],
    );
  }

  /// `Could not open the folder picker: {error}`
  String localFolderPickerFailed(String error) {
    return Intl.message(
      'Could not open the folder picker: $error',
      name: 'localFolderPickerFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Could not read the folder: {error}`
  String localFolderReadFailed(String error) {
    return Intl.message(
      'Could not read the folder: $error',
      name: 'localFolderReadFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Could not read the file: {error}`
  String localFileReadFailed(String error) {
    return Intl.message(
      'Could not read the file: $error',
      name: 'localFileReadFailed',
      desc: '',
      args: [error],
    );
  }

  /// `The file is larger than {mb} MB and cannot be used this way.`
  String localFileTooLarge(int mb) {
    return Intl.message(
      'The file is larger than $mb MB and cannot be used this way.',
      name: 'localFileTooLarge',
      desc: '',
      args: [mb],
    );
  }

  /// `The Kindle sees the books from this folder, including subfolders. Android will ask you to confirm the folder once. If the books are in Downloads, select a subfolder — on Android 11+ the Downloads root itself cannot be selected. The choice is applied immediately.`
  String get localFolderHint {
    return Intl.message(
      'The Kindle sees the books from this folder, including subfolders. Android will ask you to confirm the folder once. If the books are in Downloads, select a subfolder — on Android 11+ the Downloads root itself cannot be selected. The choice is applied immediately.',
      name: 'localFolderHint',
      desc: '',
      args: [],
    );
  }

  /// `Android 11+ does not allow confirming the Downloads root. In the picker open Downloads, tap ⋮ → New folder, create e.g. Books, move the books there and select that subfolder. On Android 10 and older you can select Downloads itself.`
  String get localFolderDefaultNote {
    return Intl.message(
      'Android 11+ does not allow confirming the Downloads root. In the picker open Downloads, tap ⋮ → New folder, create e.g. Books, move the books there and select that subfolder. On Android 10 and older you can select Downloads itself.',
      name: 'localFolderDefaultNote',
      desc: '',
      args: [],
    );
  }

  /// `Choose folder`
  String get chooseFolder {
    return Intl.message(
      'Choose folder',
      name: 'chooseFolder',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get resetFolder {
    return Intl.message('Reset', name: 'resetFolder', desc: '', args: []);
  }

  /// `Library`
  String get library {
    return Intl.message('Library', name: 'library', desc: '', args: []);
  }

  /// `Browse catalog`
  String get browseCatalog {
    return Intl.message(
      'Browse catalog',
      name: 'browseCatalog',
      desc: '',
      args: [],
    );
  }

  /// `Read the catalog here and save books to favorites`
  String get browseCatalogHint {
    return Intl.message(
      'Read the catalog here and save books to favorites',
      name: 'browseCatalogHint',
      desc: '',
      args: [],
    );
  }

  /// `Open series`
  String get openSeries {
    return Intl.message('Open series', name: 'openSeries', desc: '', args: []);
  }

  /// `This book has no file to download.`
  String get downloadLinkMissing {
    return Intl.message(
      'This book has no file to download.',
      name: 'downloadLinkMissing',
      desc: '',
      args: [],
    );
  }

  /// `Download to folder`
  String get downloadToFolder {
    return Intl.message(
      'Download to folder',
      name: 'downloadToFolder',
      desc: '',
      args: [],
    );
  }

  /// `The book is saved to the chosen folder, and the Kindle sees it under “Local files”. klos converts EPUB and FB2 to MOBI and unpacks ZIP archives.`
  String get downloadToFolderNote {
    return Intl.message(
      'The book is saved to the chosen folder, and the Kindle sees it under “Local files”. klos converts EPUB and FB2 to MOBI and unpacks ZIP archives.',
      name: 'downloadToFolderNote',
      desc: '',
      args: [],
    );
  }

  /// `To save a book for the Kindle, choose a local folder on the home screen.`
  String get downloadFolderMissing {
    return Intl.message(
      'To save a book for the Kindle, choose a local folder on the home screen.',
      name: 'downloadFolderMissing',
      desc: '',
      args: [],
    );
  }

  /// `Saved: {name}`
  String savedToFolder(String name) {
    return Intl.message(
      'Saved: $name',
      name: 'savedToFolder',
      desc: '',
      args: [name],
    );
  }

  /// `Could not save the book: {error}`
  String saveToFolderFailed(String error) {
    return Intl.message(
      'Could not save the book: $error',
      name: 'saveToFolderFailed',
      desc: '',
      args: [error],
    );
  }

  /// `Choose a local folder on the home screen first.`
  String get localFolderNotChosen {
    return Intl.message(
      'Choose a local folder on the home screen first.',
      name: 'localFolderNotChosen',
      desc: '',
      args: [],
    );
  }

  /// `Could not write the file to the folder: {error}`
  String localFolderWriteFailed(String error) {
    return Intl.message(
      'Could not write the file to the folder: $error',
      name: 'localFolderWriteFailed',
      desc: '',
      args: [error],
    );
  }

  /// `No permission to write to the folder. Choose the folder again on the home screen.`
  String get localFolderWriteDenied {
    return Intl.message(
      'No permission to write to the folder. Choose the folder again on the home screen.',
      name: 'localFolderWriteDenied',
      desc: '',
      args: [],
    );
  }

  /// `Favorites`
  String get favorites {
    return Intl.message('Favorites', name: 'favorites', desc: '', args: []);
  }

  /// `No saved books yet. Open the catalog and tap the bookmark next to a book you want.`
  String get favoritesEmpty {
    return Intl.message(
      'No saved books yet. Open the catalog and tap the bookmark next to a book you want.',
      name: 'favoritesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Nothing saved yet`
  String get favoritesEmptyShort {
    return Intl.message(
      'Nothing saved yet',
      name: 'favoritesEmptyShort',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{{count} book} other{{count} books}}`
  String favoritesCount(int count) {
    return Intl.plural(
      count,
      one: '$count book',
      other: '$count books',
      name: 'favoritesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Add to favorites`
  String get favoriteAdd {
    return Intl.message(
      'Add to favorites',
      name: 'favoriteAdd',
      desc: '',
      args: [],
    );
  }

  /// `Remove from favorites`
  String get favoriteRemove {
    return Intl.message(
      'Remove from favorites',
      name: 'favoriteRemove',
      desc: '',
      args: [],
    );
  }

  /// `← Back`
  String get catalogBack {
    return Intl.message('← Back', name: 'catalogBack', desc: '', args: []);
  }

  /// `Next →`
  String get catalogForward {
    return Intl.message('Next →', name: 'catalogForward', desc: '', args: []);
  }

  /// `Could not load the catalog`
  String get catalogLoadFailed {
    return Intl.message(
      'Could not load the catalog',
      name: 'catalogLoadFailed',
      desc: '',
      args: [],
    );
  }

  /// `Check the catalog address and the internet connection.`
  String get catalogLoadFailedHint {
    return Intl.message(
      'Check the catalog address and the internet connection.',
      name: 'catalogLoadFailedHint',
      desc: '',
      args: [],
    );
  }

  /// `Favorites are empty.`
  String get favoritesEmptyOnKindleShort {
    return Intl.message(
      'Favorites are empty.',
      name: 'favoritesEmptyOnKindleShort',
      desc: '',
      args: [],
    );
  }

  /// `“send by email” goes to the Kindle address; “download” for EPUB/FB2 builds a MOBI on the phone — experimental, and complex layout is simplified. The email button appears only for formats Amazon accepts (EPUB, PDF, TXT, DOC/DOCX, RTF, HTML). If SMTP is configured, the email is sent automatically; otherwise the phone's mail app opens with the attachment ready. Everything else is downloaded as a regular file; klos unpacks ZIP archives itself and takes the file suitable for the Kindle or Amazon.`
  String get webHelpActions {
    return Intl.message(
      '“send by email” goes to the Kindle address; “download” for EPUB/FB2 builds a MOBI on the phone — experimental, and complex layout is simplified. The email button appears only for formats Amazon accepts (EPUB, PDF, TXT, DOC/DOCX, RTF, HTML). If SMTP is configured, the email is sent automatically; otherwise the phone\'s mail app opens with the attachment ready. Everything else is downloaded as a regular file; klos unpacks ZIP archives itself and takes the file suitable for the Kindle or Amazon.',
      name: 'webHelpActions',
      desc: '',
      args: [],
    );
  }

  /// `Favorites are the books you saved in the klos app. Open Library → Browse catalog, tap the bookmark next to a book, and it appears in Favorites — on the Kindle too, with the same download and email buttons.`
  String get webHelpFavorites {
    return Intl.message(
      'Favorites are the books you saved in the klos app. Open Library → Browse catalog, tap the bookmark next to a book, and it appears in Favorites — on the Kindle too, with the same download and email buttons.',
      name: 'webHelpFavorites',
      desc: '',
      args: [],
    );
  }

  /// `Favorites: {count} book(s) — {ip}`
  String favoritesLog(int count, String ip) {
    return Intl.message(
      'Favorites: $count book(s) — $ip',
      name: 'favoritesLog',
      desc: '',
      args: [count, ip],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'uk'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
