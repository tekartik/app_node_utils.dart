// Duplicate to dev_test
// This is the reference code
import 'dart:io';

import 'package:process_run/shell_run.dart';
import 'package:tekartik_build_node/build_node.dart' as build;

import 'copy_to_deploy.dart';
import 'node_support.dart';

bool _checked = false;

/// Validates the current package before running node-related commands.
Future nodeCheck() async {
  if (!_checked) {
    _checked = true;
    if (!(File('build.yaml').existsSync())) {
      stderr.writeln('Missing \'build.yaml\'');
    }
  }
}

/// Builds the node target for the given source directory.
Future nodeBuild({String directory = 'bin'}) async {
  await nodeCheck();
  await build.nodeBuild(directory: directory);
}

/*
Future nodePackageBuild({String directory = 'bin'}) async {
  await nodeCheck();
  await build.nodeBuild(directory: directory);
}*/

/// Builds the node target, copies it to deploy, and runs it.
Future nodeBuildAndRun({String directory = 'bin'}) async {
  await nodeBuild(directory: directory);
  await nodeCopyToDeploy(directory: directory);
  await nodeRun(directory: directory);
}

/// Runs the generated deploy entrypoint with Node.js.
Future nodeRun({String directory = 'bin'}) async {
  var shell = Shell();
  await shell.run('''
node deploy/index.js
  ''');
}

/// Runs the package tests on the Node.js platform.
Future nodeRunTest() async {
  await nodeCheck();
  await nodeTestCheck('.');
  var shell = Shell();
  await shell.run('dart pub run test -p node');
}
