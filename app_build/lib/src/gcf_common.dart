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
