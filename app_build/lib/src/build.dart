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
Future nodePackageRun(String path,
    {String? deployDirectory, String? basename}) async {
  deployDirectory ??= 'deploy';
  var shell = Shell(workingDirectory: path);
  await shell.run('''
node ${shellArgument(join(deployDirectory, '${basename ?? 'index'}.js'))}
  ''');
}

/// Clean node app
Future nodePackageClean(String path, {String? deployDirectory}) async {
  deployDirectory ??= 'deploy';
  stdout.writeln('deleting "build"');
  try {
    await Directory('build').delete(recursive: true);
  } catch (_) {}

  var indexJs = join(deployDirectory, 'index.js');
  stderr.writeln('deleting "$indexJs"');
  try {
    await File(indexJs).delete();
  } catch (_) {}
}

/// Copy main.dart.js to index.js
///
/// if basename is specified copy <basename>.dart.js to deploy/<basename>.js
Future nodePackageCopyToDeploy(String path,
    {String? directory, String? deployDirectory, String? basename}) async {
  directory ??= 'bin';
  deployDirectory ??= 'deploy';
  var src = File('build/$directory/${basename ?? 'main'}.dart.js');
  Future copy() async {
    var file = await src.copy('$deployDirectory/${basename ?? 'index'}.js');
    stdout.writeln('copied to $file ${file.statSync()}');
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

  /// Build main.dart.js and copy as index.js
  ///
  /// if basename is specified, in this case <basename>.dart.js is copied to deploy/<basename>.js
  Future<void> build({String? basename}) async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy(basename: basename);
  }

  /// Copy main.dart.js to deploy/index.js
  ///
  /// if basename is specified, in this case <basename>.dart.js is copied to deploy/<basename>.js
  Future<void> copyToDeploy({String? basename}) async {
    await nodePackageCopyToDeploy(options.packageTop,
        directory: options.srcDir,
        deployDirectory: options.deployDir,
        basename: basename);
  }

  Future<void> run({String? basename}) async {
    await copyToDeploy(basename: basename);
    await nodePackageRun(options.packageTop, basename: basename);
  }

  Future<void> buildAndRun({String? basename}) async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy(basename: basename);
    await nodePackageRun(options.packageTop,
        deployDirectory: options.deployDir, basename: basename);
  }

  Future<void> clean() async {
    await nodePackageClean(options.packageTop);
  }
}
