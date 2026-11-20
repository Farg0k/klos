// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(port) => "http://phone-ip:${port}/";

  static String m1(minutes) => "${minutes} min";

  static String m2(url, error) => "Catalog error ${url}: ${error}";

  static String m3(title, count, ip) => "Catalog: ${title} (${count}) — ${ip}";

  static String m4(error) => "Connection error: ${error}";

  static String m5(title, count, nextPage) =>
      "OK: “${title}”, entries: ${count}${nextPage}";

  static String m6(file, ip) => "Conversion: done “${file}” — ${ip}";

  static String m7(error) => "Could not convert the book: ${error}";

  static String m8(title, ip) => "Conversion: “${title}” — ${ip}";

  static String m9(error) => "Cover: ${error}";

  static String m10(format) => "${format} (download)";

  static String m11(name, ip) => "Download: ${name} — ${ip} (from ZIP)";

  static String m12(name, ip) => "Download: ${name} — ${ip}";

  static String m13(format) => "${format} (send by email)";

  static String m14(count) =>
      "${Intl.plural(count, zero: '0 entries', one: '1 entry', other: '${count} entries')}";

  static String m15(index) => "Chapter ${index}";

  static String m16(error) => "The file is not a valid EPUB (ZIP): ${error}";

  static String m17(error) => "Could not read the OPF manifest: ${error}";

  static String m18(count) =>
      "${Intl.plural(count, one: '${count} book', other: '${count} books')}";

  static String m19(count, ip) => "Favorites: ${count} book(s) — ${ip}";

  static String m20(size) => "${size} B";

  static String m21(size) => "${size} KB";

  static String m22(size) => "${size} MB";

  static String m23(error) => "Could not transfer the file: ${error}";

  static String m24(error) => "File transfer interrupted: ${error}";

  static String m25(error) => "Error: ${error}";

  static String m26(error) => "Could not fetch the image: ${error}";

  static String m27(error) => "Internal server error: ${error}";

  static String m28(error) => "Could not determine the IP address: ${error}";

  static String m29(title, count, ip) =>
      "Local folder “${title}”: ${count} entries — ${ip}";

  static String m30(error) => "Could not read the file: ${error}";

  static String m31(mb) =>
      "The file is larger than ${mb} MB and cannot be used this way.";

  static String m32(error) => "Local folder: error — ${error}";

  static String m33(error) => "Could not open the folder picker: ${error}";

  static String m34(error) => "Could not read the folder: ${error}";

  static String m35(error) =>
      "Could not write the file to the folder: ${error}";

  static String m36(format) =>
      "The Kindle cannot open ${format} directly, and Amazon does not accept it by email. Try EPUB, MOBI or PDF instead.";

  static String m37(title) => "Email (mail app): “${title}”";

  static String m38(ip) => "Too many wrong PINs from ${ip}";

  static String m39(ip) => "Wrong PIN from ${ip}";

  static String m40(ip) => "Kindle signed in from ${ip}";

  static String m41(addresses) => "Listening on ${addresses}";

  static String m42(port) => "Server started on port ${port}";

  static String m43(email) => "Email: test message sent to ${email}";

  static String m44(email) =>
      "The email to ${email} was accepted by the mail server.";

  static String m45(name, ip) =>
      "Email (mail app): “${name}” — ${ip} (from ZIP)";

  static String m46(name, ip) => "Email (mail app): “${name}” — ${ip}";

  static String m47(title, file) =>
      "The book “${title}” was sent from the klos app.\n\nFile: ${file}";

  static String m48(title) => "Email: downloading “${title}”";

  static String m49(error) => "Email: error — ${error}";

  static String m50(error) => "Email sending error: ${error}";

  static String m51(title, ip) => "Email: queued “${title}” — ${ip}";

  static String m52(error) => "Could not send the email: ${error}";

  static String m53(title, email) => "Email: “${title}” sent to ${email}";

  static String m54(method) => "The ${method} method is not supported.";

  static String m55(port) => "The server is running · port ${port}";

  static String m56(status) =>
      "The OPDS server denied access (HTTP ${status}). Check the username and password in settings.";

  static String m57(error) => "Could not connect to the OPDS server: ${error}";

  static String m58(status) => "The OPDS server returned HTTP ${status}.";

  static String m59(error) => "Could not parse the OPDS catalog: ${error}";

  static String m60(error) => "Error reading the response: ${error}";

  static String m61(error) => "OpenSearch: ${error}";

  static String m62(port) =>
      "Port ${port} is already in use. Choose another port in settings.";

  static String m63(error) => "Could not prepare the file: ${error}";

  static String m64(uri, error) => "Request error ${uri}: ${error}";

  static String m65(error) => "Could not save: ${error}";

  static String m66(error) => "Could not save the book: ${error}";

  static String m67(name) => "Saved: ${name}";

  static String m68(error) => "Server error: ${error}";

  static String m69(error) => "Could not start the server: ${error}";

  static String m70(error) => "Could not stop the server: ${error}";

  static String m71(title) => "The book “${title}” from klos";

  static String m72(email) =>
      "The mail app has opened on the phone. The attachment is already added, the address <b>${email}</b> is filled in — check the message and send it.";

  static String m73(error) =>
      "Error exchanging data with the SMTP server: ${error}";

  static String m74(error) => "Could not connect to the SMTP server: ${error}";

  static String m75(error) => "TLS connection error: ${error}";

  static String m76(version) => "Version ${version} is available";

  static String m77(percent) => "Downloading… ${percent}%";

  static String m78(status) => "GitHub answered ${status}.";

  static String m79(error) => "Could not reach GitHub: ${error}";

  static String m80(error) => "Could not check for updates: ${error}";

  static String m81(error) => "Could not install the update: ${error}";

  static String m82(address) =>
      "Enter this server address:<br><b>${address}</b>";

  static String m83(name) => "The file “${name}” in the archive is empty.";

  static String m84(list) => " Found: ${list}.";

  static String m85(megabytes) =>
      "A file in the ZIP archive is too large (over ${megabytes} MB).";

  static String m86(name) => "Could not determine the format of “${name}”.";

  static String m87(name) => "Could not unpack “${name}” from the archive.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aboutApp": MessageLookupByLibrary.simpleMessage("About the app"),
        "aboutAppHint": MessageLookupByLibrary.simpleMessage(
            "Version, build and licences."),
        "aboutDescription": MessageLookupByLibrary.simpleMessage(
            "klos is a local OPDS server that lets a Kindle download books from the phone over Wi-Fi."),
        "actionWaitHint": MessageLookupByLibrary.simpleMessage(
            "Please wait, this may take a minute. Don\'t press the button again."),
        "addCatalogFirst": MessageLookupByLibrary.simpleMessage(
            "Add an OPDS catalog address or choose a folder with books."),
        "addressPlaceholder": m0,
        "amazonRejectsFormats": MessageLookupByLibrary.simpleMessage(
            "Amazon\'s Send to Kindle accepts EPUB, PDF, TXT, DOC/DOCX and images by email; it does not convert FB2, CBZ or ZIP. Add the sender address to the “Approved Personal Document E-mail List” in your Amazon settings, otherwise the email will be rejected."),
        "appBuild": MessageLookupByLibrary.simpleMessage("Build"),
        "appNotOpen": MessageLookupByLibrary.simpleMessage(
            "The klos app is not open on the phone right now. Open it on screen and try again."),
        "appNotOpenMailApp": MessageLookupByLibrary.simpleMessage(
            "The klos app is not open on the phone right now. Open it on screen and try again — the mail app will open with the message ready."),
        "appPackage": MessageLookupByLibrary.simpleMessage("Package"),
        "appVersion": MessageLookupByLibrary.simpleMessage("Version"),
        "autoRefresh": MessageLookupByLibrary.simpleMessage(
            "The page refreshes automatically every 4 seconds."),
        "autoStart":
            MessageLookupByLibrary.simpleMessage("Start automatically"),
        "autoStartHint": MessageLookupByLibrary.simpleMessage(
            "The server starts together with the app."),
        "autoStartShort": MessageLookupByLibrary.simpleMessage("auto-start"),
        "autoStop":
            MessageLookupByLibrary.simpleMessage("Stop after inactivity"),
        "autoStopHint": MessageLookupByLibrary.simpleMessage(
            "The server stops on its own when no device uses it for this long, so a forgotten server does not stay on the network."),
        "autoStopMinutes": m1,
        "autoStopOff": MessageLookupByLibrary.simpleMessage("Never"),
        "badBookAddress": MessageLookupByLibrary.simpleMessage(
            "The link has no valid book address."),
        "badCatalogAddress": MessageLookupByLibrary.simpleMessage(
            "The link has no valid catalog address."),
        "badFileAddress": MessageLookupByLibrary.simpleMessage(
            "The link has no valid file address."),
        "badImageAddress": MessageLookupByLibrary.simpleMessage(
            "The link has no valid image address."),
        "badSearchTemplate": MessageLookupByLibrary.simpleMessage(
            "The link has no valid search template."),
        "bookFallbackTitle": MessageLookupByLibrary.simpleMessage("Book"),
        "browseCatalog": MessageLookupByLibrary.simpleMessage("Browse catalog"),
        "browseCatalogHint": MessageLookupByLibrary.simpleMessage(
            "Read the catalog here and save books to favorites"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "catalog": MessageLookupByLibrary.simpleMessage("OPDS catalog"),
        "catalogAddressRequired": MessageLookupByLibrary.simpleMessage(
            "Enter the OPDS catalog address."),
        "catalogAppearance":
            MessageLookupByLibrary.simpleMessage("Catalog appearance"),
        "catalogBack": MessageLookupByLibrary.simpleMessage("← Back"),
        "catalogEmpty":
            MessageLookupByLibrary.simpleMessage("The catalog is empty."),
        "catalogErrorLog": m2,
        "catalogForward": MessageLookupByLibrary.simpleMessage("Next →"),
        "catalogLoadFailed":
            MessageLookupByLibrary.simpleMessage("Could not load the catalog"),
        "catalogLoadFailedHint": MessageLookupByLibrary.simpleMessage(
            "Check the catalog address and the internet connection."),
        "catalogLog": m3,
        "catalogNotSet":
            MessageLookupByLibrary.simpleMessage("No address added yet"),
        "catalogUrl": MessageLookupByLibrary.simpleMessage("Catalog address"),
        "catalogUrlHelper": MessageLookupByLibrary.simpleMessage(
            "Link to an OPDS catalog (Atom XML). http:// can be omitted — it will be added automatically."),
        "catalogUrlHint": MessageLookupByLibrary.simpleMessage(
            "http://192.168.1.20:8080/opds"),
        "check": MessageLookupByLibrary.simpleMessage("Check"),
        "checking": MessageLookupByLibrary.simpleMessage("Checking..."),
        "chooseFolder": MessageLookupByLibrary.simpleMessage("Choose folder"),
        "clear": MessageLookupByLibrary.simpleMessage("Clear"),
        "close": MessageLookupByLibrary.simpleMessage("Close"),
        "connectionError": m4,
        "connectionOk": m5,
        "contentsLabel": MessageLookupByLibrary.simpleMessage("Contents"),
        "conversionDoneLog": m6,
        "conversionFailed": m7,
        "conversionLog": m8,
        "convertUnsupportedFormat": MessageLookupByLibrary.simpleMessage(
            "This format cannot be converted on the phone. EPUB and FB2 are supported."),
        "coverLabel": MessageLookupByLibrary.simpleMessage("Cover"),
        "coverLog": m9,
        "deliverySmtp":
            MessageLookupByLibrary.simpleMessage("Send by email via SMTP"),
        "downloadAction": m10,
        "downloadFolderMissing": MessageLookupByLibrary.simpleMessage(
            "To save a book for the Kindle, choose a local folder on the home screen."),
        "downloadFromZipLog": m11,
        "downloadInProgress":
            MessageLookupByLibrary.simpleMessage("Downloading…"),
        "downloadLinkMissing": MessageLookupByLibrary.simpleMessage(
            "This book has no file to download."),
        "downloadLog": m12,
        "downloadToFolder":
            MessageLookupByLibrary.simpleMessage("Download to folder"),
        "downloadToFolderNote": MessageLookupByLibrary.simpleMessage(
            "The book is saved to the chosen folder, and the Kindle sees it under “Local files”. klos converts EPUB and FB2 to MOBI and unpacks ZIP archives."),
        "downloadTooLarge": MessageLookupByLibrary.simpleMessage(
            "The file is too large to download (over 120 MB)."),
        "emailAction": m13,
        "entriesCount": m14,
        "epubChapter": m15,
        "epubDrm": MessageLookupByLibrary.simpleMessage(
            "The book is DRM-protected and cannot be converted. Download another format or email the book to your Kindle."),
        "epubEmpty":
            MessageLookupByLibrary.simpleMessage("The EPUB file is empty."),
        "epubEntryTooLarge": MessageLookupByLibrary.simpleMessage(
            "A file inside the EPUB is too large to convert."),
        "epubExpandsTooMuch": MessageLookupByLibrary.simpleMessage(
            "The EPUB expands to too much data to convert."),
        "epubNoManifest":
            MessageLookupByLibrary.simpleMessage("The book has no manifest."),
        "epubNoOpf": MessageLookupByLibrary.simpleMessage(
            "The EPUB file has no OPF manifest."),
        "epubNoText": MessageLookupByLibrary.simpleMessage(
            "The book has no text to convert."),
        "epubNotZip": m16,
        "epubOpfFailed": m17,
        "epubTextNotFound": MessageLookupByLibrary.simpleMessage(
            "Could not find the book text. The EPUB may have an unusual structure or be DRM-protected."),
        "epubTooManyEntries": MessageLookupByLibrary.simpleMessage(
            "The EPUB contains too many files to convert safely."),
        "errorTitle": MessageLookupByLibrary.simpleMessage("Error"),
        "exitDialogMessage": MessageLookupByLibrary.simpleMessage(
            "If you leave the app, the server will stop and downloads to the Kindle will be interrupted. To keep the server running in the background, press “Home”, not “Back”."),
        "exitDialogTitle":
            MessageLookupByLibrary.simpleMessage("Server is running"),
        "favoriteAdd": MessageLookupByLibrary.simpleMessage("Add to favorites"),
        "favoriteRemove":
            MessageLookupByLibrary.simpleMessage("Remove from favorites"),
        "favorites": MessageLookupByLibrary.simpleMessage("Favorites"),
        "favoritesCount": m18,
        "favoritesEmpty": MessageLookupByLibrary.simpleMessage(
            "No saved books yet. Open the catalog and tap the bookmark next to a book you want."),
        "favoritesEmptyOnKindleShort":
            MessageLookupByLibrary.simpleMessage("Favorites are empty."),
        "favoritesEmptyShort":
            MessageLookupByLibrary.simpleMessage("Nothing saved yet"),
        "favoritesLog": m19,
        "fileFallback": MessageLookupByLibrary.simpleMessage("File"),
        "fileReady": MessageLookupByLibrary.simpleMessage("File ready"),
        "fileSizeBytes": m20,
        "fileSizeKb": m21,
        "fileSizeMb": m22,
        "fileTransferFailed": m23,
        "fileTransferInterrupted": m24,
        "genericError": m25,
        "getBook": MessageLookupByLibrary.simpleMessage("Get:"),
        "help": MessageLookupByLibrary.simpleMessage("Help"),
        "helpAddressPlaceholder":
            MessageLookupByLibrary.simpleMessage("http://phone-ip:8080/"),
        "helpStep1": MessageLookupByLibrary.simpleMessage(
            "1. Connect the Kindle and the phone to the same Wi-Fi network."),
        "helpStep2": MessageLookupByLibrary.simpleMessage(
            "2. On the Kindle, open Menu → Experimental Browser."),
        "helpStep3": MessageLookupByLibrary.simpleMessage(
            "3. Enter the server address:"),
        "helpStep4": MessageLookupByLibrary.simpleMessage(
            "4. Choose a book and a format. “Send by email” delivers the book to your Kindle address (via SMTP or the phone\'s mail app), “Convert” creates a MOBI on the phone, and “Download” saves the file to the device."),
        "helpStep5": MessageLookupByLibrary.simpleMessage(
            "5. The file will appear in your Kindle library or in the Documents folder."),
        "helpTip": MessageLookupByLibrary.simpleMessage(
            "Tip: if a format doesn\'t open, try MOBI. To send by email, set your Kindle address and add the sender address in Amazon — then klos will send emails itself. Without SMTP, the phone\'s mail app opens instead; this works only while klos is open. The server keeps running in the background until you stop it."),
        "helpTitle":
            MessageLookupByLibrary.simpleMessage("How to connect a Kindle"),
        "hidePassword": MessageLookupByLibrary.simpleMessage("Hide password"),
        "home": MessageLookupByLibrary.simpleMessage("Home"),
        "homeLink": MessageLookupByLibrary.simpleMessage("Home"),
        "imageFetchFailed": m26,
        "internalServerError": m27,
        "invalidJson":
            MessageLookupByLibrary.simpleMessage("invalid JSON received"),
        "ipLookupFailed": m28,
        "keepAwake": MessageLookupByLibrary.simpleMessage("Keep the screen on"),
        "keepAwakeHint": MessageLookupByLibrary.simpleMessage(
            "Stops the phone from sleeping and closing the server while it runs. The screen stays lit, so the battery drains faster."),
        "keepAwakeShort":
            MessageLookupByLibrary.simpleMessage("screen stays on"),
        "kindleAddress": MessageLookupByLibrary.simpleMessage("Kindle address"),
        "kindleAddressHint": MessageLookupByLibrary.simpleMessage(
            "Enter this address in the Experimental Browser on your Kindle."),
        "kindleAddressMissing": MessageLookupByLibrary.simpleMessage(
            "No Kindle address is set. Open the klos app, go to “Settings” → “Kindle email” and enter the Kindle address. SMTP can be left empty: the mail app will open instead."),
        "kindleEmail": MessageLookupByLibrary.simpleMessage("Kindle address"),
        "kindleEmailHelper": MessageLookupByLibrary.simpleMessage(
            "Find it on Amazon: Manage Your Content and Devices → Preferences → Send to Kindle Email Address."),
        "kindleEmailHint": MessageLookupByLibrary.simpleMessage("name"),
        "kindleEmailMissing": MessageLookupByLibrary.simpleMessage(
            "No Kindle address set. Add one to receive books by email."),
        "kindleMail": MessageLookupByLibrary.simpleMessage("Kindle email"),
        "kindleMailIntro": MessageLookupByLibrary.simpleMessage(
            "The “send by email” button appears next to formats the Kindle cannot open directly (EPUB, FB2, CBZ, ZIP) as soon as you set a Kindle address. If SMTP is configured, klos sends the email itself; otherwise the phone\'s mail app opens with the attachment and address ready. MOBI, AZW3, PDF and TXT are downloaded as regular files, and klos unpacks ZIP archives by itself."),
        "language": MessageLookupByLibrary.simpleMessage("Language"),
        "languageHint": MessageLookupByLibrary.simpleMessage(
            "Language of the app and the Kindle pages. “System default” follows the phone settings."),
        "languageSystem":
            MessageLookupByLibrary.simpleMessage("System default"),
        "library": MessageLookupByLibrary.simpleMessage("Library"),
        "licenses": MessageLookupByLibrary.simpleMessage("Licences"),
        "licensesEmpty": MessageLookupByLibrary.simpleMessage(
            "No licence information was found."),
        "licensesFullText":
            MessageLookupByLibrary.simpleMessage("Full licence texts"),
        "licensesHint": MessageLookupByLibrary.simpleMessage(
            "Libraries used by the app and the licences they are published under."),
        "licensesLoading":
            MessageLookupByLibrary.simpleMessage("Loading licence texts…"),
        "licensesPackages":
            MessageLookupByLibrary.simpleMessage("Licence texts by package"),
        "localCatalogLog": m29,
        "localFileReadFailed": m30,
        "localFileTooLarge": m31,
        "localFiles": MessageLookupByLibrary.simpleMessage("Local files"),
        "localFolder": MessageLookupByLibrary.simpleMessage("Local folder"),
        "localFolderAccessLost": MessageLookupByLibrary.simpleMessage(
            "Access to the folder was lost. Open klos → Settings → Local files and choose the folder again."),
        "localFolderAndroidOnly": MessageLookupByLibrary.simpleMessage(
            "Choosing a folder is available only on Android."),
        "localFolderBadLink": MessageLookupByLibrary.simpleMessage(
            "This link does not belong to the selected folder."),
        "localFolderConnectHint": MessageLookupByLibrary.simpleMessage(
            "The phone shares only the folder you confirm: Android does not let the app read all storage."),
        "localFolderConnectedShort":
            MessageLookupByLibrary.simpleMessage("Access granted"),
        "localFolderDefaultName":
            MessageLookupByLibrary.simpleMessage("Downloads"),
        "localFolderDefaultNote": MessageLookupByLibrary.simpleMessage(
            "Android 11+ does not allow confirming the Downloads root. In the picker open Downloads, tap ⋮ → New folder, create e.g. Books, move the books there and select that subfolder. On Android 10 and older you can select Downloads itself."),
        "localFolderEmpty": MessageLookupByLibrary.simpleMessage(
            "No books in this folder. Subfolders are shown here too."),
        "localFolderErrorLog": m32,
        "localFolderHint": MessageLookupByLibrary.simpleMessage(
            "The Kindle sees the books from this folder, including subfolders. Android will ask you to confirm the folder once. If the books are in Downloads, select a subfolder — on Android 11+ the Downloads root itself cannot be selected. The choice is applied immediately."),
        "localFolderLabel": MessageLookupByLibrary.simpleMessage("Folder"),
        "localFolderNotChosen": MessageLookupByLibrary.simpleMessage(
            "Choose a local folder on the home screen first."),
        "localFolderNotConnected": MessageLookupByLibrary.simpleMessage(
            "No folder is connected yet. Open klos → Settings → Local files and choose a folder with books. On Android 11+ the Downloads folder itself cannot be selected — choose a subfolder such as Download/Books."),
        "localFolderNotConnectedShort":
            MessageLookupByLibrary.simpleMessage("Access not granted yet"),
        "localFolderPickerFailed": m33,
        "localFolderReadFailed": m34,
        "localFolderRoot": MessageLookupByLibrary.simpleMessage("Folder root"),
        "localFolderUp": MessageLookupByLibrary.simpleMessage("↑ Up"),
        "localFolderWriteDenied": MessageLookupByLibrary.simpleMessage(
            "No permission to write to the folder. Choose the folder again on the home screen."),
        "localFolderWriteFailed": m35,
        "localFormatNeedsDelivery": m36,
        "localServer": MessageLookupByLibrary.simpleMessage("Local server"),
        "log": MessageLookupByLibrary.simpleMessage("Log"),
        "logAppStarted": MessageLookupByLibrary.simpleMessage("App started"),
        "logEmpty": MessageLookupByLibrary.simpleMessage(
            "Kindle requests and downloads will appear here."),
        "logMailApp": m37,
        "logPinBlocked": m38,
        "logPinChanged":
            MessageLookupByLibrary.simpleMessage("PIN code updated"),
        "logPinFailed": m39,
        "logPinGranted": m40,
        "logPinRotated": MessageLookupByLibrary.simpleMessage(
            "PIN replaced after repeated wrong guesses"),
        "logServerAutoStopped": MessageLookupByLibrary.simpleMessage(
            "Server stopped automatically after inactivity"),
        "logServerListening": m41,
        "logServerStarted": m42,
        "logServerStopped":
            MessageLookupByLibrary.simpleMessage("Server stopped"),
        "logTestMailSent": m43,
        "mailAccepted": MessageLookupByLibrary.simpleMessage(
            "The email was accepted by the mail server."),
        "mailAcceptedTo": m44,
        "mailAmazonHint": MessageLookupByLibrary.simpleMessage(
            "Amazon processes the book separately: it will appear in your Kindle library within a few minutes. If the sender address is not on the approved list in your Amazon settings, the email will be rejected."),
        "mailAppFromZipLog": m45,
        "mailAppLog": m46,
        "mailBody": m47,
        "mailDownloadLog": m48,
        "mailDownloadingHint": MessageLookupByLibrary.simpleMessage(
            "The book is being downloaded from the OPDS catalog. This may take a few minutes."),
        "mailErrorLog": m49,
        "mailInProgress": MessageLookupByLibrary.simpleMessage("Sending…"),
        "mailNotConfigured": MessageLookupByLibrary.simpleMessage(
            "Kindle email is not configured: enter the Kindle address, SMTP server, sender address and at least one format."),
        "mailNotConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Kindle email is not configured."),
        "mailPrepareErrorLog": m50,
        "mailQueuedLog": m51,
        "mailSendFailed": m52,
        "mailSendingHint": MessageLookupByLibrary.simpleMessage(
            "The email is being handed to the SMTP server. Do not close the klos app."),
        "mailSentLog": m53,
        "mailSkippedLog": MessageLookupByLibrary.simpleMessage(
            "Email: skipped — Kindle email is not configured"),
        "mailStageDone": MessageLookupByLibrary.simpleMessage("Email sent"),
        "mailStageDownloading": MessageLookupByLibrary.simpleMessage(
            "Downloading the book from OPDS..."),
        "mailStageFailed":
            MessageLookupByLibrary.simpleMessage("Could not send"),
        "mailStageQueued": MessageLookupByLibrary.simpleMessage("Queued..."),
        "mailStageSending": MessageLookupByLibrary.simpleMessage(
            "Sending the email to Kindle..."),
        "mailTooLarge": MessageLookupByLibrary.simpleMessage(
            "The file is larger than 25 MB — Amazon does not accept such emails. Try another format or download the book directly."),
        "methodNotSupported": m54,
        "mobiTextTooLarge": MessageLookupByLibrary.simpleMessage(
            "The book text is too large to convert."),
        "nextPage": MessageLookupByLibrary.simpleMessage("Next &gt;"),
        "nextPageSuffix":
            MessageLookupByLibrary.simpleMessage(", there is a next page"),
        "noIpAddress": MessageLookupByLibrary.simpleMessage(
            "No IP address found. Check that Wi-Fi is connected."),
        "notAnImage": MessageLookupByLibrary.simpleMessage(
            "The OPDS server returned something other than an image."),
        "notAtomFeed":
            MessageLookupByLibrary.simpleMessage("not an Atom/OPDS catalog"),
        "notConfiguredBody": MessageLookupByLibrary.simpleMessage(
            "No OPDS catalog has been added and no folder with books has been chosen."),
        "notConfiguredHelp": MessageLookupByLibrary.simpleMessage(
            "Open the klos app on your phone, add the OPDS server address or choose a folder with books, then start the local server."),
        "notFoundHeading":
            MessageLookupByLibrary.simpleMessage("Page not found"),
        "notFoundHint":
            MessageLookupByLibrary.simpleMessage("The link may be outdated."),
        "notFoundTitle": MessageLookupByLibrary.simpleMessage("Not found"),
        "notOpds2Feed":
            MessageLookupByLibrary.simpleMessage("not an OPDS 2.0 catalog"),
        "notificationChannelDescription": MessageLookupByLibrary.simpleMessage(
            "Notifications about the OPDS server for Kindle"),
        "notificationChannelName":
            MessageLookupByLibrary.simpleMessage("Local server"),
        "notificationRunning":
            MessageLookupByLibrary.simpleMessage("The server is running"),
        "notificationRunningPort": m55,
        "onlyHttpAddresses": MessageLookupByLibrary.simpleMessage(
            "Only http:// and https:// addresses are supported."),
        "opdsAccessDenied": m56,
        "opdsConnectFailed": m57,
        "opdsEmptyFile": MessageLookupByLibrary.simpleMessage(
            "The OPDS server returned an empty file."),
        "opdsHtmlInsteadOfFile": MessageLookupByLibrary.simpleMessage(
            "The OPDS server returned an HTML page instead of a file. You may need to log in, or access to this book is restricted."),
        "opdsHttpStatus": m58,
        "opdsParseFailed": m59,
        "opdsReadFailed": m60,
        "opdsResponseTooLarge": MessageLookupByLibrary.simpleMessage(
            "The OPDS server response is too large."),
        "opdsServer": MessageLookupByLibrary.simpleMessage("OPDS server"),
        "opdsTimeout": MessageLookupByLibrary.simpleMessage(
            "The OPDS server is not responding (timeout)."),
        "openSearchLog": m61,
        "openSeries": MessageLookupByLibrary.simpleMessage("Open series"),
        "passwordOptional":
            MessageLookupByLibrary.simpleMessage("Password (optional)"),
        "pinBlocked": MessageLookupByLibrary.simpleMessage(
            "Too many wrong attempts. Wait a few minutes and reload the page."),
        "pinCode": MessageLookupByLibrary.simpleMessage("PIN code"),
        "pinHintOnKindle": MessageLookupByLibrary.simpleMessage(
            "Enter this code once in the Kindle browser. The Kindle stays signed in until the server restarts."),
        "pinPageHint": MessageLookupByLibrary.simpleMessage(
            "The PIN protects your library from other devices on the Wi-Fi network."),
        "pinPageIntro": MessageLookupByLibrary.simpleMessage(
            "Enter the PIN shown in the klos app on the phone."),
        "pinPageTitle": MessageLookupByLibrary.simpleMessage("PIN required"),
        "pinProtection": MessageLookupByLibrary.simpleMessage("PIN protection"),
        "pinProtectionHint": MessageLookupByLibrary.simpleMessage(
            "Ask for a PIN before the Kindle can open the catalog. Recommended on a shared Wi-Fi network."),
        "pinRefresh": MessageLookupByLibrary.simpleMessage("New PIN"),
        "pinShort": MessageLookupByLibrary.simpleMessage("PIN"),
        "pinStartsWithServer": MessageLookupByLibrary.simpleMessage(
            "The code appears here after the server starts."),
        "pinSubmit": MessageLookupByLibrary.simpleMessage("Unlock"),
        "pinWrong":
            MessageLookupByLibrary.simpleMessage("Wrong PIN. Try again."),
        "port": MessageLookupByLibrary.simpleMessage("Port"),
        "portHelper": MessageLookupByLibrary.simpleMessage(
            "Kindle address: http://phone-ip:port/"),
        "portInUse": m62,
        "prepareFileFailed": m63,
        "previousPage": MessageLookupByLibrary.simpleMessage("&lt; Back"),
        "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
        "refreshAddresses":
            MessageLookupByLibrary.simpleMessage("Refresh IP addresses"),
        "refreshStatus":
            MessageLookupByLibrary.simpleMessage("Refresh status now"),
        "requestErrorLog": m64,
        "reset": MessageLookupByLibrary.simpleMessage("Reset"),
        "resetFolder": MessageLookupByLibrary.simpleMessage("Reset"),
        "retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "saveFailed": m65,
        "saveToFolderFailed": m66,
        "savedToFolder": m67,
        "saving": MessageLookupByLibrary.simpleMessage("Saving..."),
        "searchButton": MessageLookupByLibrary.simpleMessage("Search"),
        "searchCatalog":
            MessageLookupByLibrary.simpleMessage("Search the catalog"),
        "searchHint":
            MessageLookupByLibrary.simpleMessage("Book title or author"),
        "searchResults":
            MessageLookupByLibrary.simpleMessage("Search results:"),
        "searchUrlFailed": MessageLookupByLibrary.simpleMessage(
            "Could not build the search address."),
        "securityInfo": MessageLookupByLibrary.simpleMessage(
            "The server listens on the Wi-Fi network only. Without PIN protection every device on it can open the catalog, so use a trusted network. Changing the port restarts a running server."),
        "sendByEmailTitle":
            MessageLookupByLibrary.simpleMessage("Send by email"),
        "sendTestMail": MessageLookupByLibrary.simpleMessage("Send test email"),
        "sendUnavailable": MessageLookupByLibrary.simpleMessage(
            "Sending by email is not available in this build of the app."),
        "senderEmail": MessageLookupByLibrary.simpleMessage("Sender address"),
        "senderEmailHelper": MessageLookupByLibrary.simpleMessage(
            "Must match the address added to Amazon as an approved sender."),
        "senderEmailHint":
            MessageLookupByLibrary.simpleMessage("your.address@gmail.com"),
        "sending": MessageLookupByLibrary.simpleMessage("Sending..."),
        "serverErrorLog": m68,
        "serverOfflineHint": MessageLookupByLibrary.simpleMessage(
            "The server is stopped — the Kindle cannot connect until you start it."),
        "serverRunning":
            MessageLookupByLibrary.simpleMessage("Server is running"),
        "serverRunningHint": MessageLookupByLibrary.simpleMessage(
            "The Kindle can connect to this phone."),
        "serverSettings":
            MessageLookupByLibrary.simpleMessage("Server settings"),
        "serverSettingsHint": MessageLookupByLibrary.simpleMessage(
            "The catalog, port, folder and Kindle delivery are set up on the main screen."),
        "serverStartFailed": m69,
        "serverStopFailed": m70,
        "serverStopped":
            MessageLookupByLibrary.simpleMessage("Server is stopped"),
        "serverStoppedHint": MessageLookupByLibrary.simpleMessage(
            "Start the server so the Kindle can download books."),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsAutoSaveHint": MessageLookupByLibrary.simpleMessage(
            "Changes are saved automatically."),
        "settingsSaved": MessageLookupByLibrary.simpleMessage("Settings saved"),
        "shareAndroidOnly": MessageLookupByLibrary.simpleMessage(
            "Sending by email is only available in the Android build of klos."),
        "shareBody": m71,
        "shareChooserTitle":
            MessageLookupByLibrary.simpleMessage("Send book to Kindle"),
        "shareHint": MessageLookupByLibrary.simpleMessage(
            "If the mail app did not open, open klos on the phone screen and try again. The file is temporarily kept in the app cache."),
        "shareMissingArgs": MessageLookupByLibrary.simpleMessage(
            "No file or Kindle address was provided."),
        "shareMissingFile": MessageLookupByLibrary.simpleMessage(
            "The book file was not found."),
        "shareOpenFailed": MessageLookupByLibrary.simpleMessage(
            "Could not open the mail app."),
        "sharePrepared": MessageLookupByLibrary.simpleMessage(
            "The mail app has opened on the phone. The attachment is already added — check the message and send it."),
        "sharePreparedTo": m72,
        "showCovers": MessageLookupByLibrary.simpleMessage("Show covers"),
        "showCoversHint": MessageLookupByLibrary.simpleMessage(
            "Book thumbnails in the catalog. Turn off if pages should load faster or without images."),
        "showPassword": MessageLookupByLibrary.simpleMessage("Show password"),
        "smtpAuthRejected": MessageLookupByLibrary.simpleMessage(
            "The SMTP server rejected the login or password. For Gmail, use an app password, not your regular password."),
        "smtpCommunication": m73,
        "smtpConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Configured — klos sends emails itself."),
        "smtpConnectFailed": m74,
        "smtpHost": MessageLookupByLibrary.simpleMessage("SMTP server"),
        "smtpHostHelper": MessageLookupByLibrary.simpleMessage(
            "For example: smtp.gmail.com, smtp.ukr.net"),
        "smtpHostHint": MessageLookupByLibrary.simpleMessage("smtp.gmail.com"),
        "smtpIntro": MessageLookupByLibrary.simpleMessage(
            "Fill this in so klos sends emails itself. Without SMTP, the “send by email” button opens the phone\'s mail app."),
        "smtpMessageRejected": MessageLookupByLibrary.simpleMessage(
            "The mail server rejected the message: check the Kindle and sender addresses."),
        "smtpNoGreeting": MessageLookupByLibrary.simpleMessage(
            "The SMTP server did not send a greeting. Check the address and port."),
        "smtpNoSecure": MessageLookupByLibrary.simpleMessage(
            "The SMTP server does not support a secure connection. Check the port and the SSL switch."),
        "smtpNotConfigured": MessageLookupByLibrary.simpleMessage(
            "SMTP is not configured — the “send by email” button will open the phone\'s mail app."),
        "smtpNotConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Not configured — the mail app opens instead."),
        "smtpOptional": MessageLookupByLibrary.simpleMessage("SMTP (optional)"),
        "smtpPassword": MessageLookupByLibrary.simpleMessage("SMTP password"),
        "smtpPasswordHelper": MessageLookupByLibrary.simpleMessage(
            "For Gmail, use an app password. Stored only on this device."),
        "smtpPort": MessageLookupByLibrary.simpleMessage("SMTP port"),
        "smtpPortHelper":
            MessageLookupByLibrary.simpleMessage("587 — STARTTLS, 465 — SSL"),
        "smtpSsl": MessageLookupByLibrary.simpleMessage(
            "SSL/TLS immediately (port 465)"),
        "smtpSslHint": MessageLookupByLibrary.simpleMessage(
            "Enable for port 465. Usually off for 587: the connection is secured with STARTTLS."),
        "smtpTimeout": MessageLookupByLibrary.simpleMessage(
            "The SMTP server is not responding (timeout)."),
        "smtpTls": MessageLookupByLibrary.simpleMessage(
            "TLS connection error with the SMTP server. Try another port (465 with SSL or 587 without SSL)."),
        "smtpUsername": MessageLookupByLibrary.simpleMessage("SMTP username"),
        "smtpUsernameHelper": MessageLookupByLibrary.simpleMessage(
            "Usually your full email address."),
        "source": MessageLookupByLibrary.simpleMessage("Source:"),
        "startServer": MessageLookupByLibrary.simpleMessage("Start server"),
        "stopAndExit": MessageLookupByLibrary.simpleMessage("Stop and exit"),
        "stopServer": MessageLookupByLibrary.simpleMessage("Stop server"),
        "storedOnDevice":
            MessageLookupByLibrary.simpleMessage("Stored only on this device."),
        "tagline": MessageLookupByLibrary.simpleMessage(
            "klos • a local OPDS bridge for Kindle"),
        "testMailBody": MessageLookupByLibrary.simpleMessage(
            "Test email from klos.\n\nIf Amazon accepted the message, books will arrive on your Kindle."),
        "testMailFileContent": MessageLookupByLibrary.simpleMessage(
            "This is a test email from klos.\nIf you see it on the Kindle, email is configured correctly.\n"),
        "testMailMissing": MessageLookupByLibrary.simpleMessage(
            "Fill in the Kindle address, SMTP server and sender address, and select at least one format."),
        "testMailNotConfigured": MessageLookupByLibrary.simpleMessage(
            "First fill in the Kindle address, SMTP server and sender address, and select at least one format."),
        "testMailSent": MessageLookupByLibrary.simpleMessage(
            "The test email was handed to the SMTP server. Check your Kindle in a few minutes."),
        "testMailSubject":
            MessageLookupByLibrary.simpleMessage("klos: email check"),
        "theme": MessageLookupByLibrary.simpleMessage("Theme"),
        "themeDark": MessageLookupByLibrary.simpleMessage("Dark"),
        "themeHint": MessageLookupByLibrary.simpleMessage(
            "“Auto” follows the phone\'s light or dark mode."),
        "themeLight": MessageLookupByLibrary.simpleMessage("Light"),
        "themeSystem": MessageLookupByLibrary.simpleMessage("Auto"),
        "tlsError": m75,
        "tooLargeToEmail": MessageLookupByLibrary.simpleMessage(
            "The file is too large to send by email (over 100 MB)."),
        "unknownError": MessageLookupByLibrary.simpleMessage("Unknown error."),
        "untitled": MessageLookupByLibrary.simpleMessage("Untitled"),
        "updateAvailable": m76,
        "updateBannerHint": MessageLookupByLibrary.simpleMessage(
            "Tap to see what\'s new and install it."),
        "updateCheck":
            MessageLookupByLibrary.simpleMessage("Check for updates"),
        "updateChecking":
            MessageLookupByLibrary.simpleMessage("Checking for updates…"),
        "updateDownload":
            MessageLookupByLibrary.simpleMessage("Download and install"),
        "updateDownloading": m77,
        "updateErrorDownload": MessageLookupByLibrary.simpleMessage(
            "The APK could not be downloaded."),
        "updateErrorGithub": m78,
        "updateErrorNetwork": m79,
        "updateErrorNoApk": MessageLookupByLibrary.simpleMessage(
            "The release has no APK for this phone."),
        "updateFailed": m80,
        "updateInstallFailed": m81,
        "updateInstallHint": MessageLookupByLibrary.simpleMessage(
            "The new version installs over this one, so settings, favorites and the chosen folder stay in place."),
        "updateNone": MessageLookupByLibrary.simpleMessage(
            "You have the latest version."),
        "updateNotes": MessageLookupByLibrary.simpleMessage("What\'s new"),
        "usernameOptional":
            MessageLookupByLibrary.simpleMessage("Username (optional)"),
        "validateCatalogRequired": MessageLookupByLibrary.simpleMessage(
            "Enter the OPDS catalog address"),
        "validateCatalogScheme": MessageLookupByLibrary.simpleMessage(
            "The address must start with http:// or https://"),
        "validateEmailInvalid":
            MessageLookupByLibrary.simpleMessage("Invalid email address"),
        "validateEmailRequired":
            MessageLookupByLibrary.simpleMessage("Enter an address"),
        "validatePort": MessageLookupByLibrary.simpleMessage(
            "Port must be between 1024 and 65535"),
        "validateSmtpHost": MessageLookupByLibrary.simpleMessage(
            "Enter only the server address, e.g. smtp.gmail.com"),
        "validateSmtpPort": MessageLookupByLibrary.simpleMessage(
            "Port must be between 1 and 65535"),
        "webHelpActions": MessageLookupByLibrary.simpleMessage(
            "“send by email” goes to the Kindle address; “download” for EPUB/FB2 builds a MOBI on the phone — experimental, and complex layout is simplified. The email button appears only for formats Amazon accepts (EPUB, PDF, TXT, DOC/DOCX, RTF, HTML). If SMTP is configured, the email is sent automatically; otherwise the phone\'s mail app opens with the attachment ready. Everything else is downloaded as a regular file; klos unpacks ZIP archives itself and takes the file suitable for the Kindle or Amazon."),
        "webHelpFavorites": MessageLookupByLibrary.simpleMessage(
            "Favorites are the books you saved in the klos app. Open Library → Browse catalog, tap the bookmark next to a book, and it appears in Favorites — on the Kindle too, with the same download and email buttons."),
        "webHelpFormats": MessageLookupByLibrary.simpleMessage(
            "If a format does not open, try MOBI or AZW3. klos unpacks ZIP archives automatically: for the Kindle it takes MOBI, AZW3, AZW, PDF or TXT, for email — EPUB, PDF, TXT, RTF, DOC/DOCX or HTML, and for conversion — EPUB. If there is only FB2 or CBZ inside, klos will say so."),
        "webHelpHeading":
            MessageLookupByLibrary.simpleMessage("How to download a book"),
        "webHelpLimits": MessageLookupByLibrary.simpleMessage(
            "Conversion simplifies complex layout and does not work with DRM. Sending via the mail app works only while the klos app is open on the phone: the file is temporarily stored in the app cache."),
        "webHelpPrivacy": MessageLookupByLibrary.simpleMessage(
            "Books are not stored on the phone permanently: the server only passes them from the OPDS catalog to the Kindle. The phone must be nearby and connected to the same network. While the server is on, a notification is visible in the Android notification shade."),
        "webHelpSearch": MessageLookupByLibrary.simpleMessage(
            "If the catalog has a <b>Search</b> field, search works directly from the Kindle: enter an author or a book title."),
        "webHelpStep1": MessageLookupByLibrary.simpleMessage(
            "Connect the Kindle and the phone to the same Wi-Fi network."),
        "webHelpStep2": MessageLookupByLibrary.simpleMessage(
            "On the Kindle, open <b>Experimental Browser</b>."),
        "webHelpStep3": m82,
        "webHelpStep4": MessageLookupByLibrary.simpleMessage(
            "Choose a book and a format. <b>(download)</b> saves the file to the Kindle, <b>(send by email)</b> sends it to the Kindle address — automatically via SMTP if configured, or via the phone\'s mail app — and <b>(convert)</b> creates a MOBI on the phone."),
        "webHelpStep5": MessageLookupByLibrary.simpleMessage(
            "The file will appear in your Kindle library or in the <b>Documents</b> folder."),
        "zipBroken": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive is damaged or password-protected and cannot be opened."),
        "zipEmptyFile": m83,
        "zipFound": m84,
        "zipNoConvertible": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains no EPUB or FB2, so there is nothing to convert."),
        "zipNoEmailFile": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains no file Amazon accepts (EPUB, PDF, TXT, RTF, DOC/DOCX or HTML)."),
        "zipNoKindleFile": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains no file the Kindle opens directly (MOBI, AZW3, AZW, PDF or TXT)."),
        "zipNoUsableFiles": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains no usable files."),
        "zipOnlyEpub": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains only an EPUB. klos converts it to MOBI on download."),
        "zipOnlyFb2": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains only an FB2. klos converts it to MOBI on download."),
        "zipTooLarge": m85,
        "zipTooManyEntries": MessageLookupByLibrary.simpleMessage(
            "The ZIP archive contains too many files."),
        "zipUnknownFormat": m86,
        "zipUnpackFailed": m87
      };
}
