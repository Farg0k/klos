# klos

A local OPDS bridge for Kindle.

The app turns an Android phone into a small HTTP server: it reads a remote
OPDS catalog and serves it to the Kindle **Experimental Browser** as simple
HTML pages. Books are usually not stored on the phone — they are proxied from
the original OPDS server straight to the Kindle; if you want, klos can save a
book into a folder on the phone that the Kindle can see.

```
Kindle (Experimental Browser)  ──HTTP──▶  phone (klos)  ──HTTP──▶  OPDS server
```

## Features

- one OPDS catalog address (Atom/XML or JSON) with optional HTTP Basic login;
- OPDS 1.x (Atom) and OPDS 2.0 (JSON) — the format is detected automatically;
- English and Ukrainian interface — the system language or one chosen in
  **Settings → Language** (Auto / English / Ukrainian);
- auto / light / dark theme — **Settings → Theme**; Auto follows the phone's
  light or dark mode;
- the brand blue `#0D8BD0` in buttons, switches, the app icon, the splash
  screen, the favicon and the app bar in both themes;
- the same 8 px corner radius for buttons, cards, fields and dialogs;
- plain HTML without JavaScript — compatible with old Kindle browsers,
  high contrast, no grey text;
- nested catalogs and OPDS pagination (`next`/`previous`) with large buttons
  at the top and bottom of the page; when the server does not provide a
  `previous` link, klos remembers the navigation history and still shows a
  working **Back** button;
- catalog search when the OPDS server supports it (OpenSearch);
- links to EPUB, MOBI, AZW/AZW3, PDF, CBZ, FB2, TXT, ZIP;
- formats shown as buttons with clear borders: MOBI, which the Kindle opens
  best, is highlighted as the primary button, other formats sit next to it as
  secondary ones;
- automatic ZIP unpacking: for the Kindle klos takes MOBI/AZW3/AZW/PDF/TXT,
  for email — EPUB/PDF/TXT/RTF/DOC/DOCX/HTML, for conversion — EPUB or FB2;
  if the archive contains only EPUB or FB2, klos always converts it to MOBI
  during a normal download, so the **download** button never leads to a dead
  end;
- sending books to the Kindle by email (Amazon Send to Kindle) for formats
  Amazon accepts by email (EPUB, PDF, TXT, RTF, DOC/DOCX, HTML) — the
  **send to Kindle** button appears as soon as a Kindle address is set;
- if SMTP is configured, klos sends the email itself; if not, it opens the
  phone's mail app with the attachment and the Kindle address already filled
  in;
- EPUB/FB2 → MOBI conversion on the phone is enabled automatically: the
  **download** button next to EPUB or FB2 serves the Kindle a ready MOBI,
  there is no separate switch;
- book covers in the catalog, with an option to hide them on the home screen;
- **catalog browsing in the app**: **Library** on the home screen opens the
  OPDS catalog without the server or a Kindle — subcatalogs, pagination,
  search and covers work the same way, and a book can be saved to
  **favorites** with one button;
- **favorites on the Kindle**: saved books appear both in the app and on the
  `/favorites` page of the local server — with the same **download** and
  **send to Kindle** buttons as the catalog; PIN protection also applies to
  that page;
- **downloading into the folder from the app**: on a book card (catalog or
  favorites) the **Download to folder** button saves the file into the same
  local folder the Kindle sees — with ZIP unpacking and EPUB/FB2 → MOBI
  conversion, exactly like the server serves a book to the Kindle browser;
  if a book belongs to a series, the series opens with a separate button
  instead of replacing the book card;
- **local folder on the phone**: choose a folder through the Android system
  picker (the picker opens in Downloads) and read its books on the Kindle just
  like an OPDS catalog, including subfolders; access is limited to the chosen
  folder;
- file name with the correct extension and `Content-Disposition` (and also in
  the link path, in case the Kindle ignores the header); Cyrillic titles are
  transliterated to Latin because the Kindle browser handles them poorly;
- foreground service: the server responds in the background and a
  notification shows that it is active;
- optional wake lock (**Keep the screen on**, Settings screen): keeps the
  screen on while the server runs and is released as soon as the server stops;
- server auto-stop after a set time without requests (Off / 5 / 10 / 30 /
  60 min), so a forgotten server does not stay on the network;
- server auto-start when the app opens;
- optional PIN protection: the Kindle enters a four-digit code from the app
  once, the code is regenerated on every server start, and repeated failed
  attempts are temporarily blocked;
- request and download log in the app;
- **About** item in the settings: version and build number together with the
  licenses of all libraries the app is built from;
- raw OPDS XML/JSON at `/opds?u=...` for other readers;
- settings are stored locally on the device.

## How to use

1. Install the app on the phone:

   ```powershell
   flutter pub get
   flutter run
   # or
   flutter build apk --release
   # APK: build/app/outputs/flutter-apk/app-release.apk
   ```

   **Android 8.0 (API 26)** or newer is required.

2. On the home screen, in the **Server settings** block, choose the source of
   books: an **OPDS catalog**, a local folder, or both. For a catalog, open
   **OPDS catalog** and enter the address, for example:

   - Calibre Content Server: `http://192.168.1.20:8080/opds`
   - COPS: `http://192.168.1.20:8081/opds`
   - calibre-web: `http://192.168.1.20:8083/opds`

   If the server requires a login, enter it in the **Login** and **Password**
   fields. Settings are saved **automatically**: switches and formats
   immediately, text fields when you move to the next field or close the
   panel. The **Check** button in that panel downloads the catalog and shows
   its name and entry count. The server does not restart until the port is
   changed.

   Optional: in **Local files** on the home screen, connect a folder on the
   phone to read its books on the Kindle even without an OPDS catalog. If no
   catalog address is set, the server opens that folder right on the main
   page. See [Local files on the phone](#local-files-on-the-phone) for
   details.

3. Tap **Start server**. The app shows an address like
   `http://192.168.1.42:8080/`.

4. Connect the Kindle and the phone to the same Wi-Fi network. On the Kindle
   open **Menu → Experimental Browser** and enter the address from the app.

5. Choose a book and a format. Next to formats Amazon accepts by email
   (**EPUB**, **PDF**, **TXT**, **RTF**, **DOC/DOCX**, **HTML**) there is a
   **send to Kindle** button (when a Kindle address is set) — the book goes to
   the Kindle address automatically via SMTP or through the phone's mail app.
   The **download** button next to EPUB or FB2 converts the book to MOBI on
   the phone; other formats download as they are. The server does not transfer
   files larger than 120 MB.

> **MOBI** and **AZW3** work most reliably on older Kindles. If EPUB or PDF
> does not open, try another format the catalog offers.

Book covers are shown by default (if the OPDS catalog provides them). You can
turn them off on the home screen under **Local server → Catalog view → Show
covers** — pages will open faster and without images.

Long explanations about the send-to-Kindle/download buttons and favorites do
not take up space on catalog pages: they are collected on the **Help** page
(a tab in the catalog navigation) and in the app help (the **?** button on the
home screen).

### Catalog search

If the OPDS server declares search (`rel="search"`, OpenSearch), a **Search**
field appears on the catalog page. Enter a query — klos substitutes it into
the server template (`{searchTerms}`) and shows the results. The field stays
on the results page, so you can search again or **Reset** the search.

Both variants found in OPDS are supported: a ready template in the feed itself
and a separate OpenSearch description
(`application/opensearchdescription+xml`), which klos downloads once and
remembers. OPDS 2.0 uses URI templates like `{?query}` — they are supported
too.

Search is not available in every catalog: if the server does not declare it,
there is no field.

### Local files on the phone

klos can show the Kindle not only an OPDS catalog but also books from a folder
on the phone.

1. On the home screen open **Local files** and tap **Choose folder**.
2. Android opens the system folder picker right in **Downloads**. Choose a
   subfolder with books and confirm access. If there is no such folder yet,
   tap **⋮ → New folder** right in the picker.
3. The folder is connected **immediately** after confirmation. The app and the
   `/local` page show the name of the **chosen subfolder** (for example,
   `Books`), not "Downloads". No manual save is needed — changes apply
   automatically.

> **Android 11+ does not allow choosing the Downloads root itself.** The "Use
> this folder" button is disabled for it — this is a system privacy
> restriction, not klos. Create a subfolder in Downloads
> (**⋮ → New folder**), for example `Download/Books`, put the books there and
> choose that subfolder. On Android 10 and older the Downloads root is chosen
> like any other folder. If the name "Downloads" was saved earlier, klos
> updates it to the real subfolder name on the next launch.

On the Kindle the **Local files** page is available from the catalog
navigation:

- **subfolders** can be opened; the **↑ Up** link returns one level up, and
  **Folder root** goes back to the chosen folder itself;
- only books are shown; images, `Thumbs.db`, hidden files and temporary files
  of office apps are skipped;
- the actions are the same as in OPDS: **download** and (for EPUB and other
  formats Amazon accepts) **send to Kindle**. MOBI, AZW/AZW3, PDF, TXT and
  unknown formats download directly (MOBI as the primary button); EPUB and
  FB2 download as MOBI (conversion happens on the phone); CBZ and ZIP
  download and klos extracts a file suitable for the Kindle. Only what Amazon
  accepts (EPUB, PDF, TXT, RTF, DOC/DOCX, HTML) can be sent by email, so FB2,
  CBZ and ZIP have no **send to Kindle** button.

Important about permissions:

- Android does not let an app read all storage. klos works **only with the
  folder you explicitly confirmed**; the permission persists between launches
  (persistable URI permission).
- On Android 11+ the system forbids choosing the **Downloads root**, the
  internal storage root and SD card roots. That is why **Downloads** is shown
  as a starting point, but you need to connect a subfolder (for example,
  `Download/Books`) or another folder. Without confirmation, the `/local`
  page explains that the folder has not been connected yet.
- The server accepts only documents **inside the chosen folder**: foreign,
  forged or outdated links are rejected.
- If access is lost (the folder was deleted, the permission was reset after a
  restart or clearing app data), choose the folder again on the home screen.
- Files are read into memory with limits: download — 120 MB, mail app —
  100 MB, conversion — 80 MB, Amazon attachment — 25 MB.

### Kindle email (Send to Kindle)

Formats Amazon accepts (**EPUB**, **PDF**, **TXT**, **RTF**, **DOC/DOCX**,
**HTML**) can be sent to the Kindle by email: Amazon converts the book and
adds it to the library. This is a fallback alongside automatic MOBI
conversion.

1. On Amazon open **Manage Your Content and Devices → Preferences → Personal
   Document Settings**:
   - copy the address like `name@kindle.com`;
   - add the address you will send books from to the
     **Approved Personal Document E-mail List**.
2. In the app, open **Kindle email** on the home screen:
   - enter only the **name** before "@" (for example, `notik`) — the
     `@kindle.com` part is shown in the field and added automatically, the
     "@" character cannot be typed; this is enough for the send-to-Kindle
     button to appear. If an address with another domain was saved earlier,
     klos replaces it with `@kindle.com` (regional Amazon domains like
     `@kindle.co.uk` stay);
   - **optional**: fill in the SMTP server, port, login, password and sender
     address so klos sends emails itself;
   - tap **Send test email** to check SMTP.
3. For Gmail use an **app password** (not your regular password):
   `smtp.gmail.com`, port 587 without SSL or 465 with SSL. Two-factor
   authentication is required.
4. Changes are saved automatically. In the catalog on the Kindle, the
   **send to Kindle** button appears next to formats Amazon accepts.

If SMTP is not configured, tapping **send to Kindle** downloads the file to
the phone and opens the mail app: the attachment and the Kindle address are
already filled in, you only need to tap Send. This works only while klos is
open on the phone. While the file is being prepared, the button changes to
**Sending…** so you can see the tap registered.

The **send to Kindle** button is shown only next to formats Amazon accepts by
email — **EPUB, PDF, TXT, RTF, DOC/DOCX, HTML**. For a format Amazon does not
accept (**FB2, CBZ**) or whose contents are unknown in advance (**ZIP**) there
is no send-to-Kindle button, so the email is not rejected. The Kindle reads
**MOBI, AZW, AZW3, PDF** and **TXT** itself, so they keep **download**. Next
to **EPUB** and **FB2** the **download** button is present too: klos converts
them to MOBI during download. For **FB2, CBZ and ZIP** the only path is
**download** (FB2 becomes MOBI, and klos extracts a suitable file from ZIP).

Amazon limits:

- an email (with the attachment) cannot be larger than **25 MB**;
- email accepts **EPUB, PDF, TXT, RTF, DOC/DOCX, HTML** and images;
- Amazon does not convert **FB2 and CBZ** by email, so klos does not offer
  send to Kindle for them — download such books (for FB2 it is a ready MOBI)
  or look for EPUB/MOBI;
- for **ZIP** there is no send-to-Kindle button: the contents are unknown in
  advance and Amazon does not accept archives. Instead, download unpacks the
  archive and serves a file suitable for the Kindle;
- a successful SMTP exchange only means the mail server accepted the message.
  Amazon processes the book separately: it appears in the library in a few
  minutes, and a conversion error arrives in a separate email from Amazon.

The status page (`/mail/<id>`) refreshes automatically every 4 seconds while
the book is downloaded and sent, so the Kindle browser does not wait for a
large file.

### EPUB and FB2 → MOBI conversion

Some Kindles do not open EPUB, and no Kindle supports FB2. That is why the
**download** button next to EPUB and FB2 files **automatically converts** the
book **on the phone** and serves the Kindle a ready MOBI. There is no separate
switch — conversion is always on, and no Kindle address is needed for it.

`.fb2.zip` and ZIPs containing only EPUB/FB2 work the same way: klos extracts
the needed file from the archive and converts it.

While conversion runs, the button changes to **Downloading…** and no longer
reacts to taps, and a hint to wait appears below it. The server is also
protected against double taps: if the Kindle sends the same request twice, the
book is converted or downloaded only once, and both requests receive the ready
file.

> Conversion is **experimental**: it produces a simple MOBI and complex layout
> is simplified. If a book must look exactly as the publisher intended, use a
> format the Kindle opens directly, or email (Amazon converts better).

The converter is built into the app and works without the internet or
third-party services. It is a minimal **MOBI 6 (KF7)** writer: UTF-8 text,
cover, table of contents and links between chapters.

Conversion limits:

- **EPUB** and **FB2** are supported as input, **MOBI 6** as output, no
  AZW3/KF8;
- books with **DRM** are rejected (font obfuscation is not considered DRM and
  is converted);
- complex formatting is simplified: CSS, fonts and positioning are not
  preserved, basic text, headings, images and links remain;
- very large books convert more slowly (processing runs on a background
  thread, the interface does not freeze).

### Without SMTP: the phone's mail app

If SMTP is not configured, klos can still prepare an email:

1. Enter the **Kindle address** on the home screen in **Kindle email** (leave
   SMTP empty).
2. In the catalog on the Kindle tap **EPUB (send to Kindle)**. klos downloads
   the file to the phone and opens the mail app with the **attachment already
   added** and the **Kindle address filled in** (Android `EXTRA_EMAIL`). You
   only need to review the email and tap Send.

Important:

- the mail app opens **only while the klos app is active** (not in the
  background). So keep klos open when you tap a link on the Kindle;
- the ready file is kept temporarily in the app cache so the mail app can
  attach it; klos removes stale files on the next launch;
- your mail app sends the email — klos has no access to your mail.

The server runs in the background until you stop it: there is a permanent
notification in the Android shade (the app asks for notification permission).
Closing the app (swiping it away from recents) stops the server.

If the Kindle does not open the address, check that the network does not use
client isolation (AP isolation) and that the phone is not running a separate
guest network.

## OPDS support

- **OPDS 1.x** (Atom/XML) — navigation, acquisition, covers, pagination,
  OpenSearch search, HTTP Basic.
- **OPDS 2.0** (`application/opds+json`) — navigation feeds, publications,
  groups, covers from `images`, individual publication documents and search
  via URI templates (`{?query}`).

The format is detected automatically from the response body (XML or JSON), so
the catalog address does not need to be changed.

Not used: facets, the OPDS authentication document (HTTP Basic only), indirect
acquisition.

## How it works

| File | Purpose |
| --- | --- |
| `lib/main.dart` | app startup, BLoC providers, theme, lifecycle |
| `lib/utils/locator.dart` | `get_it` locator: ObjectBox and services |
| `lib/features/home_screen/` | home screen: `bloc/` (server state) and `components/` (cards, server settings menus) |
| `lib/features/server_settings/` | server settings panels: catalog, files, server, Kindle email |
| `lib/features/catalog_screen/` | OPDS catalog browsing in the app: `bloc/` (feed pages and search) and the book list screen |
| `lib/features/favorites_screen/` | favorites: `bloc/` (shared state) and the screen with saved books and covers |
| `lib/features/settings_screen/` | app settings: language, theme, wake lock and **About** |
| `lib/features/about/` | **About**: version, build and library licenses |
| `lib/components/` | shared cards, hints and panels for screens |
| `lib/entity/app_settings.dart` | immutable settings model (`Equatable`) |
| `lib/entity/settings_entity.dart` | ObjectBox entity and conversion to `AppSettings` |
| `lib/entity/favorite.dart` | saved catalog book: key, title, link |
| `lib/entity/favorite_entity.dart` | ObjectBox favorites entity; links are stored as JSON |
| `lib/services/objectbox_service.dart` | opening the database and the single settings row |
| `lib/services/server_service.dart` | HTTP server, foreground service, IP addresses, log |
| `lib/platform/screen_wakelock.dart` | optional wake lock that keeps the screen on |
| `lib/platform/app_info.dart` | app version and build number (`package_info_plus`) |
| `lib/local/local_files.dart` | local folder model, formats and book filter |
| `lib/local/local_storage.dart` | SAF folder access, reading and writing, `content://` link checks |
| `lib/local/folder_download.dart` | downloading a catalog book into the local folder |
| `lib/books/ebook_formats.dart` | book formats and Amazon Send to Kindle support |
| `lib/books/ebook_archive.dart` | choosing and unpacking a book from a ZIP archive |
| `lib/books/kindle_file.dart` | shared download, unpacking and conversion for the server and the app |
| `lib/l10n/intl_en.arb` | English interface strings (base locale) |
| `lib/l10n/intl_uk.arb` | Ukrainian interface strings |
| `lib/l10n/l10n.dart` | locale selection and strings for code outside widgets |
| `lib/generated/` | generated Flutter Intl localization classes (`S`) |
| `lib/mail/kindle_mailer.dart` | temporary file download and SMTP sending |
| `lib/server/mail_jobs.dart` | background sending queue and statuses |
| `lib/convert/mobi_writer.dart` | MOBI 6 (KF7) writer for EPUB |
| `lib/convert/epub.dart` | EPUB parsing and MOBI assembly |
| `lib/convert/epub_converter.dart` | EPUB conversion (on a background thread) |
| `lib/convert/book_converter.dart` | choosing the converter by format (EPUB or FB2) |
| `lib/convert/fb2.dart` | FB2 parsing → HTML for MOBI |
| `lib/convert/mobi_book.dart` | MOBI 6 writer with PalmDOC compression for FB2 |
| `lib/convert/fb2_to_mobi.dart` | FB2 conversion entry point |
| `lib/share/share_service.dart` | phone mail app and file cache |
| `lib/opds/opds_feed.dart` | Atom/OPDS parser, absolute links |
| `lib/opds/opds2_feed.dart` | OPDS 2.0 (JSON) parser |
| `lib/opds/opds_client.dart` | catalog and file downloads, Basic auth |
| `lib/opds/opensearch.dart` | OpenSearch templates |
| `lib/server/proxy_server.dart` | local `HttpServer` and routes |
| `lib/server/server_auth.dart` | PIN code, sessions and failed-attempt throttling |
| `lib/server/html_pages.dart` | HTML for the Kindle |
| `lib/server/favicon.dart` | SVG icon for the browser |
| `lib/theme/app_theme.dart` | brand colour, light and dark themes |
| `lib/server/file_names.dart` | safe file names, transliteration, MIME → extension |
| `lib/server/url_codec.dart` | URL-safe tokens for links |
| `android/.../MainActivity.kt` | SAF channel `klos/files` (folder picking, reading and writing) and the mail app |
| `android/.../ServerService.kt` | foreground service with a notification |

Settings are split by purpose: **everything related to the server** (catalog,
local files, port, auto-stop, delivery methods, Kindle email) is edited on the
home screen — each item opens its own `ModalBottomSheet`, so the home screen
stays short. The **Settings screen** contains app parameters: interface
language, theme, wake lock (**Keep the screen on**) and the **About** item —
version and build number from the installed package (`package_info_plus`) plus
a custom licenses panel with the list of libraries and full texts from
`LicenseRegistry`. Both places save changes automatically, without a Save
button.

The splash screen is branded without third-party packages: Android 12+ uses
the system SplashScreen API through `res/values-v31/styles.xml`
(`windowSplashScreenBackground` and `windowSplashScreenAnimatedIcon`), while
Android 11 and older use `res/drawable/launch_background.xml`. The background
is the brand blue `#0D8BD0` (`splash_background`), the logo is a white reader
on that background (`drawable/ic_splash_logo.xml`). The adaptive icon
(`ic_launcher_background.xml`), the favicon and the notification accent use the
same colour.

Local server routes:

| Route | What it does |
| --- | --- |
| `/` | the root OPDS catalog as HTML; without a catalog — the chosen local folder |
| `/browse?u=...` | a nested catalog (the token contains the URL) |
| `/search?u=...&q=...` | catalog search (OpenSearch, if supported) |
| `/download/<name>?u=...&n=...&t=...` | proxying a book file (EPUB/FB2 are converted to MOBI) |
| `/send/<name>?u=...&n=...&t=...` | sending a book to the Kindle: SMTP or the mail app |
| `/image?u=...&t=...` | proxying a book cover |
| `/mail/<id>` | sending status page (with auto-refresh) |
| `/local` | books from the chosen local folder |
| `/local?d=...` | a subfolder of the local folder |
| `/local/download/<name>?u=...` | downloading a file from the local folder (EPUB/FB2 → MOBI) |
| `/local/send/<name>?u=...` | sending a local book to the Kindle |
| `/favorites` | books saved to favorites in the app, with download and email buttons |
| `/opds?u=...` | raw Atom/XML or JSON of a catalog |
| `/help` | instructions for the Kindle |
| `/unlock` | PIN check and session sign-in (a form without JavaScript) |

## Security and limits

- The local server listens on **all Wi-Fi and network addresses of the phone**
  and never goes out to the mobile network, so the catalog is unreachable from
  outside the local network. It also listens on **loopback** (`127.0.0.1`), so
  the phone itself can see the catalog and port forwarding works on the
  emulator (`adb forward tcp:8080 tcp:8080`). If one address fails to bind,
  the rest keep working.
  By default it has no password: any device on the same Wi-Fi network sees the
  catalog and can use the phone as an HTTP proxy. Enable
  **Home screen → Local server → PIN protection** if the network is not fully
  trusted.
- **PIN protection** (optional): the Kindle enters a four-digit code on the
  sign-in page once, after which it receives a session in the HttpOnly cookie
  `klos_session`. The code is shown in the app (on the home screen and in the
  **Local server** panel) and is **regenerated every time the server starts**,
  so yesterday's PIN does not work. The code is compared in constant time, and
  failed attempts are limited: five errors from one device within five minutes
  return `429` with `Retry-After`, and twenty errors in total trigger an
  automatic PIN change and sign out every device.
- **Auto-stop** (Home screen → Local server → "Stop after inactivity"): if no
  device has contacted the server for the set time, it stops by itself and
  releases the network and the wake lock. Every request resets the countdown;
  the server does not interrupt an active download.
- Responses add the protective headers `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY` and `Referrer-Policy: no-referrer`; pages are not
  cached. Icons are served without sign-in because the sign-in page needs them
  too.
- The OPDS login and password are stored in the local ObjectBox database in
  plain text (on this device only).
- The SMTP password is also stored in ObjectBox without encryption. Use a
  separate app password (Gmail, Ukr.net, etc.) that can be revoked, and do not
  use your main mail password.
- Without a PIN, anyone on the same network can open `/send/...` for formats
  Amazon accepts and send a book to your Kindle. This does not give access to
  your mail, but it uses traffic and can clutter the Kindle.
- The fallback `/send/...` mode without SMTP is likewise available without a
  password. It works only while the app is active and opens the mail app on
  the phone — the extra step is noticeable, but wasting the phone's resources
  on a trusted network is still undesirable.
- The attachment is kept temporarily in the app cache (a `.part` file) only
  for the duration of sending and is deleted immediately after the SMTP
  server responds.
- ZIP archives are protected against zip bombs: the download size (120 MB),
  the number of files in the archive (20 000) and the size of a single
  unpacked file (120 MB) are limited. Decompression is additionally limited
  while reading, even if the archive header understates the real size. EPUB
  and FB2 conversion has separate limits: 32 MB per file, 96 MB for text and
  64 MB per image.
- ZIP contents are never written to disk under names taken from the archive,
  so paths like `../../file` (zip-slip) cannot escape the app cache.
- The local folder is opened only through the SAF permission you confirmed.
  The server accepts `content://` links only within the chosen tree
  (`LocalStorage.isUnder`), so a forged link cannot read other files on the
  phone. Picking a folder does not give the app access to all storage.
- Local traffic goes over plain HTTP. If the OPDS server is available over
  HTTPS, the phone → OPDS server connection is encrypted.
- One OPDS catalog and one local folder are supported. Pages are deliberately
  light so they work fast on e-ink.
- Android may restrict background services. For long sessions keep the app
  open; the foreground service notification shows that the server is active.
  On Xiaomi/Samsung allow klos to run in the background and disable battery
  optimisation. If the phone still stops the server, enable
  **Settings → Keep the screen on**: the wake lock keeps the screen on while
  the server runs (the battery drains faster).
- Self-signed HTTPS certificates of an OPDS server are not accepted. Use HTTP
  on the local network or a certificate Android trusts.

## Interface languages

The app interface is localized through Flutter Intl (class `S`):

- `lib/l10n/intl_en.arb` — the base locale (English);
- `lib/l10n/intl_uk.arb` — Ukrainian.

The language is chosen in **Settings → Language**:

- **Same as system** (default) — the system locale is used;
- **English** — English is forced;
- **Українська** — Ukrainian is forced.

If the system has no supported locale, English is used. New strings are added
to both ARB files, after which Flutter Intl generates `lib/generated/`. The
language choice applies immediately after the settings change and extends to
the HTML pages for the Kindle (catalog, email, help), log messages, the
Android notification, OPDS errors, conversions and sending. For code outside
the widget tree there is `L10n` in `lib/l10n/l10n.dart`; the background
EPUB → MOBI conversion receives the language code and loads the translation
in the isolate.

## Development

```powershell
flutter analyze
flutter test
flutter build apk --debug
# a smaller APK for a specific architecture:
flutter build apk --release --split-per-abi
```

The ObjectBox schema is generated with `dart run build_runner build`. After
changing `lib/entity/settings_entity.dart` it must be run again; the generated
`lib/objectbox.g.dart` and `lib/objectbox-model.json` are kept in the
repository.

Tests cover the OPDS parser, link encoding, file names, the full proxying
cycle (HTML catalog, nested catalog, raw XML, file download, unavailable
server error), format selection for email and the sending queue with status
pages, as well as EPUB and FB2 → MOBI conversion (book parsing, DRM refusal,
table of contents, images, PalmDOC compression), unpacking `.fb2.zip`,
protection against repeated downloads and automatic downloading of EPUB/FB2
as MOBI. The local folder is tested separately: book filtering, subfolders and
**↑ Up**, MOBI/ZIP downloads, EPUB and FB2 conversion, the send-to-Kindle
button being visible only for Amazon formats and rejection of links outside
the chosen SAF tree. For downloads from the app the tests check saving MOBI
unchanged, unpacking ZIP, converting EPUB and FB2 to MOBI, refusing without a
chosen folder and choosing the most convenient format.

The release build in the template is signed with the debug key. To publish,
configure your own `signingConfig` in `android/app/build.gradle.kts`.
