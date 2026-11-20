import '../books/ebook_formats.dart';
import '../entity/favorite.dart';
import '../l10n/l10n.dart';
import '../local/local_files.dart';
import '../opds/opds_feed.dart';
import 'mail_jobs.dart';
import 'url_codec.dart';

String escapeHtml(Object? value) {
  return (value ?? '')
      .toString()
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String formatTypeLabel(String? type) => EbookFormat.labelForMime(type);

String renderCatalogPage(
  OpdsFeed feed, {
  Uri? previousPage,
  bool kindleMailReady = false,
  bool showCovers = false,
  String? searchTemplate,
  String? searchQuery,
}) {
  final template = searchTemplate ?? feed.searchTemplate;
  final body = StringBuffer()
    ..write('<h1>${escapeHtml(feed.title)}</h1>')
    ..write(
      '<p class="meta">${l10n.entriesCount(feed.entries.length)} | '
      '<a href="${escapeHtml(browseHref(feed.url))}">${l10n.refresh}</a></p>',
    );

  if (searchQuery != null && searchQuery.isNotEmpty) {
    body.write(
      '<p class="meta">${l10n.searchResults} <b>${escapeHtml(searchQuery)}</b> | '
      '<a href="/">${l10n.reset}</a></p>',
    );
  }

  if (template != null) {
    body.write(_searchForm(template, searchQuery ?? ''));
  }

  final pager = _pager(feed, previousPage: previousPage);
  if (pager.isNotEmpty) body.write(pager);

  if (feed.entries.isEmpty) {
    body.write('<p>${l10n.catalogEmpty}</p>');
  } else {
    body.write('<ul class="books">');
    for (final entry in feed.entries) {
      body.write(
        _renderEntry(
          entry,
          kindleMailReady: kindleMailReady,
          showCovers: showCovers,
        ),
      );
    }
    body.write('</ul>');
  }

  if (pager.isNotEmpty) body.write(pager);

  body.write(
    '<hr><p class="meta">${l10n.source} '
    '${escapeHtml(feed.url.toString())}</p>',
  );

  return _page(title: feed.title, body: body.toString());
}

/// Pagination shown both above and below the book list.
///
/// Both directions are always shown so the reader can see that paging exists
/// and where it ends. The unavailable one is a disabled button instead of a
/// missing link, and it keeps black text so it stays readable on e-ink.
/// [previousPage] is klos's own history and is used when the OPDS server
/// links only forward.
String _pager(OpdsFeed feed, {Uri? previousPage}) {
  final previousUrl = previousPage ?? feed.previousPage;
  if (previousUrl == null && feed.nextPage == null) return '';

  final previous = previousUrl == null
      ? '<span class="button disabled">${l10n.previousPage}</span>'
      : '<a class="button" href="${escapeHtml(browseHref(previousUrl))}">'
            '${l10n.previousPage}</a>';
  final next = feed.nextPage == null
      ? '<span class="button disabled">${l10n.nextPage}</span>'
      : '<a class="button" href="${escapeHtml(browseHref(feed.nextPage!))}">'
            '${l10n.nextPage}</a>';
  return '<div class="pager">$previous $next</div>';
}

/// Page for the folder that was chosen in the app settings.
///
/// Subfolders are navigation entries, books get the same delivery buttons as
/// the OPDS catalog: a direct download for formats the Kindle opens, email and
/// conversion for EPUB (and for ZIP archives that may contain either).
String renderLocalPage({
  required String title,
  required String folderUri,
  required List<LocalEntry> entries,
  LocalParent? parent,
  bool kindleMailReady = false,
}) {
  final body = StringBuffer()..write('<h1>${escapeHtml(title)}</h1>');

  final links = <String>[
    '<a href="${escapeHtml(localDirHref(folderUri))}">${l10n.refresh}</a>',
  ];
  if (parent != null) {
    links.insert(
      0,
      '<a href="${escapeHtml(localDirHref(parent.uri))}">'
      '${l10n.localFolderUp}</a>',
    );
  } else {
    links.insert(0, '<a href="/local">${l10n.localFolderRoot}</a>');
  }
  body.write(
    '<p class="meta">${l10n.entriesCount(entries.length)} | '
    '${links.join(' | ')}</p>',
  );

  if (entries.isEmpty) {
    body.write('<p>${l10n.localFolderEmpty}</p>');
  } else {
    body.write('<ul class="books">');
    for (final entry in entries) {
      body.write(
        entry.isDirectory
            ? '<li><a href="${escapeHtml(localDirHref(entry.uri))}">'
                  '<b>${escapeHtml(entry.name)}</b></a>'
                  '<br><span class="meta">${l10n.localFolderLabel}</span></li>'
            : _renderLocalFile(entry, kindleMailReady: kindleMailReady),
      );
    }
    body.write('</ul>');
  }

  return _page(title: title, body: body.toString());
}

/// Page with the books saved from the catalog in the app.
///
/// The links are the original acquisition URLs, so the usual download and mail
/// buttons work exactly as on the catalog page.
String renderFavoritesPage({
  required List<Favorite> favorites,
  bool kindleMailReady = false,
  bool showCovers = false,
}) {
  final body = StringBuffer()
    ..write('<h1>${l10n.favorites}</h1>')
    ..write(
      '<p class="meta">${l10n.entriesCount(favorites.length)} | '
      '<a href="/favorites">${l10n.refresh}</a></p>',
    );

  if (favorites.isEmpty) {
    body.write('<p>${l10n.favoritesEmptyOnKindleShort}</p>');
  } else {
    body.write('<ul class="books">');
    for (final favorite in favorites) {
      body.write(
        _renderEntry(
          favorite.toEntry(),
          kindleMailReady: kindleMailReady,
          showCovers: showCovers,
        ),
      );
    }
    body.write('</ul>');
  }

  return _page(title: l10n.favorites, body: body.toString());
}

String _renderLocalFile(LocalEntry entry, {required bool kindleMailReady}) {
  final out = StringBuffer('<li><b>${escapeHtml(entry.name)}</b>');
  final size = formatFileSize(entry.size);
  if (size.isNotEmpty) {
    out.write('<br><span class="meta">${escapeHtml(size)}</span>');
  }

  final mime = entry.effectiveMime;
  final label = formatTypeLabel(mime);
  final key = EbookFormat.keyForMime(mime);
  final recognized = EbookFormat.match(mime) != null;
  final direct = EbookFormat.downloadsDirectly(mime);
  final convertible = EbookFormat.convertible(mime);
  final isZip = key == EbookFormat.zip.key;
  final isMobi = key == EbookFormat.mobi.key;
  final uri = Uri.parse(entry.uri);
  final title = entry.title;

  String? primary;
  final actions = <String>[];
  void add(String button, {bool primaryAction = false}) {
    if (primaryAction) {
      primary = button;
    } else {
      actions.add(button);
    }
  }

  // A Kindle opens MOBI/AZW3/AZW/PDF/TXT directly, and an unknown format is
  // offered as a plain file. EPUB and FB2 are converted into MOBI while
  // downloading, and archives are searched for a usable file. The mail button
  // is offered only for formats Amazon accepts by email.
  if (isZip || direct || !recognized || convertible) {
    add(
      _action(
        localDownloadHref(uri, title: title, type: mime),
        l10n.downloadAction(label),
        primary: isMobi,
        busyLabel: l10n.downloadInProgress,
      ),
      primaryAction: isMobi,
    );
  }
  if (!direct && kindleMailReady && EbookFormat.emailable(mime)) {
    add(
      _action(
        localMailHref(uri, title: title, type: mime),
        l10n.emailAction(label),
        busyLabel: l10n.mailInProgress,
      ),
    );
  }

  final buttons = [?primary, ...actions];
  if (buttons.isEmpty) {
    if (!direct) {
      out.write(
        '<br><span class="meta">${l10n.localFormatNeedsDelivery(label)}</span>',
      );
    }
  } else {
    out.write('<div class="actions">${buttons.join(' ')}</div>');
  }
  out.write('</li>');
  return out.toString();
}

/// Explains that no folder permission is available yet.
String renderLocalUnavailablePage({String? message}) {
  return _page(
    title: l10n.localFiles,
    body:
        '''
<h1>${l10n.localFiles}</h1>
<p>${escapeHtml(message ?? l10n.localFolderNotConnected)}</p>
<p class="meta">${l10n.localFolderConnectHint}</p>
<p><a href="/">${l10n.homeLink}</a></p>
''',
  );
}

String renderMailPage(MailJob job, {String? kindleEmail}) {
  final body = StringBuffer()
    ..write('<h1>${l10n.kindleMail}</h1>')
    ..write('<p><b>${escapeHtml(job.displayTitle)}</b></p>')
    ..write('<p>${escapeHtml(job.stageLabel)}</p>');

  switch (job.stage) {
    case MailJobStage.queued:
    case MailJobStage.downloading:
      body.write('<p class="meta">${l10n.mailDownloadingHint}</p>');
      break;
    case MailJobStage.sending:
      body.write('<p class="meta">${l10n.mailSendingHint}</p>');
      break;
    case MailJobStage.done:
      final address = (kindleEmail ?? '').trim();
      body.write(
        '<p>${address.isEmpty ? l10n.mailAccepted : l10n.mailAcceptedTo(escapeHtml(address))}</p>',
      );
      body.write('<p class="meta">${l10n.mailAmazonHint}</p>');
      break;
    case MailJobStage.failed:
      body.write(
        '<p class="error">${escapeHtml(job.error ?? l10n.unknownError)}</p>',
      );
      final retry =
          job.retryHref ??
          (job.url == null
              ? null
              : mailHref(job.url!, title: job.title, type: job.mime));
      if (retry != null) {
        body.write('<p><a href="${escapeHtml(retry)}">${l10n.retry}</a></p>');
      }
      break;
  }

  if (job.isActive) {
    final statusHref = '/mail/${Uri.encodeComponent(job.id)}';
    body
      ..write(
        '<p><a href="${escapeHtml(statusHref)}">${l10n.refreshStatus}</a></p>',
      )
      ..write('<p class="meta">${l10n.autoRefresh}</p>');
  }

  body.write('<p><a href="/">${l10n.home}</a></p>');

  return _page(
    title: l10n.kindleMail,
    body: body.toString(),
    extraHead: job.isActive
        ? '<meta http-equiv="refresh" content="4;url='
              '${escapeHtml('/mail/${job.id}')}">'
        : '',
  );
}

String renderErrorPage(String message, {Uri? retryUrl, String? retryHref}) {
  final body = StringBuffer()
    ..write('<h1>${l10n.errorTitle}</h1>')
    ..write('<p>${escapeHtml(message)}</p>');

  final href = retryHref ?? (retryUrl == null ? null : browseHref(retryUrl));
  if (href != null) {
    body.write('<p><a href="${escapeHtml(href)}">${l10n.retry}</a></p>');
  }
  body.write('<p><a href="/">${l10n.home}</a></p>');

  return _page(title: l10n.errorTitle, body: body.toString());
}

String renderSharePage({required String title, String? kindleEmail}) {
  final address = (kindleEmail ?? '').trim();
  final message = address.isEmpty
      ? l10n.sharePrepared
      : l10n.sharePreparedTo(escapeHtml(address));
  return _page(
    title: l10n.sendByEmailTitle,
    body:
        '''
<h1>${l10n.fileReady}</h1>
<p><b>${escapeHtml(title)}</b></p>
<p>$message</p>
<p class="meta">${l10n.shareHint}</p>
<p><a href="/">${l10n.home}</a></p>
''',
  );
}

String renderNotConfiguredPage() {
  return _page(
    title: 'klos',
    body:
        '''
<h1>klos</h1>
<p>${l10n.notConfiguredBody}</p>
<p>${l10n.notConfiguredHelp}</p>
<p><a href="/help">${l10n.help}</a></p>
''',
  );
}

String renderPinPage({String? error, String? next}) {
  final message = error == null
      ? ''
      : '<p class="error">${escapeHtml(error)}</p>';
  final target = (next ?? '').trim();
  final nextField = target.isEmpty
      ? ''
      : '<input type="hidden" name="next" value="${escapeHtml(target)}">';
  return _page(
    title: l10n.pinPageTitle,
    body:
        '''
<h1>${l10n.pinPageTitle}</h1>
<p>${l10n.pinPageIntro}</p>
$message
<form action="/unlock" method="post">
<p><input type="text" name="pin" size="4" maxlength="4" autocomplete="off"></p>
$nextField
<p><input type="submit" value="${l10n.pinSubmit}"></p>
</form>
<p class="meta">${l10n.pinPageHint}</p>
''',
  );
}

String renderHelpPage({String? serverAddress}) {
  final address = serverAddress ?? l10n.helpAddressPlaceholder;
  return _page(
    title: l10n.help,
    body:
        '''
<h1>${l10n.webHelpHeading}</h1>
<ol>
<li>${l10n.webHelpStep1}</li>
<li>${l10n.webHelpStep2}</li>
<li>${l10n.webHelpStep3(escapeHtml(address))}</li>
<li>${l10n.webHelpStep4}</li>
<li>${l10n.webHelpStep5}</li>
</ol>
<p class="meta">${l10n.webHelpFormats}</p>
<p class="meta">${l10n.webHelpSearch}</p>
<p class="meta">${l10n.webHelpLimits}</p>
<p class="meta">${l10n.webHelpActions}</p>
<p class="meta">${l10n.webHelpFavorites}</p>
<p class="meta">${l10n.webHelpPrivacy}</p>
<p><a href="/">${l10n.home}</a></p>
''',
  );
}

String renderNotFoundPage() {
  return _page(
    title: l10n.notFoundTitle,
    body:
        '''
<h1>${l10n.notFoundHeading}</h1>
<p>${l10n.notFoundHint}</p>
<p><a href="/">${l10n.home}</a></p>
''',
  );
}

/// Trims a description to the short teaser shown in the catalog list.
String _summarySnippet(String text) {
  if (text.length <= 240) return text;
  return '${text.substring(0, 237).trimRight()}...';
}

String _renderEntry(
  OpdsEntry entry, {
  required bool kindleMailReady,
  required bool showCovers,
}) {
  final out = StringBuffer('<li>');
  final navigation = entry.navigationLinks;
  final acquisitions = entry.downloadLinks;

  final cover = showCovers ? entry.coverLink : null;
  if (cover != null) {
    out.write(
      '<img src="${escapeHtml(imageHref(cover.href, type: cover.type))}" '
      'width="72" height="108" align="left" hspace="8" vspace="3" '
      'border="0" alt="">',
    );
  }

  if (navigation.isNotEmpty) {
    out.write(
      '<a href="${escapeHtml(browseHref(navigation.first.href))}">'
      '<b>${escapeHtml(entry.title)}</b></a>',
    );
  } else {
    out.write('<b>${escapeHtml(entry.title)}</b>');
  }

  if (entry.author != null && entry.author!.isNotEmpty) {
    out.write('<br><span class="meta">${escapeHtml(entry.author)}</span>');
  }

  if (acquisitions.isNotEmpty) {
    final seen = <String>{};
    final actions = <String>[];
    // MOBI is the format a Kindle opens best, so it becomes the primary
    // button and goes before the alternatives. The other formats stay
    // available as secondary buttons, and are the only options when there
    // is no MOBI link at all.
    String? primary;
    for (final link in acquisitions) {
      final label = formatTypeLabel(link.type);
      if (!seen.add(label)) continue;
      final key = EbookFormat.keyForMime(link.type);
      final directDownload = EbookFormat.downloadsDirectly(link.type);
      final convertible = EbookFormat.convertible(link.type);
      final isZip = key == EbookFormat.zip.key;
      final isMobi = key == EbookFormat.mobi.key;
      final rendered = <String>[];

      // A ZIP may contain a file the Kindle opens, and EPUB/FB2 are converted
      // into MOBI while downloading, so those get a plain download button.
      // Formats like MOBI, AZW3, PDF and TXT fall through to the download
      // below, and the mail alternative is offered only for formats Amazon
      // accepts by email (EPUB, PDF, TXT, RTF, DOC/DOCX, HTML).
      if (isZip || convertible) {
        rendered.add(
          _action(
            downloadHref(link.href, title: entry.title, type: link.type),
            l10n.downloadAction(label),
            busyLabel: l10n.downloadInProgress,
          ),
        );
      }
      if (!directDownload &&
          kindleMailReady &&
          EbookFormat.emailable(link.type)) {
        rendered.add(
          _action(
            mailHref(link.href, title: entry.title, type: link.type),
            l10n.emailAction(label),
            busyLabel: l10n.mailInProgress,
          ),
        );
      }
      if (rendered.isEmpty) {
        final download = _action(
          downloadHref(link.href, title: entry.title, type: link.type),
          l10n.downloadAction(label),
          primary: isMobi,
          busyLabel: l10n.downloadInProgress,
        );
        if (isMobi) {
          primary = download;
        } else {
          actions.add(download);
        }
      } else {
        actions.addAll(rendered);
      }
    }
    final buttons = [?primary, ...actions];
    if (buttons.isNotEmpty) {
      out.write('<div class="actions">${buttons.join(' ')}</div>');
    }
  }

  if (entry.summary != null && entry.summary!.isNotEmpty) {
    out.write(
      '<br><span class="meta">${escapeHtml(_summarySnippet(entry.summary!))}</span>',
    );
  }

  if (cover != null) out.write('<br clear="all">');
  out.write('</li>');
  return out.toString();
}

String _searchForm(String template, String query) {
  return '<form action="/search" method="get">'
      '<input type="hidden" name="u" value="${escapeHtml(template)}">'
      '<input type="text" name="q" size="18" value="${escapeHtml(query)}"> '
      '<input type="submit" value="${l10n.searchButton}">'
      '</form>';
}

String _action(
  String href,
  String label, {
  bool primary = false,
  String? busyLabel,
}) {
  final classes = primary ? 'button primary' : 'button';
  final busy = busyLabel == null
      ? ''
      : ' data-klos-busy-label="${escapeHtml(busyLabel)}"'
            ' data-klos-busy-hint="${escapeHtml(l10n.actionWaitHint)}"'
            ' onclick="return klosBusy(this)"';
  return '<a class="$classes" href="${escapeHtml(href)}"$busy>'
      '${escapeHtml(label)}</a>';
}

String _page({
  required String title,
  required String body,
  String extraHead = '',
}) {
  return '''<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0D8BD0">
$extraHead
<link rel="icon" type="image/svg+xml" href="/icon.svg">
<title>${escapeHtml(title)}</title>
<style type="text/css">
body { font-family: Georgia, serif; margin: 0.7em; line-height: 1.45; color: #000; background: #fff; }
h1 { font-size: 1.45em; margin: 0 0 0.4em 0; }
p { margin: 0.5em 0; }
ul, ol { margin: 0.4em 0; padding-left: 1.2em; }
ul.books { list-style: none; margin: 0.3em 0; padding: 0; }
ul.books li { margin: 0; padding: 1.1em 0; border-bottom: 1px solid #000; }
ul.books li:last-child { border-bottom: 0; }
ol li { margin: 0.7em 0; }
a { color: #000; }
.meta { font-size: 0.95em; color: #000; word-wrap: break-word; }
.error { color: #000; font-weight: bold; border: 2px solid #000; padding: 0.6em; }
.nav { border-bottom: 1px solid #000; padding-bottom: 0.45em; margin-bottom: 0.9em; font-size: 1em; }
form { margin: 0.6em 0; }
input { font-size: 1em; }
input[type="text"] { padding: 0.2em 0.3em; border: 1px solid #000; }
input[type="submit"] { padding: 0.45em 1em; border: 2px solid #000; background: #fff; color: #000; font-weight: bold; }
hr { border: 0; border-top: 1px solid #000; margin: 1.1em 0; }
.actions { margin: 0.55em 0 0.15em 0; }
.button {
  display: inline-block;
  margin: 0 0.65em 0.55em 0;
  padding: 0.5em 0.85em;
  border: 1px solid #000;
  background: #fff;
  color: #000;
  font-size: 0.95em;
  font-weight: bold;
  text-decoration: none;
  line-height: 1.2;
  max-width: 100%;
  box-sizing: border-box;
  word-wrap: break-word;
}
.button.primary {
  margin-right: 0.75em;
  padding: 0.6em 1.1em;
  border: 3px solid #000;
  background: #000;
  color: #fff;
  font-size: 1.05em;
}
.pager { margin: 0.7em 0 0.9em 0; }
.pager .button {
  min-width: 6em;
  padding: 0.75em 1.2em;
  border-width: 2px;
  font-size: 1.05em;
  text-align: center;
}
.button.disabled {
  border-style: dashed;
  border-width: 2px;
  font-weight: normal;
  background: #fff;
  color: #000;
}
</style>
<script type="text/javascript">
function klosBusy(link) {
  if (link.getAttribute('data-klos-busy')) { return false; }
  link.setAttribute('data-klos-busy', '1');
  link.className = 'button disabled';
  link.innerHTML = link.getAttribute('data-klos-busy-label');
  var hint = link.getAttribute('data-klos-busy-hint');
  if (hint && link.parentNode) {
    var note = document.createElement('p');
    note.className = 'meta';
    note.appendChild(document.createTextNode(hint));
    link.parentNode.appendChild(note);
  }
  var href = link.getAttribute('href');
  if (!href) { return false; }
  setTimeout(function () { window.location.href = href; }, 400);
  return false;
}
</script>
</head>
<body>
<div class="nav"><a href="/">${l10n.homeLink}</a> | <a href="/favorites">${l10n.favorites}</a> | <a href="/local">${l10n.localFiles}</a> | <a href="/help">${l10n.help}</a></div>
$body
</body>
</html>
''';
}
