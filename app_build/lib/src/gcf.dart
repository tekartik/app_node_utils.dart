// Duplicate to dev_test
// This is the reference code
import 'dart:io';

import 'package:process_run/shell_run.dart';
import 'package:tekartik_app_node_build/src/run.dart';

Future gcfNodeBuildAndServe({String directory = 'bin'}) async {
  await nodeBuild(directory: directory);
  await gcfNodeCopyToDeploy(directory: directory);
  await gcfNodeServe(directory: directory);
}

Future gcfNodeServe({String directory = 'deploy'}) async {
  var shell = Shell(workingDirectory: directory);
  await shell.run('firebase serve');
}

/// Convert main.dart to index.js
Future gcfNodeCopyToDeploy(
    {String directory = 'bin', String dstDir = 'deploy'}) async {
  var src = File('build/$directory/main.dart.js');
  Future copy() async {
    var file = await src.copy('$dstDir/functions/index.js');
    print('copied to ${file} ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(dstDir).create(recursive: true);
    await copy();
  }
}
