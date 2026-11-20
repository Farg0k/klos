import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:github_release_apk_updater/github_release_apk_updater.dart';

/// What went wrong while looking for or installing an update.
///
/// The service throws codes instead of ready messages, so the screen can
/// translate them and the tests do not depend on a language.
enum UpdateProblem {
  /// GitHub answered with an error status or unusable data.
  github,

  /// The network request failed or timed out.
  network,

  /// The release has no APK this phone can install.
  noApk,

  /// The APK could not be saved on the phone.
  download,

  /// The installed version is unknown, so nothing can be compared.
  unknownVersion,
}

class UpdateException implements Exception {
  UpdateException(this.problem, [this.detail = '']);

  final UpdateProblem problem;

  /// Raw server or system text, for logs and for the message tail.
  final String detail;

  @override
  String toString() => 'UpdateException(${problem.name}): $detail';
}

/// A newer release of klos published on GitHub.
@immutable
class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.downloadUrl,
    required this.assetName,
    this.notes = '',
  });

  /// Version without the leading `v`, for example `1.0.1`.
  final String version;

  /// Direct download link of the APK.
  final String downloadUrl;

  /// Name of the APK file in the release, for example
  /// `app-arm64-v8a-release.apk`.
  final String assetName;

  /// Release notes written on GitHub.
  final String notes;
}

/// Progress of an APK download, as a percentage.
typedef UpdateProgress = void Function(int percent);

/// Checks GitHub Releases for a newer klos and installs it.
///
/// The APKs are signed with the same key as the installed app, so Android
/// updates it in place and keeps the settings, the favorites and the chosen
/// folder instead of installing a second copy.
class AppUpdateService {
  AppUpdateService({
    this.owner = 'Farg0k',
    this.repository = 'klos',
    this.fetchRelease,
    this.abisProvider,
    ApkDownloaderService? downloader,
    GithubReleaseApkUpdater? installer,
  }) : _downloader = downloader ?? ApkDownloaderService(),
       _installer = installer ?? GithubReleaseApkUpdater();

  final String owner;
  final String repository;

  /// Replaces the GitHub request; tests use it to stay offline.
  final ReleaseFetcher? fetchRelease;

  /// Replaces the platform ABI lookup, which needs a real Android runtime.
  final AbisProvider? abisProvider;
  final ApkDownloaderService _downloader;
  final GithubReleaseApkUpdater _installer;

  /// Returns the newer release, or null when the installed version is current.
  ///
  /// [currentVersion] comes from the installed package; [abis] decides which
  /// split APK is downloaded, so the phone takes the smallest one it can run.
  Future<AppUpdate?> check({
    required String currentVersion,
    List<String> abis = const [],
  }) async {
    final current = currentVersion.trim();
    if (current.isEmpty) {
      throw UpdateException(UpdateProblem.unknownVersion);
    }
    final release = await (fetchRelease ?? _readLatestRelease)();
    return parseRelease(release, abis: abis, currentVersion: current);
  }

  /// Downloads [update] into the app storage and returns the file path.
  Future<String> download(
    AppUpdate update, {
    UpdateProgress? onProgress,
  }) async {
    final path = await _downloader.downloadAPK(update.downloadUrl, null, (
      received,
      total,
    ) {
      if (onProgress == null || total <= 0) return;
      onProgress((received * 100 ~/ total).clamp(0, 100));
    });
    if (path == null || path.isEmpty) {
      throw UpdateException(UpdateProblem.download);
    }
    return path;
  }

  /// Opens the Android installer for the downloaded APK.
  Future<void> install(String path) => _installer.installApk(path);

  /// ABIs of this phone, most preferred first.
  Future<List<String>> deviceAbis() async {
    final provider = abisProvider;
    if (provider != null) return normalizeAbis(await provider());
    try {
      final abis = await _installer.getSupportedAbis();
      return abis == null ? const [] : normalizeAbis(abis);
    } catch (error) {
      // Without the platform answer the universal APK is used.
      debugPrint('ABI lookup failed: $error');
      return const [];
    }
  }

  /// Reads the newest release from the GitHub API.
  Future<Map<String, dynamic>?> _readLatestRelease() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = 'klos/1.0';
    final url = Uri.parse(
      'https://api.github.com/repos/$owner/$repository/releases/latest',
    );
    try {
      final request = await client
          .getUrl(url)
          .timeout(const Duration(seconds: 20));
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateException(UpdateProblem.github, '${response.statusCode}');
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw UpdateException(UpdateProblem.github, 'unexpected data');
      }
      return decoded;
    } on TimeoutException catch (error) {
      throw UpdateException(UpdateProblem.network, error.message ?? 'timeout');
    } on SocketException catch (error) {
      throw UpdateException(UpdateProblem.network, error.message);
    } on HandshakeException catch (error) {
      throw UpdateException(UpdateProblem.network, error.message);
    } on FormatException catch (error) {
      throw UpdateException(UpdateProblem.github, error.message);
    } finally {
      client.close(force: true);
    }
  }

  /// Picks the APK for this phone and compares it with [currentVersion].
  ///
  /// Pure, so the asset choice and the version check can be tested without the
  /// network. Every release also carries a universal APK without an ABI in its
  /// name, which is used when no split APK matches. A null [json] means the
  /// repository has no published release yet.
  @visibleForTesting
  static AppUpdate? parseRelease(
    Map<String, dynamic>? json, {
    required List<String> abis,
    required String currentVersion,
  }) {
    if (json == null) return null;
    final tag = (json['tag_name'] as String? ?? '').trim();
    if (tag.isEmpty) return null;
    final version = tag.startsWith('v') ? tag.substring(1) : tag;

    // The version is compared before the asset is looked up: an old release
    // without an APK is still simply "no update", not an error.
    if (!VersionComparator().isNewerVersion(version, currentVersion)) {
      return null;
    }

    final assets = (json['assets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final apk = _pickAsset(assets, abis);
    if (apk == null) {
      throw UpdateException(UpdateProblem.noApk);
    }

    return AppUpdate(
      version: version,
      downloadUrl: apk['browser_download_url'] as String? ?? '',
      assetName: apk['name'] as String? ?? '',
      notes: (json['body'] as String? ?? '').trim(),
    );
  }

  static const List<String> _knownAbis = [
    'arm64-v8a',
    'armeabi-v7a',
    'armeabi',
    'x86_64',
    'x86',
  ];

  /// ABI-specific APK first, then the universal one.
  static Map<String, dynamic>? _pickAsset(
    List<Map<String, dynamic>> assets,
    List<String> abis,
  ) {
    final apks = assets
        .where((asset) => (asset['name'] as String? ?? '').endsWith('.apk'))
        .toList();
    if (apks.isEmpty) return null;
    for (final abi in normalizeAbis(abis)) {
      for (final apk in apks) {
        if ((apk['name'] as String).contains(abi)) return apk;
      }
    }
    for (final apk in apks) {
      final name = apk['name'] as String;
      if (!_knownAbis.any(name.contains)) return apk;
    }
    return apks.first;
  }

  /// Keeps the ABIs in the order the platform reported them.
  @visibleForTesting
  static List<String> normalizeAbis(List<String> abis) {
    final result = <String>[];
    for (final abi in abis) {
      final name = abi.trim();
      if (name.isNotEmpty && !result.contains(name)) result.add(name);
    }
    return result;
  }
}

/// Reads the newest release from the GitHub API.
typedef ReleaseFetcher = Future<Map<String, dynamic>?> Function();

/// Lists the ABIs of this phone, most preferred first.
typedef AbisProvider = Future<List<String>> Function();
