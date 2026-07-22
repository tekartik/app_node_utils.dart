import 'package:path/path.dart' as p;
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:process_run/stdio.dart';
import 'package:tekartik_app_node_build/app_build.dart';
import 'package:tekartik_app_node_build/gcf_build.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'gcf_common.dart';

/// Compile bin/main.dart to deploy/functions/index.js
/// Builds the current package and starts the local Firebase emulator.
Future gcfNodeBuildAndServe({
  String directory = 'bin',
  String deployDirectory = 'deploy',
  String? projectId,
}) async {
  await gcfNodePackageBuildAndServe(
    '.',
    directory: directory,
    deployDirectory: deployDirectory,
    projectId: projectId,
  );
}

/// Builds a package and starts the local Firebase emulator.
Future gcfNodePackageBuildAndServe(
  String path, {
  String directory = 'bin',
  String deployDirectory = 'deploy',
  String? projectId,
  int? port,
}) async {
  await gcfNodePackageBuild(
    path,
    directory: directory,
    deployDirectory: deployDirectory,
  );
  await gcfNodePackageServe(
    path,
    directory: deployDirectory,
    projectId: projectId,
    port: port,
  );
}

/// Deprecated legacy GCF build entrypoint.
@Deprecated('Use gcfNodePackageBuild')
Future gcfNodeBuild({
  String directory = 'bin',
  String deployDirectory = 'deploy',
}) async {
  await gcfNodePackageBuild(
    '.',
    directory: directory,
    deployDirectory: deployDirectory,
  );
}

/// Compiles a package entrypoint and copies it to the functions deploy folder.
Future gcfNodePackageBuild(
  String path, {
  String directory = 'bin',
  String deployDirectory = 'deploy',

  /// Default to main.dart inside [directory]
  String? srcFile,
  bool? debug,
}) async {
  srcFile ??= 'main.dart';
  await nodePackageCompileJs(
    path,
    input: join(directory, srcFile),
    debug: debug,
  );

  await gcfNodePackageCopyToDeploy(
    path,
    directory: directory,
    deployDirectory: deployDirectory,
    jsSrcFile: '${basename(srcFile)}.js',
  );
}

/// Installs npm dependencies for the generated Firebase functions package.
Future gcfNodePackageNpmInstall(
  String path, {
  bool force = false,
  String deployDirectory = 'deploy',
}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(
    join(path, deployDirectory, 'functions', 'package.json'),
  ).existsSync())) {
    if (force ||
        !(Directory(
          join(path, deployDirectory, 'functions', 'node_modules'),
        ).existsSync())) {
      await Shell(
        workingDirectory: join(path, deployDirectory, 'functions'),
      ).run('npm install');
    }
  }
}

/// Upgrades `firebase-functions` in the generated Firebase functions package.
Future gcfNodePackageNpmUpgrade(
  String path, {
  String deployDirectory = 'deploy',
}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(
    join(path, deployDirectory, 'functions', 'package.json'),
  ).existsSync())) {
    await Shell(
      workingDirectory: join(path, deployDirectory, 'functions'),
    ).run('npm install --save firebase-functions@latest');
  }
}

/// Upgrades `firebase-admin` in the generated Firebase functions package.
Future gcfNodePackageNpmUpgradeFirebaseAdmin(
  String path, {
  String deployDirectory = 'deploy',
}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(
    join(path, deployDirectory, 'functions', 'package.json'),
  ).existsSync())) {
    await Shell(
      workingDirectory: join(path, deployDirectory, 'functions'),
    ).run('npm install --save firebase-admin@latest');
  }
}

/// Serves the current package with the Firebase CLI.
Future gcfNodeServe({String directory = 'deploy', String? projectId}) async {
  await gcfNodePackageServe('.', directory: directory);
}

/// Serves a built package with the Firebase CLI.
Future gcfNodePackageServe(
  String path, {
  String directory = 'deploy',
  String? projectId,
  int? port,
}) async {
  await gcfNodePackageNpmInstall(path);
  var shell = Shell(workingDirectory: join(path, directory));
  await shell.run(
    'firebase serve${gcfNodePackageFirebaseArgProjectId(projectId)}'
    '${port == null ? '' : ' -p $port'}',
  );
}

/// Deploy functions.
Future<void> gcfNodePackageDeployFunctions(
  String path, {
  String deployDirectory = 'deploy',
  String? projectId,
  List<String>? functions,
}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(
    gcfNodePackageDeployFunctionsCommand(
      deployDirectory: deployDirectory,
      projectId: projectId,
      functions: functions,
    ),
  );
}

/// Serve functions.
Future<void> gcfNodePackageServeFunctions(
  String path, {
  String deployDirectory = 'deploy',
  String? projectId,
  List<String>? functions,
  int? port,
}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(
    gcfNodePackageServeFunctionsCommand(
      deployDirectory: deployDirectory,
      projectId: projectId,
      functions: functions,
      port: port,
    ),
  );
}

/// Deprecated legacy serve entrypoint.
// Bad name and implementation - to delete 2021-04-19
@Deprecated('Misnamed since this actually serve')
Future gcfNodeCreate({String directory = 'deploy'}) async {
  var shell = Shell(workingDirectory: directory);
  await shell.run('firebase serve');
}

/// Convert main.dart to index.js
/// Copies the current package build output into the functions deploy folder.
Future gcfNodeCopyToDeploy({
  String directory = 'bin',
  String deployDirectory = 'deploy',
}) async {
  await gcfNodePackageCopyToDeploy(
    '.',
    directory: directory,
    deployDirectory: deployDirectory,
  );
}

/// Convert main.dart to index.js
/// Copies a package build output into the functions deploy folder.
Future gcfNodePackageCopyToDeploy(
  String path, {
  String directory = 'bin',
  String deployDirectory = 'deploy',
  String? jsSrcFile,
}) async {
  var src = File(join(path, 'build', directory, jsSrcFile ?? 'main.dart.js'));
  var dstDir = join(path, deployDirectory, 'functions');

  Future copy() async {
    var file = await src.copy(join(dstDir, 'index.js'));
    stdout.writeln('copied to $file ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(dstDir).create(recursive: true);

    await copy();
  }
}

/// Returns the default Firebase project id from the environment.
String getDefaultProjectId() {
  return ShellEnvironment().vars['TEKARTIK_FIREBASE_PROJECT_ID'] ??
      '-unset-project-id-';
}

/// New builder helper
class GcfNodeAppBuilder implements CommonAppBuilder {
  /// Optional generation target used by callers integrating with codegen.
  final String? target;

  /// Builder configuration.
  late final GcfNodeAppOptions options;

  /// Absolute path to the deploy directory.
  String get deployFullPath {
    if (p.isAbsolute(options.deployDir)) {
      return options.deployDir;
    } else {
      return join(options.packageTop, options.deployDir);
    }
  }

  /// Creates a builder with Google Cloud Function defaults.
  GcfNodeAppBuilder({GcfNodeAppOptions? options, this.target}) {
    this.options =
        options ?? GcfNodeAppOptions(projectId: getDefaultProjectId());
  }

  /// Builds the configured function package.
  Future<void> build() async {
    await generateVersionIfNeeded();
    await gcfNodePackageBuild(
      options.packageTop,
      directory: options.srcDir,
      deployDirectory: options.deployDir,
      srcFile: options.srcFile,
    );
  }

  /// Copies the compiled output to the deploy directory.
  Future<void> copyToDeploy() async {
    await gcfNodePackageCopyToDeploy(
      options.packageTop,
      directory: options.srcDir,
      deployDirectory: options.deployDir,
    );
  }

  /// Serves only the configured functions with the Firebase emulator.
  Future<void> serveFunctions({List<String>? functions}) async {
    await gcfNodePackageServeFunctions(
      options.packageTop,
      deployDirectory: options.deployDir,
      projectId: options.projectId,
      port: options.port,
      functions: functions ?? options.functions,
    );
  }

  /// Serves the full deploy directory with the Firebase CLI.
  Future<void> serve() async {
    await gcfNodePackageServe(
      options.packageTop,
      directory: options.deployDir,
      projectId: options.projectId,
      port: options.port,
    );
  }

  /// Builds the package and immediately starts the Firebase emulator.
  Future<void> buildAndServe() async {
    await gcfNodePackageBuildAndServe(
      options.packageTop,
      directory: options.srcDir,
      deployDirectory: options.deployDir,
      projectId: options.projectId,
      port: options.port,
    );
  }

  /// Builds the package and serves only the configured functions.
  Future<void> buildAndServeFunctions({List<String>? functions}) async {
    await build();

    await serveFunctions(functions: functions);
  }

  /// Removes generated build and deploy artifacts.
  Future<void> clean() async {
    await nodePackageClean(options.packageTop);
  }

  /// Builds the package and deploys the configured functions.
  Future<void> buildAndDeployFunctions({List<String>? functions}) async {
    await build();

    await deployFunctions(functions: functions);
  }

  /// Deploys the configured functions with the Firebase CLI.
  Future<void> deployFunctions({List<String>? functions}) async {
    await gcfNodePackageDeployFunctions(
      options.packageTop,
      projectId: options.projectId,
      deployDirectory: options.deployDir,
      functions: functions ?? options.functions,
    );
  }

  /// Installs npm dependencies for the generated functions package.
  Future<void> npmInstall() async {
    await gcfNodePackageNpmInstall(
      options.packageTop,
      deployDirectory: options.deployDir,
    );
  }

  /// Upgrades `firebase-functions` in the generated functions package.
  Future<void> npmUpgrade() async {
    await gcfNodePackageNpmUpgrade(
      options.packageTop,
      deployDirectory: options.deployDir,
    );
  }

  /// Upgrades `firebase-admin` in the generated functions package.
  Future<void> npmUpgradeFirebaseAdmin() async {
    await gcfNodePackageNpmUpgradeFirebaseAdmin(
      options.packageTop,
      deployDirectory: options.deployDir,
    );
  }

  @override
  /// Root package path for this builder.
  String get path => options.packageTop;
}
