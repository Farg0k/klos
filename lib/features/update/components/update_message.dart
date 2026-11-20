import '../../../generated/l10n.dart';
import '../../../platform/app_update.dart';

/// Turns an [UpdateException] into a message in the current language.
///
/// The service reports codes so it has no dependency on the UI; the screens
/// share this one place to render them.
String describeUpdateError(UpdateException error, S s) {
  switch (error.problem) {
    case UpdateProblem.github:
      final status = int.tryParse(error.detail);
      if (status != null) return s.updateErrorGithub(status);
      return s.updateFailed(error.detail);
    case UpdateProblem.network:
      return s.updateErrorNetwork(error.detail);
    case UpdateProblem.noApk:
      return s.updateErrorNoApk;
    case UpdateProblem.download:
      return s.updateErrorDownload;
    case UpdateProblem.unknownVersion:
      return s.updateFailed(s.unknownError);
  }
}
