// Firebase cloud function
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:tekartik_build_node/build_node.dart';

/// Compile bin/main.dart to deploy/functions/index.js
Future gcfNodeBuildAndServe(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await gcfNodePackageBuildAndServe('.',
      directory: directory, deployDirectory: deployDirectory);
}

Future gcfNodePackageBuildAndServe(String path,
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await gcfNodePackageBuild(path,
      directory: directory, deployDirectory: deployDirectory);
  await gcfNodePackageServe(path, directory: deployDirectory);
}

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

Future gcfNodeServe({String directory = 'deploy'}) async {
  await gcfNodePackageServe('.', directory: directory);
}

Future gcfNodePackageServe(String path, {String directory = 'deploy'}) async {
  await gcfNodePackageNpmInstall(path);
  var shell = Shell(workingDirectory: join(path, directory));
  await shell.run('firebase serve');
}

/// Deploy functions.
Future<void> gcfNodePackageDeployFunctions(String path,
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(
      'firebase ${projectId == null ? '' : '--project $projectId'} deploy --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}');
}

/// Serve functions.
Future<void> gcfNodePackageServeFunctions(String path,
    {String deployDirectory = 'deploy',
    String? projectId,
    List<String>? functions}) async {
  var shell = Shell(workingDirectory: join(path, deployDirectory));

  await shell.run(
      'firebase${projectId == null ? '' : '--project $projectId'} serve --only ${functions == null ? 'functions' : functions.map((e) => 'functions:$e').join(',')}');
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
  Future copy() async {
    var file =
        await src.copy(join(path, '$deployDirectory/functions/index.js'));
    print('copied to $file ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(deployDirectory).create(recursive: true);
    await copy();
  }
}
