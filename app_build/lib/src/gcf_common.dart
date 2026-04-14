import 'build_common.dart';

/// Serve functions.
/// Builds the Firebase emulators command used to serve selected functions.
String gcfNodePackageServeFunctionsCommand({
  String deployDirectory = 'deploy',
  String? projectId,
  List<String>? functions,
  int? port,
}) {
  return 'firebase${gcfNodePackageFirebaseArgProjectId(projectId)} emulators:start'
      ' --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}'
      '${port == null ? '' : ' -p $port'}';
}

/// Builds the Firebase deploy command used to deploy selected functions.
String gcfNodePackageDeployFunctionsCommand({
  String deployDirectory = 'deploy',
  String? projectId,
  List<String>? functions,
}) {
  return 'firebase${gcfNodePackageFirebaseArgProjectId(projectId)} deploy --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}';
}

/// Returns the optional Firebase CLI project argument.
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

  /// Restricts operations to the listed function names.
  final List<String>? functions;

  /// Optional IP port (5001)
  final int? port;

  /// Optional region for setting artifact policy
  final String? region;

  /// Creates Google Cloud Function node app options.
  GcfNodeAppOptions({
    this.projectId,
    super.packageTop,
    String? deployDir,
    super.srcDir,
    super.srcFile,
    this.port,
    this.functions,
    this.region,
  }) : super(deployDir: deployDir ?? gcfNodeAppDeployDirDefault);

  /// Returns a copy of these options with the provided overrides.
  GcfNodeAppOptions copyWith({
    String? projectId,
    List<String>? functions,
    String? srcFile,
    String? packageTop,
    String? srcDir,
    String? deployDir,
    int? port,
    String? region,
  }) {
    return GcfNodeAppOptions(
      projectId: projectId ?? this.projectId,
      functions: functions ?? this.functions,
      port: port ?? this.port,
      region: region ?? this.region,
      packageTop: packageTop ?? this.packageTop,
      deployDir: deployDir ?? this.deployDir,
      srcDir: srcDir ?? this.srcDir,
      srcFile: srcFile ?? this.srcFile,
    );
  }
}
