import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/books/ebook_formats.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/entity/settings_entity.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/server/file_names.dart';
import 'package:klos/server/url_codec.dart';

/// Saves [settings] to the ObjectBox entity and reads them back.
AppSettings _roundTrip(AppSettings settings) =>
    SettingsEntity.fromSettings(settings).toSettings();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  group('url codec', () {
    test('round-trips URLs with unicode and query parameters', () {
      final original = Uri.parse(
        'http://example.com/opds/search?q=%D0%BA%D0%BD%D0%B8%D0%B3%D0%B0',
      );
      final decoded = decodeTarget(encodeTarget(original));
      expect(decoded, original);
    });

    test('returns null for invalid tokens', () {
      expect(decodeTarget(''), isNull);
      expect(decodeTarget('not a base64 token!'), isNull);
    });

    test('downloadHref carries title and type', () {
      final href = downloadHref(
        Uri.parse('http://example.com/book.epub'),
        title: 'Книга',
        type: 'application/epub+zip',
      );
      final uri = Uri.parse(href);
      expect(uri.path, startsWith('/download/'));
      expect(uri.pathSegments.last, 'Kniga.epub');
      expect(uri.queryParameters['n'], 'Книга');
      expect(uri.queryParameters['t'], 'application/epub+zip');
      expect(decodeTarget(uri.queryParameters['u']!), isNotNull);
    });

    test('browseHref starts with /browse', () {
      final href = browseHref(Uri.parse('http://example.com/opds'));
      expect(href, startsWith('/browse?u='));
    });

    test('mailHref points to /send and keeps the file name', () {
      final href = mailHref(
        Uri.parse('http://example.com/book.epub'),
        title: 'Книга',
        type: 'application/epub+zip',
      );
      final uri = Uri.parse(href);
      expect(uri.path, startsWith('/send/'));
      expect(uri.pathSegments.last, 'Kniga.epub');
      expect(uri.queryParameters['n'], 'Книга');
      expect(uri.queryParameters['t'], 'application/epub+zip');
      expect(decodeTarget(uri.queryParameters['u']!), isNotNull);
    });
  });

  group('ebook formats', () {
    test('maps MIME types to format keys', () {
      expect(EbookFormat.keyForMime('application/epub+zip'), 'EPUB');
      expect(EbookFormat.keyForMime('application/pdf'), 'PDF');
      expect(EbookFormat.keyForMime('application/x-mobipocket-ebook'), 'MOBI');
      expect(EbookFormat.keyForMime('application/x-mobi8-ebook'), 'AZW3');
      expect(EbookFormat.keyForMime('application/x-fictionbook+xml'), 'FB2');
      expect(EbookFormat.keyForMime('application/octet-stream'), 'OTHER');
      expect(EbookFormat.keyForMime(null), 'OTHER');
    });

    test('labels known formats and trims unknown MIME types', () {
      expect(EbookFormat.labelForMime('application/epub+zip'), 'EPUB');
      expect(EbookFormat.labelForMime('application/vnd.amazon.ebook'), 'AZW');
      expect(EbookFormat.labelForMime('text/plain; charset=utf-8'), 'TXT');
      expect(EbookFormat.labelForMime(''), 'Файл');
      expect(
        EbookFormat.labelForMime('application/x-very-long-format-type'),
        endsWith('...'),
      );
    });

    test('knows which formats the Kindle opens directly', () {
      expect(
        EbookFormat.downloadsDirectly('application/x-mobipocket-ebook'),
        isTrue,
      );
      expect(
        EbookFormat.downloadsDirectly('application/vnd.amazon.ebook'),
        isTrue,
      );
      expect(EbookFormat.downloadsDirectly('application/pdf'), isTrue);
      expect(
        EbookFormat.downloadsDirectly('text/plain; charset=utf-8'),
        isTrue,
      );

      expect(EbookFormat.downloadsDirectly('application/epub+zip'), isFalse);
      expect(EbookFormat.downloadsDirectly('application/fb2'), isFalse);
      expect(
        EbookFormat.downloadsDirectly('application/vnd.comicbook+zip'),
        isFalse,
      );
      expect(EbookFormat.downloadsDirectly('application/zip'), isFalse);
      expect(EbookFormat.downloadsDirectly('application/x-unknown'), isFalse);
    });

    test('converts EPUB and FB2 into MOBI before download', () {
      expect(EbookFormat.convertible('application/epub+zip'), isTrue);
      expect(EbookFormat.convertible('application/x-fictionbook+xml'), isTrue);
      expect(EbookFormat.convertible('application/fb2'), isTrue);
      expect(EbookFormat.convertible('application/pdf'), isFalse);
      expect(EbookFormat.convertible('application/zip'), isFalse);
      expect(EbookFormat.convertible(null), isFalse);
    });

    test('offers email only for formats Amazon accepts', () {
      expect(EbookFormat.emailable('application/epub+zip'), isTrue);
      expect(EbookFormat.emailable('application/pdf'), isTrue);
      expect(EbookFormat.emailable('text/plain'), isTrue);
      expect(EbookFormat.emailable('application/rtf'), isTrue);
      expect(EbookFormat.emailable('application/msword'), isTrue);
      expect(EbookFormat.emailable('text/html'), isTrue);
      expect(EbookFormat.emailable('application/x-fictionbook+xml'), isFalse);
      expect(EbookFormat.emailable('application/x-cbz'), isFalse);
      expect(EbookFormat.emailable('application/zip'), isFalse);
      expect(EbookFormat.emailable('application/x-mobipocket-ebook'), isFalse);
      expect(EbookFormat.emailable(null), isFalse);
    });
  });

  group('file names', () {
    test('adds the extension implied by the MIME type', () {
      final name = fileNameFor(
        url: Uri.parse('http://example.com/download.php?id=1'),
        title: 'Book',
        mime: 'application/x-mobipocket-ebook',
      );
      expect(name, 'Book.mobi');
    });

    test('replaces an existing ebook extension and transliterates', () {
      final name = fileNameFor(
        url: Uri.parse('http://example.com/book.pdf'),
        title: 'Книга.epub',
        mime: 'application/pdf',
      );
      expect(name, 'Kniga.pdf');
    });

    test('transliterates Ukrainian letters and typographic punctuation', () {
      final name = fileNameFor(
        url: Uri.parse('http://example.com/book'),
        title: 'Їжак Євген «Том — 1»',
        mime: 'application/epub+zip',
      );
      expect(name, 'Yizhak Yevgen Tom - 1.epub');
    });

    test('drops apostrophes and keeps the extension', () {
      final name = fileNameFor(
        url: Uri.parse('http://example.com/book'),
        title: 'Зв\u2019язок.txt',
        mime: 'text/plain',
      );
      expect(name, 'Zvyazok.txt');
    });

    test('uses underscores for URLs and truncates long names', () {
      final name = fileNameFor(
        url: Uri.parse('http://example.com/book'),
        title: 'A very long title ${'x' * 200}',
        mime: 'application/epub+zip',
        underscores: true,
      );
      expect(name, endsWith('.epub'));
      expect(name, isNot(contains(' ')));
      expect(name.runes.length, lessThanOrEqualTo(120));
    });

    test('builds an RFC 5987 content disposition', () {
      final disposition = contentDispositionFor(
        url: Uri.parse('http://example.com/book'),
        title: 'Книга',
        mime: 'application/epub+zip',
      );
      expect(disposition, startsWith('attachment; filename="'));
      expect(disposition, contains('filename*=UTF-8'));
      expect(disposition, contains('.epub'));
    });

    test('maps mobi8 to azw3', () {
      expect(extensionForMime('application/x-mobi8-ebook'), '.azw3');
      expect(extensionForMime('application/octet-stream'), isNull);
    });
  });

  group('AppSettings.parseCatalogUrl', () {
    test('adds http scheme when missing', () {
      final url = AppSettings.parseCatalogUrl('192.168.1.20:8080/opds');
      expect(url.toString(), 'http://192.168.1.20:8080/opds');
    });

    test('accepts https and keeps query', () {
      final url = AppSettings.parseCatalogUrl('https://example.com/opds?q=1');
      expect(url?.scheme, 'https');
      expect(url?.query, 'q=1');
    });

    test('rejects unsupported schemes and empty input', () {
      expect(AppSettings.parseCatalogUrl(''), isNull);
      expect(AppSettings.parseCatalogUrl('ftp://example.com/opds'), isNull);
      expect(AppSettings.parseCatalogUrl('http://'), isNull);
    });
  });

  group('kindle mail settings', () {
    const configured = AppSettings(
      catalogUrl: null,
      kindleEmail: 'reader@kindle.com',
      smtpHost: 'smtp.example.com',
      senderEmail: 'sender@example.com',
    );

    test('has no email delivery configured by default', () {
      const settings = AppSettings(catalogUrl: null);
      expect(settings.smtpPort, 587);
      expect(settings.smtpSsl, isFalse);
      expect(settings.hasKindleEmail, isFalse);
      expect(settings.emailConfigured, isFalse);
    });

    test('requires Kindle address, SMTP host and sender', () {
      expect(configured.emailConfigured, isTrue);

      expect(
        const AppSettings(
          catalogUrl: null,
          smtpHost: 'smtp.example.com',
          senderEmail: 'sender@example.com',
        ).emailConfigured,
        isFalse,
      );
      expect(
        const AppSettings(
          catalogUrl: null,
          kindleEmail: 'reader@kindle.com',
          senderEmail: 'sender@example.com',
        ).emailConfigured,
        isFalse,
      );
      expect(
        const AppSettings(
          catalogUrl: null,
          kindleEmail: 'reader@kindle.com',
          smtpHost: 'smtp.example.com',
        ).emailConfigured,
        isFalse,
      );
    });

    test('validates email addresses', () {
      expect(AppSettings.isValidEmail('reader@kindle.com'), isTrue);
      expect(AppSettings.isValidEmail('  reader@kindle.com '), isTrue);
      expect(AppSettings.isValidEmail(''), isFalse);
      expect(AppSettings.isValidEmail('reader'), isFalse);
      expect(AppSettings.isValidEmail('reader@'), isFalse);
      expect(AppSettings.isValidEmail('@kindle.com'), isFalse);
      expect(AppSettings.isValidEmail('reader@kindle'), isFalse);
      expect(AppSettings.isValidEmail('two@at@kindle.com'), isFalse);
      expect(AppSettings.isValidEmail('reader @kindle.com'), isFalse);
      expect(AppSettings.isValidEmail('reader@.com'), isFalse);
    });

    test('trims mail fields', () {
      const settings = AppSettings(
        catalogUrl: null,
        kindleEmail: ' reader@kindle.com ',
        smtpHost: ' smtp.example.com ',
        senderEmail: ' sender@example.com ',
      );
      final normalized = settings.normalized();
      expect(normalized.kindleEmail, 'reader@kindle.com');
      expect(normalized.smtpHost, 'smtp.example.com');
      expect(normalized.senderEmail, 'sender@example.com');
      expect(normalized.emailConfigured, isTrue);
    });

    test('recognizes only Amazon Kindle domains', () {
      expect(AppSettings.isKindleDomain('@kindle.com'), isTrue);
      expect(AppSettings.isKindleDomain('@kindle.co.uk'), isTrue);
      expect(AppSettings.isKindleDomain('@kindle.de'), isTrue);
      expect(AppSettings.isKindleDomain('@KINDLE.COM'), isTrue);
      expect(AppSettings.isKindleDomain('@vv.mol'), isFalse);
      expect(AppSettings.isKindleDomain('@example.com'), isFalse);
      expect(AppSettings.isKindleDomain(''), isFalse);
    });

    test('replaces a non-Kindle domain when saving the address', () {
      // A stray domain must never survive; the name is kept.
      expect(
        AppSettings.normalizeKindleEmail('reader@vv.mol'),
        'reader@kindle.com',
      );
      expect(
        AppSettings.normalizeKindleEmail('reader@kindle.com'),
        'reader@kindle.com',
      );
      // Regional Kindle domains are kept.
      expect(
        AppSettings.normalizeKindleEmail('reader@kindle.co.uk'),
        'reader@kindle.co.uk',
      );
      // A bare name is left alone; the field adds the domain itself.
      expect(AppSettings.normalizeKindleEmail('reader'), 'reader');
      expect(AppSettings.normalizeKindleEmail(''), '');
    });

    test('normalized settings always use a Kindle domain', () {
      const settings = AppSettings(
        catalogUrl: null,
        kindleEmail: ' reader@vv.mol ',
      );
      final normalized = settings.normalized();
      expect(normalized.kindleEmail, 'reader@kindle.com');
      expect(normalized.hasKindleEmail, isTrue);
    });

    test('round-trips mail settings through the ObjectBox entity', () {
      final settings = AppSettings(
        catalogUrl: Uri.parse('http://192.168.1.20:8080/opds'),
        kindleEmail: 'reader@kindle.com',
        smtpHost: 'smtp.example.com',
        smtpPort: 465,
        smtpUsername: 'user@example.com',
        smtpPassword: 'secret',
        senderEmail: 'user@example.com',
        smtpSsl: true,
      );

      final loaded = _roundTrip(settings);
      expect(loaded.kindleEmail, 'reader@kindle.com');
      expect(loaded.smtpHost, 'smtp.example.com');
      expect(loaded.smtpPort, 465);
      expect(loaded.smtpUsername, 'user@example.com');
      expect(loaded.smtpPassword, 'secret');
      expect(loaded.senderEmail, 'user@example.com');
      expect(loaded.smtpSsl, isTrue);
      expect(loaded.emailConfigured, isTrue);
      expect(loaded, settings);
    });
  });

  group('kindle delivery', () {
    test('is off by default', () {
      const settings = AppSettings(catalogUrl: null);
      expect(settings.hasKindleEmail, isFalse);
      expect(settings.smtpConfigured, isFalse);
      expect(settings.emailConfigured, isFalse);
    });

    test('mail is available with only a Kindle address', () {
      const settings = AppSettings(
        catalogUrl: null,
        kindleEmail: 'reader@kindle.com',
      );
      expect(settings.hasKindleEmail, isTrue);
      expect(settings.smtpConfigured, isFalse);
      expect(settings.emailConfigured, isFalse);
    });

    test('SMTP needs only a host and a sender', () {
      const settings = AppSettings(
        catalogUrl: null,
        smtpHost: 'smtp.example.com',
        senderEmail: 'sender@example.com',
      );
      expect(settings.smtpConfigured, isTrue);
      expect(settings.hasKindleEmail, isFalse);
      expect(settings.emailConfigured, isFalse);
    });

    test('defaults keep delivery off', () {
      final loaded = SettingsEntity().toSettings();
      expect(loaded.hasKindleEmail, isFalse);
      expect(loaded.emailConfigured, isFalse);
    });
  });

  group('catalog appearance', () {
    test('shows covers by default', () {
      const settings = AppSettings(catalogUrl: null);
      expect(settings.showCovers, isTrue);
      expect(settings.normalized().showCovers, isTrue);
    });

    test('keeps the cover choice through the entity', () {
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, showCovers: false))
            .showCovers,
        isFalse,
      );
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, showCovers: true))
            .showCovers,
        isTrue,
      );
    });
  });

  group('wake lock settings', () {
    test('is off by default', () {
      expect(const AppSettings(catalogUrl: null).keepAwake, isFalse);
      expect(SettingsEntity().toSettings().keepAwake, isFalse);
    });

    test('round-trips the choice through the entity', () {
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, keepAwake: true))
            .keepAwake,
        isTrue,
      );
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, keepAwake: false))
            .keepAwake,
        isFalse,
      );
    });

    test('survives normalization and a folder change', () {
      final normalized = const AppSettings(
        catalogUrl: null,
        keepAwake: true,
      ).normalized();
      expect(normalized.keepAwake, isTrue);

      final connected = normalized.withLocalFolder(
        uri: 'content://example/tree/primary%3ABooks',
        name: 'Books',
      );
      expect(connected.keepAwake, isTrue);
      expect(connected.hasLocalFolder, isTrue);
    });
  });

  group('automatic stop settings', () {
    test('defaults to ten minutes and is on', () {
      expect(
        const AppSettings(catalogUrl: null).autoStopMinutes,
        AppSettings.defaultAutoStopMinutes,
      );
      expect(SettingsEntity().toSettings().autoStopMinutes, 10);
      expect(const AppSettings(catalogUrl: null).autoStopEnabled, isTrue);
    });

    test('off means the server keeps running', () {
      const settings = AppSettings(catalogUrl: null, autoStopMinutes: 0);
      expect(settings.autoStopEnabled, isFalse);
      expect(_roundTrip(settings).autoStopMinutes, 0);
    });

    test('round-trips every offered value through the entity', () {
      for (final minutes in AppSettings.autoStopMinutesOptions) {
        expect(
          _roundTrip(AppSettings(catalogUrl: null, autoStopMinutes: minutes))
              .autoStopMinutes,
          minutes,
        );
      }
    });

    test('falls back to the default for an unknown value', () {
      expect(
        const AppSettings(
          catalogUrl: null,
          autoStopMinutes: 7,
        ).normalized().autoStopMinutes,
        AppSettings.defaultAutoStopMinutes,
      );
      expect(
        SettingsEntity(autoStopMinutes: 7).toSettings().autoStopMinutes,
        AppSettings.defaultAutoStopMinutes,
      );
    });

    test('survives normalization and a folder change', () {
      final normalized = const AppSettings(
        catalogUrl: null,
        autoStopMinutes: 30,
      ).normalized();
      expect(normalized.autoStopMinutes, 30);

      final connected = normalized.withLocalFolder(
        uri: 'content://example/tree/primary%3ABooks',
        name: 'Books',
      );
      expect(connected.autoStopMinutes, 30);
    });
  });

  group('PIN protection settings', () {
    test('is off by default', () {
      expect(const AppSettings(catalogUrl: null).requirePin, isFalse);
      expect(SettingsEntity().toSettings().requirePin, isFalse);
    });

    test('round-trips the choice through the entity', () {
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, requirePin: true))
            .requirePin,
        isTrue,
      );
      expect(
        _roundTrip(const AppSettings(catalogUrl: null, requirePin: false))
            .requirePin,
        isFalse,
      );
    });

    test('survives normalization and a folder change', () {
      final normalized = const AppSettings(
        catalogUrl: null,
        requirePin: true,
      ).normalized();
      expect(normalized.requirePin, isTrue);

      final connected = normalized.withLocalFolder(
        uri: 'content://example/tree/primary%3ABooks',
        name: 'Books',
      );
      expect(connected.requirePin, isTrue);
    });

    test('is kept when other values are copied', () {
      const settings = AppSettings(catalogUrl: null, requirePin: true);
      expect(settings.copyWith(port: 9090).requirePin, isTrue);
      expect(settings.copyWith(requirePin: false).requirePin, isFalse);
    });
  });

  group('settings copy', () {
    test('replaces only the values it is given', () {
      const settings = AppSettings(
        catalogUrl: null,
        kindleEmail: 'reader@kindle.com',
        port: 9090,
      );

      final changed = settings.copyWith(port: 8081, keepAwake: true);

      expect(changed.port, 8081);
      expect(changed.keepAwake, isTrue);
      expect(changed.kindleEmail, 'reader@kindle.com');
      expect(changed.catalogUrl, isNull);
    });

    test('keeps the catalog address unless it is cleared', () {
      final settings = AppSettings(
        catalogUrl: Uri.parse('http://example.com/opds'),
      );

      expect(settings.copyWith(port: 9090).catalogUrl, settings.catalogUrl);
      expect(settings.copyWith(clearCatalogUrl: true).catalogUrl, isNull);
    });
  });

  group('local folder settings', () {
    test('defaults to no connected folder', () {
      const settings = AppSettings(catalogUrl: null);
      expect(settings.localFolderUri, '');
      expect(settings.localFolderName, '');
      expect(settings.hasLocalFolder, isFalse);
    });

    test('round-trips the folder through the entity', () {
      final loaded = _roundTrip(
        const AppSettings(
          catalogUrl: null,
          localFolderUri:
              'content://com.android.externalstorage.documents/tree/'
              'primary%3ABooks',
          localFolderName: 'Books',
        ),
      );
      expect(loaded.localFolderUri, contains('primary%3ABooks'));
      expect(loaded.localFolderName, 'Books');
      expect(loaded.hasLocalFolder, isTrue);
    });

    test('drops the name when the folder is reset', () {
      final loaded = _roundTrip(
        const AppSettings(
          catalogUrl: null,
          localFolderUri: '  ',
          localFolderName: 'Books',
        ).normalized(),
      );
      expect(loaded.localFolderUri, '');
      expect(loaded.localFolderName, '');
      expect(loaded.hasLocalFolder, isFalse);
    });

    test('trims the folder URI and name', () {
      final normalized = const AppSettings(
        catalogUrl: null,
        localFolderUri: ' content://example/tree/primary%3ABooks ',
        localFolderName: ' Books ',
      ).normalized();

      expect(
        normalized.localFolderUri,
        'content://example/tree/primary%3ABooks',
      );
      expect(normalized.localFolderName, 'Books');
      expect(normalized.hasLocalFolder, isTrue);
    });

    test('withLocalFolder keeps other settings and clears the name', () {
      const settings = AppSettings(
        catalogUrl: null,
        kindleEmail: 'reader@kindle.com',
        localFolderUri: '',
      );

      final connected = settings.withLocalFolder(
        uri: ' content://example/tree/primary%3ABooks ',
        name: ' Books ',
      );
      expect(
        connected.localFolderUri,
        'content://example/tree/primary%3ABooks',
      );
      expect(connected.localFolderName, 'Books');
      expect(connected.kindleEmail, 'reader@kindle.com');
      expect(connected.hasLocalFolder, isTrue);

      final reset = connected.withLocalFolder(uri: '', name: 'Books');
      expect(reset.localFolderUri, '');
      expect(reset.localFolderName, '');
      expect(reset.hasLocalFolder, isFalse);
    });
  });

  group('theme settings', () {
    test('follows the system theme by default', () {
      expect(
        const AppSettings(catalogUrl: null).themeMode,
        AppThemeMode.system,
      );
    });

    test('round-trips the selected theme', () {
      expect(
        _roundTrip(
          const AppSettings(catalogUrl: null, themeMode: AppThemeMode.dark),
        ).themeMode,
        AppThemeMode.dark,
      );
      expect(
        _roundTrip(
          const AppSettings(catalogUrl: null, themeMode: AppThemeMode.light),
        ).themeMode,
        AppThemeMode.light,
      );
      expect(
        _roundTrip(
          const AppSettings(catalogUrl: null, themeMode: AppThemeMode.system),
        ).themeMode,
        AppThemeMode.system,
      );
    });
  });

  group('language settings', () {
    test('defaults to the system language', () {
      expect(const AppSettings(catalogUrl: null).language, AppLanguage.system);
    });

    test('round-trips the selected language', () {
      expect(
        _roundTrip(
          const AppSettings(catalogUrl: null, language: AppLanguage.ukrainian),
        ).language,
        AppLanguage.ukrainian,
      );
      expect(
        _roundTrip(
          const AppSettings(catalogUrl: null, language: AppLanguage.english),
        ).language,
        AppLanguage.english,
      );
    });

    test('maps language settings to locales', () {
      expect(localeFor(AppLanguage.system), isNull);
      expect(localeFor(AppLanguage.english), const Locale('en'));
      expect(localeFor(AppLanguage.ukrainian), const Locale('uk'));
    });

    test('loads translations for non-widget code', () async {
      await L10n.use(const Locale('uk'));
      expect(l10n.serverStopped, 'Сервер зупинено');

      await L10n.use(const Locale('en'));
      expect(l10n.serverStopped, 'Server is stopped');
    });
  });

  group('settings entity', () {
    test('flattens the catalog URL and enums for storage', () {
      final entity = SettingsEntity.fromSettings(
        const AppSettings(
          catalogUrl: null,
          language: AppLanguage.ukrainian,
          themeMode: AppThemeMode.dark,
        ),
      );
      expect(entity.catalogUrl, '');
      expect(entity.language, 'uk');
      expect(entity.themeMode, 'dark');
    });

    test('reads back an empty catalog URL as not configured', () {
      final entity = SettingsEntity(catalogUrl: '  ');
      expect(entity.toSettings().catalogUrl, isNull);
      expect(entity.toSettings().isConfigured, isFalse);
    });

    test('clamps invalid ports to the defaults', () {
      final entity = SettingsEntity(port: 80, smtpPort: 0);
      expect(entity.toSettings().port, AppSettings.defaultPort);
      expect(entity.toSettings().smtpPort, AppSettings.defaultSmtpPort);
    });
  });
}
