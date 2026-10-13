@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_node_build/app_build.dart';
import 'package:tekartik_app_node_build/gcf_build.dart';
import 'package:test/test.dart';

void main() {
  late Directory top;
  setUp(() async {
    top = await Directory.systemTemp.createTemp('app_build_paths_');
  });
  tearDown(() async {
    await top.delete(recursive: true);
  });

  Future<void> writeFile(String path, String content) async {
    var file = File(join(top.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  bool exists(String path) =>
      FileSystemEntity.typeSync(join(top.path, path)) !=
      FileSystemEntityType.notFound;

  String read(String path) => File(join(top.path, path)).readAsStringSync();

  group('paths are relative to the package', () {
    test('nodePackageCopyToDeploy', () async {
      await writeFile(join('build', 'bin', 'main.dart.js'), 'main');
      await writeFile(join('build', 'bin', 'other.dart.js'), 'other');
      await nodePackageCopyToDeploy(top.path);
      expect(read(join('deploy', 'index.js')), 'main');
      await nodePackageCopyToDeploy(top.path, basename: 'other');
      expect(read(join('deploy', 'other.js')), 'other');
    });

    test('nodePackageClean', () async {
      await writeFile(join('build', 'bin', 'main.dart.js'), 'main');
      await writeFile(join('deploy', 'index.js'), 'main');
      await writeFile(join('deploy', 'keep.js'), 'keep');
      await nodePackageClean(top.path);
      expect(exists('build'), isFalse);
      expect(exists(join('deploy', 'index.js')), isFalse);
      expect(exists(join('deploy', 'keep.js')), isTrue);
    });

    test('NodeAppBuilder.clean uses the deploy dir', () async {
      await writeFile(join('out', 'index.js'), 'main');
      await NodeAppBuilder(
        options: NodeAppOptions(packageTop: top.path, deployDir: 'out'),
      ).clean();
      expect(exists(join('out', 'index.js')), isFalse);
    });

    test('GcfNodeAppBuilder.copyToDeploy uses srcFile', () async {
      await writeFile(join('build', 'bin', 'main.dart.js'), 'main');
      await writeFile(join('build', 'bin', 'other.dart.js'), 'other');
      await GcfNodeAppBuilder(
        options: GcfNodeAppOptions(packageTop: top.path, srcFile: 'other.dart'),
      ).copyToDeploy();
      expect(read(join('deploy', 'functions', 'index.js')), 'other');
    });

    test('GcfNodeAppBuilder.clean removes the functions index.js', () async {
      await writeFile(join('build', 'bin', 'main.dart.js'), 'main');
      await writeFile(join('deploy', 'functions', 'index.js'), 'main');
      await writeFile(join('deploy', 'functions', 'package.json'), '{}');
      await GcfNodeAppBuilder(
        options: GcfNodeAppOptions(packageTop: top.path),
      ).clean();
      expect(exists('build'), isFalse);
      expect(exists(join('deploy', 'functions', 'index.js')), isFalse);
      expect(exists(join('deploy', 'functions', 'package.json')), isTrue);
    });
  });
}
