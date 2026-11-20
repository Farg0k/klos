import 'package:flutter_test/flutter_test.dart';
import 'package:klos/features/update/bloc/update_bloc.dart';
import 'package:klos/platform/app_info.dart';
import 'package:klos/platform/app_update.dart';

Map<String, dynamic> _release(String tag, {String body = 'Notes'}) => {
  'tag_name': tag,
  'body': body,
  'assets': [
    {
      'name': 'app-arm64-v8a-release.apk',
      'browser_download_url':
          'https://github.com/Farg0k/klos/releases/download/$tag/app.apk',
    },
  ],
};

UpdateBloc _bloc(
  Future<Map<String, dynamic>?> Function() release, {
  String installed = '1.0.0',
}) {
  final bloc = UpdateBloc(
    service: AppUpdateService(
      fetchRelease: release,
      abisProvider: () async => const ['arm64-v8a'],
    ),
    infoLoader: () async => AppInfo(version: installed),
  );
  addTearDown(bloc.close);
  return bloc;
}

/// Waits until the bloc settles on [status], so the test does not depend on
/// how many states the request goes through.
Future<UpdateState> _until(
  UpdateBloc bloc,
  bool Function(UpdateState state) test, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (test(bloc.state)) return bloc.state;
  return bloc.stream.firstWhere(test).timeout(timeout);
}

void main() {
  group('automatic check', () {
    test('finds a newer release on its own', () async {
      final bloc = _bloc(() async => _release('v1.1.0'));
      bloc.add(const UpdateStarted());

      final state = await _until(
        bloc,
        (state) => state.status == UpdateStatus.available,
      );

      expect(state.update!.version, '1.1.0');
      expect(state.showsBanner, isTrue);
    });

    test('stays silent when the installed version is current', () async {
      final bloc = _bloc(() async => _release('v1.0.0'));
      bloc.add(const UpdateStarted());

      final state = await _until(
        bloc,
        (state) =>
            state.status == UpdateStatus.upToDate ||
            state.status == UpdateStatus.failed,
      );

      expect(state.status, UpdateStatus.upToDate);
      expect(state.showsBanner, isFalse);
    });

    test('stays silent when GitHub cannot be reached', () async {
      final bloc = _bloc(
        () async => throw UpdateException(UpdateProblem.network, 'offline'),
      );
      bloc.add(const UpdateStarted());

      final state = await _until(
        bloc,
        (state) => state.status == UpdateStatus.failed,
      );

      expect(state.error!.problem, UpdateProblem.network);
      // The app keeps working offline; the home screen stays clean.
      expect(state.showsBanner, isFalse);
    });

    test('asks GitHub once per launch, not on every rebuild', () async {
      var calls = 0;
      final bloc = _bloc(() async {
        calls++;
        return _release('v1.1.0');
      });

      bloc.add(const UpdateStarted());
      await _until(bloc, (state) => state.status == UpdateStatus.available);

      bloc.add(const UpdateStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(calls, 1);
    });
  });

  group('manual check', () {
    test('reports the current version and reopens the banner', () async {
      final bloc = _bloc(() async => _release('v1.0.0'));
      bloc.add(const UpdateStarted());
      await _until(bloc, (state) => state.status == UpdateStatus.upToDate);

      bloc.add(const UpdateCheckRequested());
      final state = await _until(
        bloc,
        (state) => state.status == UpdateStatus.upToDate && !state.dismissed,
      );

      expect(state.showsBanner, isFalse);
      expect(state.dismissed, isFalse);
    });

    test('widens an error that the silent check kept quiet', () async {
      var attempt = 0;
      final bloc = _bloc(() async {
        attempt++;
        if (attempt == 1) {
          throw UpdateException(UpdateProblem.github, '500');
        }
        return _release('v2.0.0');
      });

      bloc.add(const UpdateStarted());
      await _until(bloc, (state) => state.status == UpdateStatus.failed);

      bloc.add(const UpdateCheckRequested());
      final state = await _until(
        bloc,
        (state) => state.status == UpdateStatus.available,
      );

      expect(state.update!.version, '2.0.0');
      expect(state.error, isNull);
      expect(state.showsBanner, isTrue);
    });
  });

  group('banner', () {
    test('stays hidden after it is dismissed', () async {
      final bloc = _bloc(() async => _release('v1.1.0'));
      bloc.add(const UpdateStarted());
      await _until(bloc, (state) => state.status == UpdateStatus.available);

      bloc.add(const UpdateDismissed());
      final state = await _until(bloc, (state) => state.dismissed);

      expect(state.showsBanner, isFalse);
      // The release is still known, so «About» keeps offering it.
      expect(state.update, isNotNull);
    });
  });

  group('install', () {
    test('ignores the request when nothing was found', () async {
      final bloc = _bloc(() async => null);
      bloc.add(const UpdateInstallRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.status, UpdateStatus.idle);
      expect(bloc.state.downloadPercent, isNull);
    });
  });
}
