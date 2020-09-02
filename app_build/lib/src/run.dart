import 'dart:io';

import 'package:process_run/shell_run.dart';

import 'copy_to_deploy.dart';

bool _checked = false;

Future nodeCheck() async {
  if (!_checked) {
    _checked = true;
    if (!(await File('build.yaml').exists())) {
      stderr.writeln('Missing \'build.yaml\'');
    }
  }
}

Future nodeBuild({String directory = 'bin'}) async {
  await nodeCheck();
  var shell = Shell();
  await shell.run('''
# pub run build_runner build --output=$directory:build/$directory -- -p node
pub run build_runner build --output=build/ -- -p node
''');
}

Future nodeBuildAndRun({String directory = 'bin'}) async {
  await nodeBuild(directory: directory);
  await nodeCopyToDeploy(directory: directory);
  await nodeRun(directory: directory);
}

Future nodeRun({String directory = 'bin'}) async {
  var shell = Shell();
  await shell.run('''
node deploy/index.js
  ''');
}

bool _testChecked = false;

Future nodeTestCheck() async {
  if (!_testChecked) {
    _testChecked = true;
    if ((await File('package.json').exists())) {
      if (!(await Directory('node_modules').exists())) {
        await run('npm install');
      }
    }
  }
}

Future nodeRunTest() async {
  await nodeCheck();
  await nodeTestCheck();
  var shell = Shell();
  await shell.run('pub run test -p node');
}
