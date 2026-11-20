// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a uk locale. All the
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
  String get localeName => 'uk';

  static String m0(port) => "http://IP-телефону:${port}/";

  static String m1(minutes) => "${minutes} хв";

  static String m2(url, error) => "Помилка каталогу ${url}: ${error}";

  static String m3(title, count, ip) => "Каталог: ${title} (${count}) — ${ip}";

  static String m4(error) => "Помилка з\'єднання: ${error}";

  static String m5(title, count, nextPage) =>
      "OK: «${title}», записів: ${count}${nextPage}";

  static String m6(file, ip) => "Конвертація: готово «${file}» — ${ip}";

  static String m7(error) => "Не вдалося конвертувати книгу: ${error}";

  static String m8(title, ip) => "Конвертація: «${title}» — ${ip}";

  static String m9(error) => "Обкладинка: ${error}";

  static String m10(format) => "${format} (завантажити)";

  static String m11(name, ip) => "Завантаження: ${name} — ${ip} (з ZIP)";

  static String m12(name, ip) => "Завантаження: ${name} — ${ip}";

  static String m13(format) => "${format} (на пошту)";

  static String m14(count) =>
      "${Intl.plural(count, one: '${count} запис', few: '${count} записи', many: '${count} записів', other: '${count} записів')}";

  static String m15(index) => "Розділ ${index}";

  static String m16(error) => "Файл не є коректним EPUB (ZIP): ${error}";

  static String m17(error) => "Не вдалося прочитати OPF-маніфест: ${error}";

  static String m18(count) =>
      "${Intl.plural(count, one: '${count} книга', few: '${count} книги', many: '${count} книг', other: '${count} книг')}";

  static String m19(count, ip) => "Обране: ${count} книг(и) — ${ip}";

  static String m20(size) => "${size} Б";

  static String m21(size) => "${size} КБ";

  static String m22(size) => "${size} МБ";

  static String m23(error) => "Не вдалося передати файл: ${error}";

  static String m24(error) => "Передавання файлу перервано: ${error}";

  static String m25(error) => "Помилка: ${error}";

  static String m26(error) => "Не вдалося отримати зображення: ${error}";

  static String m27(error) => "Внутрішня помилка сервера: ${error}";

  static String m28(error) => "Не вдалося визначити IP-адресу: ${error}";

  static String m29(title, count, ip) =>
      "Локальна папка «${title}»: ${count} записів — ${ip}";

  static String m30(error) => "Не вдалося прочитати файл: ${error}";

  static String m31(mb) =>
      "Файл більший за ${mb} МБ, його не можна використати так.";

  static String m32(error) => "Локальна папка: помилка — ${error}";

  static String m33(error) => "Не вдалося відкрити вибір папки: ${error}";

  static String m34(error) => "Не вдалося прочитати папку: ${error}";

  static String m35(error) => "Не вдалося записати файл у папку: ${error}";

  static String m36(format) =>
      "Kindle не відкриває ${format} напряму, і Amazon не приймає його листом. Спробуйте EPUB, MOBI або PDF.";

  static String m37(title) => "Пошта (поштова програма): «${title}»";

  static String m38(ip) => "Забагато неправильних PIN з ${ip}";

  static String m39(ip) => "Неправильний PIN з ${ip}";

  static String m40(ip) => "Kindle увійшов з ${ip}";

  static String m41(addresses) => "Слухає на ${addresses}";

  static String m42(port) => "Сервер запущено на порту ${port}";

  static String m43(email) => "Пошта: тестовий лист надіслано на ${email}";

  static String m44(email) => "Лист на ${email} прийнято поштовим сервером.";

  static String m45(name, ip) =>
      "Пошта (поштова програма): «${name}» — ${ip} (з ZIP)";

  static String m46(name, ip) => "Пошта (поштова програма): «${name}» — ${ip}";

  static String m47(title, file) =>
      "Книга «${title}» надіслана із застосунку klos.\n\nФайл: ${file}";

  static String m48(title) => "Пошта: завантаження «${title}»";

  static String m49(error) => "Пошта: помилка — ${error}";

  static String m50(error) => "Помилка відправки листом: ${error}";

  static String m51(title, ip) => "Пошта: у черзі «${title}» — ${ip}";

  static String m52(error) => "Не вдалося надіслати лист: ${error}";

  static String m53(title, email) => "Пошта: «${title}» надіслано на ${email}";

  static String m54(method) => "Метод ${method} не підтримується.";

  static String m55(port) => "Сервер працює · порт ${port}";

  static String m56(status) =>
      "OPDS-сервер відхилив доступ (HTTP ${status}). Перевірте логін і пароль у налаштуваннях.";

  static String m57(error) =>
      "Не вдалося підключитися до OPDS-сервера: ${error}";

  static String m58(status) => "OPDS-сервер повернув HTTP ${status}.";

  static String m59(error) => "Не вдалося розібрати OPDS-каталог: ${error}";

  static String m60(error) => "Помилка читання відповіді: ${error}";

  static String m61(error) => "OpenSearch: ${error}";

  static String m62(port) =>
      "Порт ${port} вже зайнятий. Виберіть інший порт у налаштуваннях.";

  static String m63(error) => "Не вдалося підготувати файл: ${error}";

  static String m64(uri, error) => "Помилка запиту ${uri}: ${error}";

  static String m65(error) => "Не вдалося зберегти: ${error}";

  static String m66(error) => "Не вдалося зберегти книгу: ${error}";

  static String m67(name) => "Збережено: ${name}";

  static String m68(error) => "Помилка сервера: ${error}";

  static String m69(error) => "Не вдалося запустити сервер: ${error}";

  static String m70(error) => "Не вдалося зупинити сервер: ${error}";

  static String m71(title) => "Книга «${title}» із klos";

  static String m72(email) =>
      "На телефоні відкрито поштову програму. Вкладення вже додано, адреса <b>${email}</b> заповнена — перевірте лист і надішліть його.";

  static String m73(error) => "Помилка обміну з SMTP-сервером: ${error}";

  static String m74(error) =>
      "Не вдалося підключитися до SMTP-сервера: ${error}";

  static String m75(error) => "Помилка TLS-з\'єднання: ${error}";

  static String m76(version) => "Доступна версія ${version}";

  static String m77(percent) => "Завантажуємо… ${percent}%";

  static String m78(status) => "GitHub відповів ${status}.";

  static String m79(error) => "Не вдалося зв\'язатися з GitHub: ${error}";

  static String m80(error) => "Не вдалося перевірити оновлення: ${error}";

  static String m81(error) => "Не вдалося встановити оновлення: ${error}";

  static String m82(address) =>
      "Введіть адресу цього сервера:<br><b>${address}</b>";

  static String m83(name) => "Файл «${name}» в архіві порожній.";

  static String m84(list) => " Знайдено: ${list}.";

  static String m85(megabytes) =>
      "Файл у ZIP-архіві завеликий (понад ${megabytes} МБ).";

  static String m86(name) => "Не вдалося визначити формат файлу «${name}».";

  static String m87(name) => "Не вдалося розпакувати «${name}» з архіву.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "aboutApp": MessageLookupByLibrary.simpleMessage("Про застосунок"),
        "aboutAppHint":
            MessageLookupByLibrary.simpleMessage("Версія, збірка та ліцензії."),
        "aboutDescription": MessageLookupByLibrary.simpleMessage(
            "klos — локальний OPDS-сервер, який дає Kindle змогу завантажувати книги з телефона через Wi-Fi."),
        "actionWaitHint": MessageLookupByLibrary.simpleMessage(
            "Зачекайте, це може тривати до хвилини. Не натискайте кнопку ще раз."),
        "addCatalogFirst": MessageLookupByLibrary.simpleMessage(
            "Додайте адресу OPDS-каталогу або виберіть папку з книгами."),
        "addressPlaceholder": m0,
        "amazonRejectsFormats": MessageLookupByLibrary.simpleMessage(
            "Amazon приймає листом EPUB, PDF, TXT, DOC/DOCX та зображення; FB2, CBZ і ZIP він не конвертує. Адреса відправника має бути додана до «Approved Personal Document E-mail List» у налаштуваннях Amazon, інакше лист відхилять."),
        "appBuild": MessageLookupByLibrary.simpleMessage("Збірка"),
        "appNotOpen": MessageLookupByLibrary.simpleMessage(
            "Застосунок klos зараз не відкритий на телефоні. Відкрийте його на екрані та повторіть."),
        "appNotOpenMailApp": MessageLookupByLibrary.simpleMessage(
            "Застосунок klos зараз не відкритий на телефоні. Відкрийте його на екрані та повторіть — тоді відкриється поштова програма з готовим листом."),
        "appPackage": MessageLookupByLibrary.simpleMessage("Пакет"),
        "appVersion": MessageLookupByLibrary.simpleMessage("Версія"),
        "autoRefresh": MessageLookupByLibrary.simpleMessage(
            "Сторінка оновлюється автоматично кожні 4 секунди."),
        "autoStart":
            MessageLookupByLibrary.simpleMessage("Запускати автоматично"),
        "autoStartHint": MessageLookupByLibrary.simpleMessage(
            "Сервер стартуватиме разом із застосунком."),
        "autoStartShort": MessageLookupByLibrary.simpleMessage("автозапуск"),
        "autoStop": MessageLookupByLibrary.simpleMessage(
            "Зупиняти після бездіяльності"),
        "autoStopHint": MessageLookupByLibrary.simpleMessage(
            "Сервер сам зупиниться, якщо ним ніхто не користується цей час, щоб забутий сервер не висів у мережі."),
        "autoStopMinutes": m1,
        "autoStopOff": MessageLookupByLibrary.simpleMessage("Ніколи"),
        "badBookAddress": MessageLookupByLibrary.simpleMessage(
            "У посиланні немає коректної адреси книги."),
        "badCatalogAddress": MessageLookupByLibrary.simpleMessage(
            "У посиланні немає коректної адреси каталогу."),
        "badFileAddress": MessageLookupByLibrary.simpleMessage(
            "У посиланні немає коректної адреси файлу."),
        "badImageAddress": MessageLookupByLibrary.simpleMessage(
            "У посиланні немає коректної адреси зображення."),
        "badSearchTemplate": MessageLookupByLibrary.simpleMessage(
            "У посиланні немає коректного шаблону пошуку."),
        "bookFallbackTitle": MessageLookupByLibrary.simpleMessage("Книга"),
        "browseCatalog":
            MessageLookupByLibrary.simpleMessage("Переглянути каталог"),
        "browseCatalogHint": MessageLookupByLibrary.simpleMessage(
            "Читайте каталог у застосунку та додавайте книги в обране"),
        "cancel": MessageLookupByLibrary.simpleMessage("Скасувати"),
        "catalog": MessageLookupByLibrary.simpleMessage("OPDS-каталог"),
        "catalogAddressRequired": MessageLookupByLibrary.simpleMessage(
            "Вкажіть адресу OPDS-каталогу."),
        "catalogAppearance":
            MessageLookupByLibrary.simpleMessage("Вигляд каталогу"),
        "catalogBack": MessageLookupByLibrary.simpleMessage("← Назад"),
        "catalogEmpty":
            MessageLookupByLibrary.simpleMessage("Каталог порожній."),
        "catalogErrorLog": m2,
        "catalogForward": MessageLookupByLibrary.simpleMessage("Далі →"),
        "catalogLoadFailed": MessageLookupByLibrary.simpleMessage(
            "Не вдалося завантажити каталог"),
        "catalogLoadFailedHint": MessageLookupByLibrary.simpleMessage(
            "Перевірте адресу каталогу та з\'єднання з інтернетом."),
        "catalogLog": m3,
        "catalogNotSet":
            MessageLookupByLibrary.simpleMessage("Адресу ще не додано"),
        "catalogUrl": MessageLookupByLibrary.simpleMessage("Адреса каталогу"),
        "catalogUrlHelper": MessageLookupByLibrary.simpleMessage(
            "Посилання на OPDS-каталог (Atom XML). Можна без http:// — він додасться автоматично."),
        "catalogUrlHint": MessageLookupByLibrary.simpleMessage(
            "http://192.168.1.20:8080/opds"),
        "check": MessageLookupByLibrary.simpleMessage("Перевірити"),
        "checking": MessageLookupByLibrary.simpleMessage("Перевірка..."),
        "chooseFolder": MessageLookupByLibrary.simpleMessage("Вибрати папку"),
        "clear": MessageLookupByLibrary.simpleMessage("Очистити"),
        "close": MessageLookupByLibrary.simpleMessage("Закрити"),
        "connectionError": m4,
        "connectionOk": m5,
        "contentsLabel": MessageLookupByLibrary.simpleMessage("Зміст"),
        "conversionDoneLog": m6,
        "conversionFailed": m7,
        "conversionLog": m8,
        "convertUnsupportedFormat": MessageLookupByLibrary.simpleMessage(
            "Цей формат не можна конвертувати на телефоні. Підтримуються EPUB і FB2."),
        "coverLabel": MessageLookupByLibrary.simpleMessage("Обкладинка"),
        "coverLog": m9,
        "deliverySmtp": MessageLookupByLibrary.simpleMessage(
            "Надсилання листом через SMTP"),
        "downloadAction": m10,
        "downloadFolderMissing": MessageLookupByLibrary.simpleMessage(
            "Щоб зберегти книгу для Kindle, виберіть локальну папку на головному екрані."),
        "downloadFromZipLog": m11,
        "downloadInProgress":
            MessageLookupByLibrary.simpleMessage("Завантаження…"),
        "downloadLinkMissing": MessageLookupByLibrary.simpleMessage(
            "У цієї книги немає файлу для завантаження."),
        "downloadLog": m12,
        "downloadToFolder":
            MessageLookupByLibrary.simpleMessage("Завантажити в папку"),
        "downloadToFolderNote": MessageLookupByLibrary.simpleMessage(
            "Книга збережеться у вибрану папку, і Kindle побачить її в «Локальних файлах». EPUB і FB2 klos конвертує в MOBI, ZIP розпакує сам."),
        "downloadTooLarge": MessageLookupByLibrary.simpleMessage(
            "Файл завеликий для завантаження (понад 120 МБ)."),
        "emailAction": m13,
        "entriesCount": m14,
        "epubChapter": m15,
        "epubDrm": MessageLookupByLibrary.simpleMessage(
            "Книга захищена DRM і не може бути конвертована. Завантажте інший формат або надішліть книгу на Kindle поштою."),
        "epubEmpty":
            MessageLookupByLibrary.simpleMessage("Файл EPUB порожній."),
        "epubEntryTooLarge": MessageLookupByLibrary.simpleMessage(
            "Файл усередині EPUB завеликий для конвертації."),
        "epubExpandsTooMuch": MessageLookupByLibrary.simpleMessage(
            "EPUB розпаковується в забагато даних для конвертації."),
        "epubNoManifest":
            MessageLookupByLibrary.simpleMessage("У книзі немає маніфесту."),
        "epubNoOpf": MessageLookupByLibrary.simpleMessage(
            "У файлі EPUB немає OPF-маніфесту."),
        "epubNoText": MessageLookupByLibrary.simpleMessage(
            "У книзі немає тексту, який можна конвертувати."),
        "epubNotZip": m16,
        "epubOpfFailed": m17,
        "epubTextNotFound": MessageLookupByLibrary.simpleMessage(
            "Не вдалося знайти текст книги. Можливо, EPUB має незвичайну структуру або захищений DRM."),
        "epubTooManyEntries": MessageLookupByLibrary.simpleMessage(
            "EPUB містить забагато файлів для безпечної конвертації."),
        "errorTitle": MessageLookupByLibrary.simpleMessage("Помилка"),
        "exitDialogMessage": MessageLookupByLibrary.simpleMessage(
            "Якщо вийти із застосунку, сервер зупиниться, а завантаження на Kindle перервуться. Щоб залишити сервер у фоні, натисніть «Додому», а не «Назад»."),
        "exitDialogTitle":
            MessageLookupByLibrary.simpleMessage("Сервер працює"),
        "favoriteAdd": MessageLookupByLibrary.simpleMessage("Додати в обране"),
        "favoriteRemove":
            MessageLookupByLibrary.simpleMessage("Прибрати з обраного"),
        "favorites": MessageLookupByLibrary.simpleMessage("Обране"),
        "favoritesCount": m18,
        "favoritesEmpty": MessageLookupByLibrary.simpleMessage(
            "Тут ще немає збережених книг. Відкрийте каталог і натисніть закладку біля потрібної книги."),
        "favoritesEmptyOnKindleShort":
            MessageLookupByLibrary.simpleMessage("Обране порожнє."),
        "favoritesEmptyShort":
            MessageLookupByLibrary.simpleMessage("Ще нічого не збережено"),
        "favoritesLog": m19,
        "fileFallback": MessageLookupByLibrary.simpleMessage("Файл"),
        "fileReady": MessageLookupByLibrary.simpleMessage("Файл готовий"),
        "fileSizeBytes": m20,
        "fileSizeKb": m21,
        "fileSizeMb": m22,
        "fileTransferFailed": m23,
        "fileTransferInterrupted": m24,
        "genericError": m25,
        "getBook": MessageLookupByLibrary.simpleMessage("Отримати:"),
        "help": MessageLookupByLibrary.simpleMessage("Довідка"),
        "helpAddressPlaceholder": MessageLookupByLibrary.simpleMessage(
            "http://IP-адреса-телефону:8080/"),
        "helpStep1": MessageLookupByLibrary.simpleMessage(
            "1. Підключіть Kindle і телефон до однієї Wi-Fi мережі."),
        "helpStep2": MessageLookupByLibrary.simpleMessage(
            "2. На Kindle відкрийте Menu → Experimental Browser."),
        "helpStep3":
            MessageLookupByLibrary.simpleMessage("3. Введіть адресу сервера:"),
        "helpStep4": MessageLookupByLibrary.simpleMessage(
            "4. Виберіть книгу та формат. Позначка «на пошту» надішле книгу на адресу Kindle (через SMTP або поштову програму на телефоні), «конвертувати» створить MOBI на телефоні, а «завантажити» збереже файл на пристрої."),
        "helpStep5": MessageLookupByLibrary.simpleMessage(
            "5. Файл з\'явиться в бібліотеці Kindle або в теці Documents."),
        "helpTip": MessageLookupByLibrary.simpleMessage(
            "Порада: якщо формат не відкривається, спробуйте MOBI. Для надсилання листом вкажіть адресу Kindle і додайте адресу відправника в Amazon — тоді klos надсилатиме листи сам. Без SMTP відкриється поштова програма на телефоні; це працює, лише коли klos відкрито. Сервер працює у фоні, поки ви його не зупините."),
        "helpTitle":
            MessageLookupByLibrary.simpleMessage("Як підключити Kindle"),
        "hidePassword":
            MessageLookupByLibrary.simpleMessage("Приховати пароль"),
        "home": MessageLookupByLibrary.simpleMessage("На головну"),
        "homeLink": MessageLookupByLibrary.simpleMessage("Головна"),
        "imageFetchFailed": m26,
        "internalServerError": m27,
        "invalidJson":
            MessageLookupByLibrary.simpleMessage("отримано некоректний JSON"),
        "ipLookupFailed": m28,
        "keepAwake": MessageLookupByLibrary.simpleMessage("Не вимикати екран"),
        "keepAwakeHint": MessageLookupByLibrary.simpleMessage(
            "Не дає телефону заснути й зупинити сервер, поки він працює. Екран постійно світиться, тож батарея розряджається швидше."),
        "keepAwakeShort":
            MessageLookupByLibrary.simpleMessage("екран не гасне"),
        "kindleAddress":
            MessageLookupByLibrary.simpleMessage("Адреса для Kindle"),
        "kindleAddressHint": MessageLookupByLibrary.simpleMessage(
            "Введіть цю адресу в Experimental Browser на Kindle."),
        "kindleAddressMissing": MessageLookupByLibrary.simpleMessage(
            "Адресу Kindle не вказано. Відкрийте застосунок klos, зайдіть у «Налаштування» → «Пошта Kindle» і вкажіть адресу Kindle. SMTP можна не заповнювати: тоді відкриється поштова програма."),
        "kindleEmail": MessageLookupByLibrary.simpleMessage("Адреса Kindle"),
        "kindleEmailHelper": MessageLookupByLibrary.simpleMessage(
            "Знайдіть її на Amazon: Manage Your Content and Devices → Preferences → Send to Kindle Email Address."),
        "kindleEmailHint": MessageLookupByLibrary.simpleMessage("ім\'я"),
        "kindleEmailMissing": MessageLookupByLibrary.simpleMessage(
            "Адресу Kindle не вказано. Додайте її, щоб отримати книгу листом."),
        "kindleMail": MessageLookupByLibrary.simpleMessage("Пошта Kindle"),
        "kindleMailIntro": MessageLookupByLibrary.simpleMessage(
            "Кнопка «на пошту» з\'являється біля форматів, які Kindle не відкриває напряму (EPUB, FB2, CBZ, ZIP), щойно ви вкажете адресу Kindle. Якщо заповнити SMTP, klos надсилатиме лист сам; якщо ні — відкриється поштова програма на телефоні з готовим вкладенням і заповненою адресою. MOBI, AZW3, PDF і TXT завантажуються як звичайні файли, а ZIP klos розпаковує сам."),
        "language": MessageLookupByLibrary.simpleMessage("Мова"),
        "languageHint": MessageLookupByLibrary.simpleMessage(
            "Мова застосунку та сторінок для Kindle. «Як у системі» бере мову з налаштувань телефона."),
        "languageSystem": MessageLookupByLibrary.simpleMessage("Як у системі"),
        "library": MessageLookupByLibrary.simpleMessage("Бібліотека"),
        "licenses": MessageLookupByLibrary.simpleMessage("Ліцензії"),
        "licensesEmpty": MessageLookupByLibrary.simpleMessage(
            "Даних про ліцензії не знайдено."),
        "licensesFullText":
            MessageLookupByLibrary.simpleMessage("Повні тексти ліцензій"),
        "licensesHint": MessageLookupByLibrary.simpleMessage(
            "Бібліотеки, які використовує застосунок, та ліцензії, за якими їх опубліковано."),
        "licensesLoading": MessageLookupByLibrary.simpleMessage(
            "Завантажуємо тексти ліцензій…"),
        "licensesPackages":
            MessageLookupByLibrary.simpleMessage("Тексти ліцензій за пакетами"),
        "localCatalogLog": m29,
        "localFileReadFailed": m30,
        "localFileTooLarge": m31,
        "localFiles": MessageLookupByLibrary.simpleMessage("Локальні файли"),
        "localFolder": MessageLookupByLibrary.simpleMessage("Локальна папка"),
        "localFolderAccessLost": MessageLookupByLibrary.simpleMessage(
            "Доступ до папки втрачено. Відкрийте klos → «Налаштування» → «Локальні файли» і виберіть папку знову."),
        "localFolderAndroidOnly": MessageLookupByLibrary.simpleMessage(
            "Вибір папки доступний лише на Android."),
        "localFolderBadLink": MessageLookupByLibrary.simpleMessage(
            "Це посилання не належить вибраній папці."),
        "localFolderConnectHint": MessageLookupByLibrary.simpleMessage(
            "Телефон відкриває лише ту папку, яку ви підтвердите: Android не дозволяє застосунку читати все сховище."),
        "localFolderConnectedShort":
            MessageLookupByLibrary.simpleMessage("Доступ надано"),
        "localFolderDefaultName":
            MessageLookupByLibrary.simpleMessage("Downloads"),
        "localFolderDefaultNote": MessageLookupByLibrary.simpleMessage(
            "Android 11+ не дає підтвердити сам корінь Downloads. У виборі папки відкрийте Downloads, натисніть ⋮ → «Нова папка», створіть, наприклад, Books, перенесіть туди книги й виберіть цю підпапку. На Android 10 і старіших можна вибрати сам Downloads."),
        "localFolderEmpty": MessageLookupByLibrary.simpleMessage(
            "У цій папці немає книг. Підпапки теж показуються тут."),
        "localFolderErrorLog": m32,
        "localFolderHint": MessageLookupByLibrary.simpleMessage(
            "Kindle бачить книги з цієї папки разом із підпапками. Android один раз попросить підтвердити папку. Якщо книги лежать у Downloads, виберіть підпапку — сам корінь Downloads на Android 11+ недоступний. Вибір застосовується одразу."),
        "localFolderLabel": MessageLookupByLibrary.simpleMessage("Папка"),
        "localFolderNotChosen": MessageLookupByLibrary.simpleMessage(
            "Спочатку виберіть локальну папку на головному екрані."),
        "localFolderNotConnected": MessageLookupByLibrary.simpleMessage(
            "Папку ще не підключено. Відкрийте klos → «Налаштування» → «Локальні файли» і виберіть папку з книгами. На Android 11+ саму Downloads вибрати не можна — виберіть підпапку, наприклад Download/Books."),
        "localFolderNotConnectedShort":
            MessageLookupByLibrary.simpleMessage("Доступ ще не надано"),
        "localFolderPickerFailed": m33,
        "localFolderReadFailed": m34,
        "localFolderRoot": MessageLookupByLibrary.simpleMessage("Корінь папки"),
        "localFolderUp": MessageLookupByLibrary.simpleMessage("↑ Вгору"),
        "localFolderWriteDenied": MessageLookupByLibrary.simpleMessage(
            "Немає дозволу на запис у папку. Виберіть папку ще раз на головному екрані."),
        "localFolderWriteFailed": m35,
        "localFormatNeedsDelivery": m36,
        "localServer": MessageLookupByLibrary.simpleMessage("Локальний сервер"),
        "log": MessageLookupByLibrary.simpleMessage("Журнал"),
        "logAppStarted":
            MessageLookupByLibrary.simpleMessage("Застосунок запущено"),
        "logEmpty": MessageLookupByLibrary.simpleMessage(
            "Тут з\'являться запити Kindle та завантаження."),
        "logMailApp": m37,
        "logPinBlocked": m38,
        "logPinChanged":
            MessageLookupByLibrary.simpleMessage("PIN-код оновлено"),
        "logPinFailed": m39,
        "logPinGranted": m40,
        "logPinRotated": MessageLookupByLibrary.simpleMessage(
            "PIN змінено після повторних невдалих спроб"),
        "logServerAutoStopped": MessageLookupByLibrary.simpleMessage(
            "Сервер зупинився сам через бездіяльність"),
        "logServerListening": m41,
        "logServerStarted": m42,
        "logServerStopped":
            MessageLookupByLibrary.simpleMessage("Сервер зупинено"),
        "logTestMailSent": m43,
        "mailAccepted": MessageLookupByLibrary.simpleMessage(
            "Лист прийнято поштовим сервером."),
        "mailAcceptedTo": m44,
        "mailAmazonHint": MessageLookupByLibrary.simpleMessage(
            "Amazon обробляє книгу окремо: вона з\'явиться в бібліотеці Kindle протягом кількох хвилин. Якщо адреса відправника не додана до списку дозволених у налаштуваннях Amazon, лист буде відхилено."),
        "mailAppFromZipLog": m45,
        "mailAppLog": m46,
        "mailBody": m47,
        "mailDownloadLog": m48,
        "mailDownloadingHint": MessageLookupByLibrary.simpleMessage(
            "Книга завантажується з OPDS-каталогу. Це може зайняти кілька хвилин."),
        "mailErrorLog": m49,
        "mailInProgress": MessageLookupByLibrary.simpleMessage("Надсилання…"),
        "mailNotConfigured": MessageLookupByLibrary.simpleMessage(
            "Пошту Kindle не налаштовано: вкажіть адресу Kindle, SMTP-сервер, адресу відправника та хоча б один формат."),
        "mailNotConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Пошту Kindle не налаштовано."),
        "mailPrepareErrorLog": m50,
        "mailQueuedLog": m51,
        "mailSendFailed": m52,
        "mailSendingHint": MessageLookupByLibrary.simpleMessage(
            "Лист передається SMTP-серверу. Не закривайте застосунок klos."),
        "mailSentLog": m53,
        "mailSkippedLog": MessageLookupByLibrary.simpleMessage(
            "Пошта: пропущено — пошту Kindle не налаштовано"),
        "mailStageDone": MessageLookupByLibrary.simpleMessage("Лист надіслано"),
        "mailStageDownloading":
            MessageLookupByLibrary.simpleMessage("Завантаження книги з OPDS…"),
        "mailStageFailed":
            MessageLookupByLibrary.simpleMessage("Не вдалося надіслати"),
        "mailStageQueued": MessageLookupByLibrary.simpleMessage("У черзі…"),
        "mailStageSending":
            MessageLookupByLibrary.simpleMessage("Надсилання листа на Kindle…"),
        "mailTooLarge": MessageLookupByLibrary.simpleMessage(
            "Файл більший за 25 МБ — Amazon не приймає такі листи. Спробуйте інший формат або завантажте книгу напряму."),
        "methodNotSupported": m54,
        "mobiTextTooLarge": MessageLookupByLibrary.simpleMessage(
            "Текст книги занадто великий для конвертації."),
        "nextPage": MessageLookupByLibrary.simpleMessage("Далі &gt;"),
        "nextPageSuffix":
            MessageLookupByLibrary.simpleMessage(", є наступна сторінка"),
        "noIpAddress": MessageLookupByLibrary.simpleMessage(
            "IP-адресу не знайдено. Перевірте, чи підключено Wi-Fi."),
        "notAnImage": MessageLookupByLibrary.simpleMessage(
            "OPDS-сервер повернув не зображення."),
        "notAtomFeed": MessageLookupByLibrary.simpleMessage(
            "отримано не Atom/OPDS-каталог"),
        "notConfiguredBody": MessageLookupByLibrary.simpleMessage(
            "OPDS-каталог не додано, і папку з книгами не вибрано."),
        "notConfiguredHelp": MessageLookupByLibrary.simpleMessage(
            "Відкрийте застосунок klos на телефоні, додайте адресу OPDS-сервера або виберіть папку з книгами та запустіть локальний сервер."),
        "notFoundHeading":
            MessageLookupByLibrary.simpleMessage("Сторінку не знайдено"),
        "notFoundHint": MessageLookupByLibrary.simpleMessage(
            "Можливо, посилання застаріле."),
        "notFoundTitle": MessageLookupByLibrary.simpleMessage("Не знайдено"),
        "notOpds2Feed": MessageLookupByLibrary.simpleMessage(
            "отримано не OPDS 2.0-каталог"),
        "notificationChannelDescription": MessageLookupByLibrary.simpleMessage(
            "Повідомлення про роботу OPDS-сервера для Kindle"),
        "notificationChannelName":
            MessageLookupByLibrary.simpleMessage("Локальний сервер"),
        "notificationRunning":
            MessageLookupByLibrary.simpleMessage("Сервер працює"),
        "notificationRunningPort": m55,
        "onlyHttpAddresses": MessageLookupByLibrary.simpleMessage(
            "Підтримуються лише адреси http:// та https://."),
        "opdsAccessDenied": m56,
        "opdsConnectFailed": m57,
        "opdsEmptyFile": MessageLookupByLibrary.simpleMessage(
            "OPDS-сервер повернув порожній файл."),
        "opdsHtmlInsteadOfFile": MessageLookupByLibrary.simpleMessage(
            "OPDS-сервер повернув HTML-сторінку замість файлу. Можливо, потрібен логін або доступ до цієї книги закритий."),
        "opdsHttpStatus": m58,
        "opdsParseFailed": m59,
        "opdsReadFailed": m60,
        "opdsResponseTooLarge": MessageLookupByLibrary.simpleMessage(
            "Відповідь OPDS-сервера завелика."),
        "opdsServer": MessageLookupByLibrary.simpleMessage("OPDS-сервер"),
        "opdsTimeout": MessageLookupByLibrary.simpleMessage(
            "OPDS-сервер не відповідає (таймаут)."),
        "openSearchLog": m61,
        "openSeries": MessageLookupByLibrary.simpleMessage("Відкрити серію"),
        "passwordOptional":
            MessageLookupByLibrary.simpleMessage("Пароль (необов\'язково)"),
        "pinBlocked": MessageLookupByLibrary.simpleMessage(
            "Забагато невдалих спроб. Зачекайте кілька хвилин і оновіть сторінку."),
        "pinCode": MessageLookupByLibrary.simpleMessage("PIN-код"),
        "pinHintOnKindle": MessageLookupByLibrary.simpleMessage(
            "Введіть цей код один раз у браузері Kindle. Kindle залишиться в системі до перезапуску сервера."),
        "pinPageHint": MessageLookupByLibrary.simpleMessage(
            "PIN-код захищає вашу бібліотеку від інших пристроїв у Wi-Fi мережі."),
        "pinPageIntro": MessageLookupByLibrary.simpleMessage(
            "Введіть PIN-код, який показано в застосунку klos на телефоні."),
        "pinPageTitle":
            MessageLookupByLibrary.simpleMessage("Потрібен PIN-код"),
        "pinProtection":
            MessageLookupByLibrary.simpleMessage("Захист PIN-кодом"),
        "pinProtectionHint": MessageLookupByLibrary.simpleMessage(
            "Питати PIN-код перед відкриттям каталогу на Kindle. Радитьмо, якщо до Wi-Fi мають доступ інші люди."),
        "pinRefresh": MessageLookupByLibrary.simpleMessage("Новий PIN"),
        "pinShort": MessageLookupByLibrary.simpleMessage("PIN"),
        "pinStartsWithServer": MessageLookupByLibrary.simpleMessage(
            "Код з\'явиться тут після запуску сервера."),
        "pinSubmit": MessageLookupByLibrary.simpleMessage("Увійти"),
        "pinWrong": MessageLookupByLibrary.simpleMessage(
            "Неправильний PIN. Спробуйте ще раз."),
        "port": MessageLookupByLibrary.simpleMessage("Порт"),
        "portHelper": MessageLookupByLibrary.simpleMessage(
            "Адреса для Kindle: http://IP-телефона:порт/"),
        "portInUse": m62,
        "prepareFileFailed": m63,
        "previousPage": MessageLookupByLibrary.simpleMessage("&lt; Назад"),
        "refresh": MessageLookupByLibrary.simpleMessage("Оновити"),
        "refreshAddresses":
            MessageLookupByLibrary.simpleMessage("Оновити IP-адреси"),
        "refreshStatus":
            MessageLookupByLibrary.simpleMessage("Оновити статус зараз"),
        "requestErrorLog": m64,
        "reset": MessageLookupByLibrary.simpleMessage("Скинути"),
        "resetFolder": MessageLookupByLibrary.simpleMessage("Скинути"),
        "retry": MessageLookupByLibrary.simpleMessage("Спробувати ще раз"),
        "save": MessageLookupByLibrary.simpleMessage("Зберегти"),
        "saveFailed": m65,
        "saveToFolderFailed": m66,
        "savedToFolder": m67,
        "saving": MessageLookupByLibrary.simpleMessage("Збереження..."),
        "searchButton": MessageLookupByLibrary.simpleMessage("Знайти"),
        "searchCatalog":
            MessageLookupByLibrary.simpleMessage("Пошук у каталозі"),
        "searchHint":
            MessageLookupByLibrary.simpleMessage("Назва книги або автор"),
        "searchResults":
            MessageLookupByLibrary.simpleMessage("Результати пошуку:"),
        "searchUrlFailed": MessageLookupByLibrary.simpleMessage(
            "Не вдалося побудувати адресу пошуку."),
        "securityInfo": MessageLookupByLibrary.simpleMessage(
            "Сервер слухає лише Wi-Fi мережу. Без захисту PIN-кодом каталог може відкрити будь-який пристрій у ній, тож користуйтеся довіреною мережею. Зміна порту перезапускає запущений сервер."),
        "sendByEmailTitle": MessageLookupByLibrary.simpleMessage("На пошту"),
        "sendTestMail":
            MessageLookupByLibrary.simpleMessage("Надіслати тестовий лист"),
        "sendUnavailable": MessageLookupByLibrary.simpleMessage(
            "Відправка листом недоступна в цій збірці застосунку."),
        "senderEmail":
            MessageLookupByLibrary.simpleMessage("Адреса відправника"),
        "senderEmailHelper": MessageLookupByLibrary.simpleMessage(
            "Має збігатися з адресою, доданою в Amazon як дозволений відправник."),
        "senderEmailHint":
            MessageLookupByLibrary.simpleMessage("your.address@gmail.com"),
        "sending": MessageLookupByLibrary.simpleMessage("Надсилання..."),
        "serverErrorLog": m68,
        "serverOfflineHint": MessageLookupByLibrary.simpleMessage(
            "Сервер зараз зупинений — Kindle не зможе підключитися, доки ви його не запустите."),
        "serverRunning": MessageLookupByLibrary.simpleMessage("Сервер працює"),
        "serverRunningHint": MessageLookupByLibrary.simpleMessage(
            "Kindle може підключитися до цього телефона."),
        "serverSettings":
            MessageLookupByLibrary.simpleMessage("Налаштування сервера"),
        "serverSettingsHint": MessageLookupByLibrary.simpleMessage(
            "Каталог, порт, папку й доставку на Kindle налаштовують на головному екрані."),
        "serverStartFailed": m69,
        "serverStopFailed": m70,
        "serverStopped":
            MessageLookupByLibrary.simpleMessage("Сервер зупинено"),
        "serverStoppedHint": MessageLookupByLibrary.simpleMessage(
            "Запустіть сервер, щоб Kindle міг завантажувати книги."),
        "settings": MessageLookupByLibrary.simpleMessage("Налаштування"),
        "settingsAutoSaveHint": MessageLookupByLibrary.simpleMessage(
            "Зміни зберігаються автоматично."),
        "settingsSaved":
            MessageLookupByLibrary.simpleMessage("Налаштування збережено"),
        "shareAndroidOnly": MessageLookupByLibrary.simpleMessage(
            "Відправка листом доступна лише в Android-збірці klos."),
        "shareBody": m71,
        "shareChooserTitle":
            MessageLookupByLibrary.simpleMessage("Надіслати книгу на Kindle"),
        "shareHint": MessageLookupByLibrary.simpleMessage(
            "Якщо поштова програма не з\'явилася, відкрийте klos на екрані телефону та повторіть. Файл тимчасово лежить у кеші застосунку."),
        "shareMissingArgs": MessageLookupByLibrary.simpleMessage(
            "Не вказано файл або адресу Kindle."),
        "shareMissingFile":
            MessageLookupByLibrary.simpleMessage("Файл книги не знайдено."),
        "shareOpenFailed": MessageLookupByLibrary.simpleMessage(
            "Не вдалося відкрити поштову програму."),
        "sharePrepared": MessageLookupByLibrary.simpleMessage(
            "На телефоні відкрито поштову програму. Вкладення вже додано — перевірте лист і надішліть його."),
        "sharePreparedTo": m72,
        "showCovers":
            MessageLookupByLibrary.simpleMessage("Показувати обкладинки"),
        "showCoversHint": MessageLookupByLibrary.simpleMessage(
            "Мініатюри книжок у каталозі. Вимкніть, якщо сторінки мають відкриватися швидше або без картинок."),
        "showPassword": MessageLookupByLibrary.simpleMessage("Показати пароль"),
        "smtpAuthRejected": MessageLookupByLibrary.simpleMessage(
            "SMTP-сервер відхилив логін або пароль. Для Gmail потрібен пароль застосунку, а не звичайний пароль."),
        "smtpCommunication": m73,
        "smtpConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Налаштовано — klos надсилає листи сам."),
        "smtpConnectFailed": m74,
        "smtpHost": MessageLookupByLibrary.simpleMessage("SMTP-сервер"),
        "smtpHostHelper": MessageLookupByLibrary.simpleMessage(
            "Наприклад: smtp.gmail.com, smtp.ukr.net"),
        "smtpHostHint": MessageLookupByLibrary.simpleMessage("smtp.gmail.com"),
        "smtpIntro": MessageLookupByLibrary.simpleMessage(
            "Заповніть, щоб klos надсилав листи сам. Без SMTP кнопка «на пошту» відкриватиме поштову програму на телефоні."),
        "smtpMessageRejected": MessageLookupByLibrary.simpleMessage(
            "Пошта відхилила лист: перевірте адреси Kindle і відправника."),
        "smtpNoGreeting": MessageLookupByLibrary.simpleMessage(
            "SMTP-сервер не відповів привітанням. Перевірте адресу й порт."),
        "smtpNoSecure": MessageLookupByLibrary.simpleMessage(
            "SMTP-сервер не підтримує захищене з\'єднання. Перевірте порт і перемикач SSL."),
        "smtpNotConfigured": MessageLookupByLibrary.simpleMessage(
            "SMTP не налаштовано — кнопка «на пошту» відкриватиме поштову програму на телефоні."),
        "smtpNotConfiguredShort": MessageLookupByLibrary.simpleMessage(
            "Не налаштовано — відкриється поштова програма."),
        "smtpOptional":
            MessageLookupByLibrary.simpleMessage("SMTP (необов\'язково)"),
        "smtpPassword": MessageLookupByLibrary.simpleMessage("SMTP-пароль"),
        "smtpPasswordHelper": MessageLookupByLibrary.simpleMessage(
            "Для Gmail — пароль застосунку. Зберігається лише на цьому пристрої."),
        "smtpPort": MessageLookupByLibrary.simpleMessage("SMTP-порт"),
        "smtpPortHelper":
            MessageLookupByLibrary.simpleMessage("587 — STARTTLS, 465 — SSL"),
        "smtpSsl":
            MessageLookupByLibrary.simpleMessage("SSL/TLS відразу (порт 465)"),
        "smtpSslHint": MessageLookupByLibrary.simpleMessage(
            "Увімкніть для порту 465. Для 587 зазвичай вимкнено: з\'єднання захищається через STARTTLS."),
        "smtpTimeout": MessageLookupByLibrary.simpleMessage(
            "SMTP-сервер не відповідає (таймаут)."),
        "smtpTls": MessageLookupByLibrary.simpleMessage(
            "Помилка TLS-з\'єднання з SMTP-сервером. Спробуйте інший порт (465 з SSL або 587 без SSL)."),
        "smtpUsername": MessageLookupByLibrary.simpleMessage("SMTP-логін"),
        "smtpUsernameHelper": MessageLookupByLibrary.simpleMessage(
            "Зазвичай це повна адреса пошти."),
        "source": MessageLookupByLibrary.simpleMessage("Джерело:"),
        "startServer": MessageLookupByLibrary.simpleMessage("Запустити сервер"),
        "stopAndExit": MessageLookupByLibrary.simpleMessage("Зупинити й вийти"),
        "stopServer": MessageLookupByLibrary.simpleMessage("Зупинити сервер"),
        "storedOnDevice": MessageLookupByLibrary.simpleMessage(
            "Зберігається лише на цьому пристрої."),
        "tagline": MessageLookupByLibrary.simpleMessage(
            "klos • локальний OPDS-міст для Kindle"),
        "testMailBody": MessageLookupByLibrary.simpleMessage(
            "Тестовий лист від klos.\n\nЯкщо Amazon прийняв лист, книга приходитиме на ваш Kindle."),
        "testMailFileContent": MessageLookupByLibrary.simpleMessage(
            "Це тестовий лист від klos.\nЯкщо ви бачите його на Kindle, пошта налаштована правильно.\n"),
        "testMailMissing": MessageLookupByLibrary.simpleMessage(
            "Заповніть адресу Kindle, SMTP-сервер, адресу відправника і виберіть хоча б один формат."),
        "testMailNotConfigured": MessageLookupByLibrary.simpleMessage(
            "Спочатку заповніть адресу Kindle, SMTP-сервер, адресу відправника і виберіть хоча б один формат."),
        "testMailSent": MessageLookupByLibrary.simpleMessage(
            "Тестовий лист передано SMTP-серверу. Перевірте Kindle за кілька хвилин."),
        "testMailSubject":
            MessageLookupByLibrary.simpleMessage("klos: перевірка пошти"),
        "theme": MessageLookupByLibrary.simpleMessage("Тема"),
        "themeDark": MessageLookupByLibrary.simpleMessage("Темна"),
        "themeHint": MessageLookupByLibrary.simpleMessage(
            "«Авто» бере тему з налаштувань телефона."),
        "themeLight": MessageLookupByLibrary.simpleMessage("Світла"),
        "themeSystem": MessageLookupByLibrary.simpleMessage("Авто"),
        "tlsError": m75,
        "tooLargeToEmail": MessageLookupByLibrary.simpleMessage(
            "Файл завеликий для відправки листом (понад 100 МБ)."),
        "unknownError":
            MessageLookupByLibrary.simpleMessage("Невідома помилка."),
        "untitled": MessageLookupByLibrary.simpleMessage("Без назви"),
        "updateAvailable": m76,
        "updateCheck":
            MessageLookupByLibrary.simpleMessage("Перевірити оновлення"),
        "updateChecking":
            MessageLookupByLibrary.simpleMessage("Перевіряємо оновлення…"),
        "updateDownload":
            MessageLookupByLibrary.simpleMessage("Завантажити й встановити"),
        "updateDownloading": m77,
        "updateErrorDownload":
            MessageLookupByLibrary.simpleMessage("Не вдалося завантажити APK."),
        "updateErrorGithub": m78,
        "updateErrorNetwork": m79,
        "updateErrorNoApk": MessageLookupByLibrary.simpleMessage(
            "У релізі немає APK для цього телефона."),
        "updateFailed": m80,
        "updateInstallFailed": m81,
        "updateInstallHint": MessageLookupByLibrary.simpleMessage(
            "Нова версія встановлюється поверх цієї, тож налаштування, обране й вибрана папка залишаються на місці."),
        "updateNone":
            MessageLookupByLibrary.simpleMessage("У вас остання версія."),
        "updateNotes": MessageLookupByLibrary.simpleMessage("Що нового"),
        "usernameOptional":
            MessageLookupByLibrary.simpleMessage("Логін (необов\'язково)"),
        "validateCatalogRequired": MessageLookupByLibrary.simpleMessage(
            "Вкажіть адресу OPDS-каталогу"),
        "validateCatalogScheme": MessageLookupByLibrary.simpleMessage(
            "Адреса має починатися з http:// або https://"),
        "validateEmailInvalid":
            MessageLookupByLibrary.simpleMessage("Некоректна адреса пошти"),
        "validateEmailRequired":
            MessageLookupByLibrary.simpleMessage("Вкажіть адресу"),
        "validatePort": MessageLookupByLibrary.simpleMessage(
            "Порт має бути від 1024 до 65535"),
        "validateSmtpHost": MessageLookupByLibrary.simpleMessage(
            "Вкажіть лише адресу сервера, наприклад smtp.gmail.com"),
        "validateSmtpPort": MessageLookupByLibrary.simpleMessage(
            "Порт має бути від 1 до 65535"),
        "webHelpActions": MessageLookupByLibrary.simpleMessage(
            "«на пошту» — на адресу Kindle; «завантажити» для EPUB/FB2 створює MOBI на телефоні — експериментально, складна верстка спрощується. Кнопка «на пошту» з\'являється лише для форматів, які приймає Amazon (EPUB, PDF, TXT, DOC/DOCX, RTF, HTML). Якщо SMTP налаштовано, лист надсилається автоматично; інакше відкриється поштовий застосунок на телефоні з готовим вкладенням. Решта форматів завантажується як звичайний файл; ZIP-архів klos розпаковує сам і бере з нього файл, придатний для Kindle або Amazon."),
        "webHelpFavorites": MessageLookupByLibrary.simpleMessage(
            "Обране — це книги, які ви зберегли в застосунку klos. Відкрийте «Бібліотека» → «Переглянути каталог», натисніть закладку біля потрібної книги — і вона з\'явиться у «Обраному», зокрема в браузері Kindle, з тими самими кнопками «завантажити» й «на пошту»."),
        "webHelpFormats": MessageLookupByLibrary.simpleMessage(
            "Якщо формат не відкривається, спробуйте MOBI або AZW3. ZIP-архів klos розпаковує автоматично: для Kindle бере MOBI, AZW3, AZW, PDF або TXT, для пошти — EPUB, PDF, TXT, RTF, DOC/DOCX чи HTML, а для конвертації — EPUB. Якщо всередині лише FB2 чи CBZ, klos так і скаже."),
        "webHelpHeading":
            MessageLookupByLibrary.simpleMessage("Як завантажити книгу"),
        "webHelpLimits": MessageLookupByLibrary.simpleMessage(
            "Конвертація спрощує складну верстку й не працює з DRM. Відправка через поштову програму працює, лише коли застосунок klos відкрито на телефоні: файл тимчасово зберігається в кеші застосунку."),
        "webHelpPrivacy": MessageLookupByLibrary.simpleMessage(
            "Книги не зберігаються на телефоні постійно: сервер лише передає їх з OPDS-каталогу на Kindle. Телефон має бути поруч і підключений до тієї ж мережі. Поки сервер увімкнений, у шторці Android видно повідомлення."),
        "webHelpSearch": MessageLookupByLibrary.simpleMessage(
            "Якщо в каталозі є поле <b>Знайти</b>, пошук працює прямо з Kindle: введіть автора або назву книги."),
        "webHelpStep1": MessageLookupByLibrary.simpleMessage(
            "Підключіть Kindle і телефон до однієї Wi-Fi мережі."),
        "webHelpStep2": MessageLookupByLibrary.simpleMessage(
            "На Kindle відкрийте <b>Experimental Browser</b> (Експериментальний браузер)."),
        "webHelpStep3": m82,
        "webHelpStep4": MessageLookupByLibrary.simpleMessage(
            "Виберіть книгу та формат. Позначка <b>(завантажити)</b> збереже файл на Kindle, <b>(на пошту)</b> надішле його на адресу Kindle — автоматично через SMTP, якщо він налаштований, або через поштову програму на телефоні, а <b>(конвертувати)</b> створить MOBI на телефоні."),
        "webHelpStep5": MessageLookupByLibrary.simpleMessage(
            "Файл з\'явиться у бібліотеці Kindle або в теці <b>Documents</b>."),
        "zipBroken": MessageLookupByLibrary.simpleMessage(
            "ZIP-архів пошкоджений або захищений паролем і не відкривається."),
        "zipEmptyFile": m83,
        "zipFound": m84,
        "zipNoConvertible": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві немає EPUB або FB2, тому конвертувати нічого."),
        "zipNoEmailFile": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві немає файлу, який приймає Amazon (EPUB, PDF, TXT, RTF, DOC/DOCX або HTML)."),
        "zipNoKindleFile": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві немає файлу, який Kindle відкриває напряму (MOBI, AZW3, AZW, PDF або TXT)."),
        "zipNoUsableFiles": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві немає придатних файлів."),
        "zipOnlyEpub": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві лише EPUB. klos перетворює його на MOBI під час завантаження."),
        "zipOnlyFb2": MessageLookupByLibrary.simpleMessage(
            "У ZIP-архіві лише FB2. klos перетворює його на MOBI під час завантаження."),
        "zipTooLarge": m85,
        "zipTooManyEntries": MessageLookupByLibrary.simpleMessage(
            "ZIP-архів містить забагато файлів."),
        "zipUnknownFormat": m86,
        "zipUnpackFailed": m87
      };
}
