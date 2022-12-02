import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:tekartik_app_node_build/app_build.dart';

@Deprecated('Use [nodePackageBuild] instead')
Future build({String directory = 'bin'}) async {
  var shell = Shell();
  await shell.run('''
# pub run build_runner build --output=$directory:build/$directory -- -p node
pub run build_runner build --output=build/ -- -p node
''');
  await nodeCopyToDeploy(directory: directory);
}

/// Regular node app
Future nodePackageRun(String path, {String? deployDirectory}) async {
  deployDirectory ??= 'deploy';
  var shell = Shell(workingDirectory: path);
  await shell.run('''
node ${shellArgument(join(deployDirectory, 'index.js'))}
  ''');
}

/// Clean node app
Future nodePackageClean(String path, {String? deployDirectory}) async {
  deployDirectory ??= 'deploy';
  print('deleting "build"');
  try {
    await Directory('build').delete(recursive: true);
  } catch (_) {}

  var indexJs = join(deployDirectory, 'index.js');
  print('deleting "$indexJs"');
  try {
    await File(indexJs).delete();
  } catch (_) {}
}

/// Convert main.dart to index.js
Future nodePackageCopyToDeploy(String path,
    {String? directory, String? deployDirectory}) async {
  directory ??= 'bin';
  deployDirectory ??= 'deploy';
  var src = File('build/$directory/main.dart.js');
  Future copy() async {
    var file = await src.copy('$deployDirectory/index.js');
    print('copied to $file ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(deployDirectory).create(recursive: true);
    await copy();
  }
}

/// New builder helper
class NodeAppBuilder {
  late final NodeAppOptions options;

  NodeAppBuilder({NodeAppOptions? options}) {
    this.options = options ?? NodeAppOptions();
  }

  Future<void> build() async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy();
  }

  Future<void> copyToDeploy() async {
    await nodePackageCopyToDeploy(options.packageTop,
        directory: options.srcDir, deployDirectory: options.deployDir);
  }

  Future<void> run() async {
    await copyToDeploy();
    await nodePackageRun(options.packageTop);
  }

  Future<void> buildAndRun() async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy();
    await nodePackageRun(options.packageTop);
  }

  Future<void> clean() async {
    await nodePackageClean(options.packageTop);
  }
}
