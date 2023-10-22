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

/// Hosting only
const gcfDeployDirDefault = 'deploy/firebase/hosting';

/// Typically we only have this.
const gcfNodeAppDeployDirDefault = 'deploy';

/// Google cloud node function options.
class GcfNodeAppOptions extends NodeAppOptions {
  /// Recommended.
  final String? projectId;
  final List<String>? functions;

  /// Optional IP port (5000)
  final int? port;
  GcfNodeAppOptions(
      {this.projectId,
      super.packageTop,
      String? deployDir,
      super.srcDir,
      this.port,
      this.functions})
      : super(deployDir: deployDir ?? gcfNodeAppDeployDirDefault);
}
