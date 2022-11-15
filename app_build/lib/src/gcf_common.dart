import 'build_common.dart';

/// Serve functions.
String gcfNodePackageServeFunctionsCommand(
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions}) {
  return 'firebase${gcfNodePackageFirebaseArgProjectId(projectId)} serve --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}';
}

String gcfNodePackageDeployFunctionsCommand(
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions}) {
  return 'firebase${gcfNodePackageFirebaseArgProjectId(projectId)} deploy --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}';
}

String gcfNodePackageFirebaseArgProjectId(String? projectId) =>
    projectId == null ? '' : ' --project $projectId';

const gcfDeployDirDefault = 'deploy/firebase/hosting';

/// Google cloud node function options.
class GcfNodeAppOptions extends NodeAppOptions {
  final String projectId;
  final List<String>? functions;

  /// Optional IP port (5000)
  final int? port;
  GcfNodeAppOptions(
      {required this.projectId,
      String? packageTop,
      String? deployDir,
      String? srcDir,
      this.port,
      this.functions})
      : super(
            packageTop: packageTop,
            deployDir: deployDir ?? gcfDeployDirDefault,
            srcDir: srcDir);
}
