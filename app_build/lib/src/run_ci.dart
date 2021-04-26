import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_app_node_build/src/node_support.dart';

import 'import.dart';
import 'node_support.dart' as node_support;

Future<bool> _isPubPackageRoot(String dir) async {
  try {
    await pathGetPubspecYamlMap(dir);
    return true;
  } catch (_) {
    return false;
  }
}

Future main(List<String> arguments) async {
  String? path;
  if (arguments.isNotEmpty) {
    var firstArg = arguments.first.toString();
    if (await _isPubPackageRoot(firstArg)) {
      path = firstArg;
    }
  }
  path ??= Directory.current.path;
  await nodePackageRunCi(path);
}

Future<List<String>> topLevelDir(String dir) async {
  var list = <String>[];
  await Directory(dir).list(recursive: false).listen((event) {
    if (event is Directory) {
      list.add(basename(event.path));
    }
  }).asFuture();
  return list;
}

List<String> _forbiddenDirs = ['node_modules', '.dart_tool', 'build'];

List<String> filterDartDirs(List<String> dirs) => dirs.where((element) {
      if (element.startsWith('.')) {
        return false;
      }
      if (_forbiddenDirs.contains(element)) {
        return false;
      }
      return true;
    }).toList(growable: false);

/// Package run options
class NodePackageRunCiOptions {
  final bool? noNodeTest;
  final bool? noVmTest;
  final bool? noGet;
  final bool? noFormat;
  final bool? noAnalyze;
  final bool? noNpmInstall;

  NodePackageRunCiOptions(
      {this.noNodeTest,
      this.noVmTest,
      this.noAnalyze,
      this.noFormat,
      this.noGet,
      this.noNpmInstall});
}

/// Run basic tests on dart/flutter package
///
/// Dart:
/// ```
/// ```
Future nodePackageRunCi(String path, [NodePackageRunCiOptions? options]) async {
  var shell = Shell(workingDirectory: path);

  var pubspecMap = await pathGetPubspecYamlMap(path);
  var analysisOptionsMap = await pathGetAnalysisOptionsYamlMap(path);
  var isFlutterPackage = pubspecYamlSupportsFlutter(pubspecMap);

  var sdkBoundaries = pubspecYamlGetSdkBoundaries(pubspecMap)!;
  var supportsNnbdExperiment =
      analysisOptionsSupportsNnbdExperiment(analysisOptionsMap);

  if (!sdkBoundaries.match(dartVersion)) {
    stderr.writeln('Unsupported sdk boundaries for dart $dartVersion');
    return;
  }
  if (isFlutterPackage) {
    throw UnsupportedError('Flutter not supported');
  }
  if (!(options?.noGet ?? false)) {
    await shell.run('''
    # Get dependencies
    pub get
    ''');
  }

  if (!(options?.noFormat ?? false)) {
    // Formatting change in 2.9 with hashbang first line
    if (dartVersion >= Version(2, 9, 0, pre: '0')) {
      try {
        var dirs = await topLevelDir(path);
        await shell.run('''
      # Formatting
      dartfmt -n --set-exit-if-changed ${filterDartDirs(dirs).join(' ')}
    ''');
      } catch (e) {
        // Sometimes we allow formatting errors...

        // if (supportsNnbdExperiment) {
        //  stderr.writeln('Error in dartfmt during nnbd experiment, ok...');
        //} else {
        //

        // but in general no!
        rethrow;
      }
    }
  }

  var dartExtraOptions = '';
  var dartRunExtraOptions = '';
  if (supportsNnbdExperiment) {
    // Temp dart extra option. To remove once nnbd supported on stable without flags
    dartExtraOptions = '--enable-experiment=non-nullable';
    // Needed for run and test
    dartRunExtraOptions =
        '--enable-experiment=non-nullable --no-sound-null-safety';

    if (!(options?.noAnalyze ?? false)) {
      // Only io test for now
      if (dartVersion >= Version(2, 10, 0, pre: '92')) {
        await shell.run('''
      # Analyze code
      dartanalyzer $dartExtraOptions --fatal-warnings --fatal-infos .
  ''');
      }

      await shell.run('''
    # Test
    pub run $dartRunExtraOptions test -p vm
    ''');
    } else {
      stderr.writeln('NNBD experiments are skipped for dart $dartVersion');
    }
  } else {
    if (!(options?.noAnalyze ?? false)) {
      await shell.run('''
      # Analyze code
      dartanalyzer --fatal-warnings --fatal-infos .
  ''');
    }

    var platforms = <String>[if (!(options?.noVmTest ?? false)) 'vm'];

    if (!(options?.noNodeTest ?? false)) {
      // Add node for standard run test
      var isNode = pubspecYamlSupportsNode(pubspecMap);
      if (isNode && node_support.isNodeSupported) {
        platforms.add('node');

        if (!(options?.noNpmInstall ?? false)) {
          await nodeTestCheck(path);
        }
        if (!(options?.noGet ?? false)) {
          // Workaround issue about complaining old pubspec on node...
          // https://travis-ci.org/github/tekartik/aliyun.dart/jobs/724680004
          await shell.run('''
          # Get dependencies
          pub get --offline
    ''');
        }
      }
    }

    if (platforms.isNotEmpty) {
      await shell.run('''
    # Test
    pub run test -p ${platforms.join(',')}
    ''');
    }
  }
}
