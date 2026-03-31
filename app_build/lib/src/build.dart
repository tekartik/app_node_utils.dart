//import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/stdio.dart';
//import 'package:dev_build/utils/shell_run.dart';
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

/// Install node modules if needed
Future nodePackagePathNpmInstall(String path, {bool force = false}) async {
  //print('# ${File(join(path, deployDirectory, 'functions', 'package.json')).statSync()}');
  if ((File(join(path, 'package.json')).existsSync())) {
    if (force || !(Directory(join(path, 'node_modules')).existsSync())) {
      await Shell(workingDirectory: path).run('npm install');
    }
  }
}

/// Regular node app
///
Future nodePackageRun(
  String path, {
  String? deployDirectory,
  String? basename,
  NodeAppRunOptions? runOptions,
}) async {
  deployDirectory ??= 'deploy';
  var shellOptions = ShellOptions(
    stdin: runOptions?.stdin,
    workingDirectory: path,
  );
  await nodePackagePathNpmInstall(join(path, deployDirectory));
  var shell = Shell(options: shellOptions);
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
/// if basename is specified copy `<basename>.dart.js` to `deploy/<basename>.js`
Future nodePackageCopyToDeploy(
  String path, {
  String? directory,
  String? deployDirectory,
  String? basename,
}) async {
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

  /// DEPRECATED use compile
  /// Build main.dart.js and copy as index.js
  ///
  /// if basename is specified, in this case `<basename>.dart.js` is copied to `deploy/<basename>.js`
  Future<void> build({String? basename}) async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy(basename: basename);
  }

  /// Copy main.dart.js to deploy/index.js
  ///
  /// if basename is specified, in this case `<basename>.dart.js` is copied to `deploy/<basename>.js`
  Future<void> copyToDeploy({String? basename}) async {
    await nodePackageCopyToDeploy(
      options.packageTop,
      directory: options.srcDir,
      deployDirectory: options.deployDir,
      basename: basename,
    );
  }

  String get _srcFile => options.srcFile ?? 'main.dart';

  Future<void> run({String? basename, NodeAppRunOptions? runOptions}) async {
    var srcFile = _srcFile;
    var fileBasename = basename ?? basenameWithoutExtension(srcFile);
    await copyToDeploy(basename: fileBasename);
    await nodePackageRun(
      options.packageTop,
      deployDirectory: options.deployDir,
      basename: fileBasename,
      runOptions: runOptions,
    );
  }

  /// DEPRECATED use compile
  Future<void> buildAndRun({
    String? basename,
    NodeAppRunOptions? runOptions,
  }) async {
    await nodePackageBuild(options.packageTop, directory: options.srcDir);
    await copyToDeploy(basename: basename);
    await nodePackageRun(
      options.packageTop,
      deployDirectory: options.deployDir,
      basename: basename,
      runOptions: runOptions,
    );
  }

  /// Compile and run
  Future<void> compileAndRun({NodeAppRunOptions? runOptions}) async {
    await compile();
    await run(runOptions: runOptions);
  }

  Future<void> compile() async {
    var srcFile = _srcFile;
    var fileBasename = basenameWithoutExtension(srcFile);
    await nodePackageCompileJs(
      options.packageTop,
      input: join(options.srcDir, srcFile),
    );
    await copyToDeploy(basename: fileBasename);
  }

  Future<void> clean() async {
    await nodePackageClean(options.packageTop);
  }
}
