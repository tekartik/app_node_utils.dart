/// Aliyun function compute
import 'dart:io';

import 'package:process_run/shell_run.dart';
import 'package:tekartik_app_node_build/src/run.dart';

/// Compile bin/main.dart to deploy/functions/index.js
Future afcNodeBuild(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await nodeBuild(directory: directory);
  await afcNodeCopyToDeploy(
      directory: directory, deployDirectory: deployDirectory);
}

Future afcNodeServe({String directory = 'deploy'}) async {
  var shell = Shell(workingDirectory: directory);
  await shell.run('firebase serve');
}

/// Convert main.dart to index.js
Future afcNodeCopyToDeploy(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  var src = File('build/$directory/main.dart.js');
  Future copy() async {
    var file = await src.copy('$deployDirectory/index.js');
    print('copied to ${file} ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(deployDirectory).create(recursive: true);
    await copy();
  }
}
