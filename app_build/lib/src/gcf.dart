// Firebase cloud function
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/shell_run.dart';
import 'package:tekartik_app_node_build/app_build.dart';

import 'gcf_common.dart';

/// Compile bin/main.dart to deploy/functions/index.js
Future gcfNodeBuildAndServe(
    {String directory = 'bin',
    String deployDirectory = 'deploy',
    String? projectId}) async {
  await gcfNodePackageBuildAndServe('.',
      directory: directory,
      deployDirectory: deployDirectory,
      projectId: projectId);
}

Future gcfNodePackageBuildAndServe(String path,
    {String directory = 'bin',
    String deployDirectory = 'deploy',
    String? projectId,
    int? port}) async {
  await gcfNodePackageBuild(path,
      directory: directory, deployDirectory: deployDirectory);
  await gcfNodePackageServe(path,
      directory: deployDirectory, projectId: projectId, port: port);
}

@Deprecated('Use gcfNodePackageBuild')
Future gcfNodeBuild(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await gcfNodePackageBuild('.',
      directory: directory, deployDirectory: deployDirectory);
}

Future gcfNodePackageBuild(String path,
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await nodePackageBuild(path, directory: directory);
  await gcfNodePackageCopyToDeploy(path,
      directory: directory, deployDirectory: deployDirectory);
}

Future gcfNodePackageNpmInstall(String path,
    {bool force = false, String deployDirectory = 'deploy'}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(join(path, deployDirectory, 'functions', 'package.json'))
      .existsSync())) {
    if (force ||
        !(Directory(join(path, deployDirectory, 'functions', 'node_modules'))
            .existsSync())) {
      await Shell(workingDirectory: join(path, deployDirectory, 'functions'))
          .run('npm install');
    }
  }
}

Future gcfNodePackageNpmUpgrade(String path,
    {String deployDirectory = 'deploy'}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(join(path, deployDirectory, 'functions', 'package.json'))
      .existsSync())) {
    await Shell(workingDirectory: join(path, deployDirectory, 'functions'))
        .run('npm install --save firebase-functions@latest');
  }
}

Future gcfNodePackageNpmUpgradeFirebaseAdmin(String path,
    {String deployDirectory = 'deploy'}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(join(path, deployDirectory, 'functions', 'package.json'))
      .existsSync())) {
    await Shell(workingDirectory: join(path, deployDirectory, 'functions'))
        .run('npm install --save firebase-admin@latest');
  }
}

Future gcfNodeServe({String directory = 'deploy', String? projectId}) async {
  await gcfNodePackageServe('.', directory: directory);
}

Future gcfNodePackageServe(String path,
    {String directory = 'deploy', String? projectId, int? port}) async {
  await gcfNodePackageNpmInstall(path);
  var shell = Shell(workingDirectory: join(path, directory));
  await shell
      .run('firebase serve${gcfNodePackageFirebaseArgProjectId(projectId)}'
          '${port == null ? '' : ' -p $port'}');
}

/// Deploy functions.
Future<void> gcfNodePackageDeployFunctions(String path,
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(gcfNodePackageDeployFunctionsCommand(
      deployDirectory: deployDirectory,
      projectId: projectId,
      functions: functions));
}

/// Serve functions.
Future<void> gcfNodePackageServeFunctions(String path,
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions,
    int? port}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(gcfNodePackageServeFunctionsCommand(
      deployDirectory: deployDirectory,
      projectId: projectId,
      functions: functions,
      port: port));
}

// Bad name and implementation - to delete 2021-04-19
@Deprecated('Misnamed since this actually serve')
Future gcfNodeCreate({String directory = 'deploy'}) async {
  var shell = Shell(workingDirectory: directory);
  await shell.run('firebase serve');
}

/// Convert main.dart to index.js
Future gcfNodeCopyToDeploy(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await gcfNodePackageCopyToDeploy('.',
      directory: directory, deployDirectory: deployDirectory);
}

/// Convert main.dart to index.js
Future gcfNodePackageCopyToDeploy(String path,
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  var src = File(join(path, 'build', directory, 'main.dart.js'));
  var dstDir = join(path, deployDirectory, 'functions');
  Future copy() async {
    var file = await src.copy(join(dstDir, 'index.js'));
    print('copied to $file ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(dstDir).create(recursive: true);
    await copy();
  }
}

String getDefaultProjectId() {
  return ShellEnvironment().vars['TEKARTIK_FIREBASE_PROJECT_ID'] ??
      '-unset-project-id-';
}

/// New builder helper
class GcfNodeAppBuilder {
  final String? target;
  late final GcfNodeAppOptions options;

  GcfNodeAppBuilder({GcfNodeAppOptions? options, this.target}) {
    this.options =
        options ?? GcfNodeAppOptions(projectId: getDefaultProjectId());
  }

  Future<void> build() async {
    await gcfNodePackageBuild(options.packageTop,
        directory: options.srcDir, deployDirectory: options.deployDir);
  }

  Future<void> copyToDeploy() async {
    await gcfNodePackageCopyToDeploy(options.packageTop,
        directory: options.srcDir, deployDirectory: options.deployDir);
  }

  Future<void> serveFunctions({List<String>? functions}) async {
    await gcfNodePackageServeFunctions(options.packageTop,
        deployDirectory: options.deployDir,
        projectId: options.projectId,
        port: options.port,
        functions: functions ?? options.functions);
  }

  Future<void> serve() async {
    await gcfNodePackageServe(
      options.packageTop,
      directory: options.deployDir,
      projectId: options.projectId,
      port: options.port,
    );
  }

  Future<void> buildAndServe() async {
    await gcfNodePackageBuildAndServe(options.packageTop,
        directory: options.srcDir,
        deployDirectory: options.deployDir,
        projectId: options.projectId,
        port: options.port);
  }

  Future<void> buildAndServeFunctions({List<String>? functions}) async {
    await build();
    await serveFunctions(functions: functions);
  }

  Future<void> clean() async {
    await nodePackageClean(options.packageTop);
  }

  Future<void> buildAndDeployFunctions({List<String>? functions}) async {
    await build();
    await deployFunctions(functions: functions);
  }

  Future<void> deployFunctions({List<String>? functions}) async {
    await gcfNodePackageDeployFunctions(options.packageTop,
        projectId: options.projectId,
        deployDirectory: options.deployDir,
        functions: functions ?? options.functions);
  }

  Future<void> npmInstall() async {
    await gcfNodePackageNpmInstall(options.packageTop,
        deployDirectory: options.deployDir);
  }

  Future<void> npmUpgrade() async {
    await gcfNodePackageNpmUpgrade(options.packageTop,
        deployDirectory: options.deployDir);
  }

  Future<void> npmUpgradeFirebaseAdmin() async {
    await gcfNodePackageNpmUpgradeFirebaseAdmin(options.packageTop,
        deployDirectory: options.deployDir);
  }
}
