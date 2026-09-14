@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_node_build/gcf_build.dart';
import 'package:tekartik_app_node_build/npm_build.dart';
import 'package:test/test.dart';

/// Write a `package.json` in [path].
Future<void> writePackageJson(String path, Map<String, Object?> map) async {
  var file = File(join(path, 'package.json'));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map));
}

/// Write the `package.json` of an installed module.
Future<void> writeInstalled(String path, String name, String version) async {
  await writePackageJson(joinAll([path, 'node_modules', ...name.split('/')]), {
    'name': name,
    'version': version,
  });
}

Future<String> emptyDir(String name) async {
  var path = join('.dart_tool', 'tekartik_app_node_build', 'test', name);
  var dir = Directory(path);
  if (dir.existsSync()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);
  return path;
}

void main() {
  group('npm_check', () {
    test('read', () async {
      var path = await emptyDir('read');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0', 'local': 'file:../local'},
        'devDependencies': {'firebase-functions': '^7.3.2'},
      });
      await writeInstalled(path, 'firebase-admin', '14.4.1');
      await writeInstalled(path, '@google-cloud/firestore', '9.1.0');
      expect(await nodePackageGetNpmDependencyConstraints(path), {
        'firebase-admin': '^14.4.0',
        'local': 'file:../local',
        'firebase-functions': '^7.3.2',
      });
      expect(
        await nodePackageGetNpmDependencyConstraints(
          path,
          includeDevDependencies: false,
        ),
        {'firebase-admin': '^14.4.0', 'local': 'file:../local'},
      );
      expect(
        await nodePackageGetNpmInstalledVersion(path, 'firebase-admin'),
        Version(14, 4, 1),
      );
      expect(
        await nodePackageGetNpmInstalledVersion(
          path,
          '@google-cloud/firestore',
        ),
        Version(9, 1, 0),
      );
      expect(
        await nodePackageGetNpmInstalledVersion(path, 'firebase-functions'),
        isNull,
      );
    });

    test('no package.json', () async {
      var path = await emptyDir('no_package_json');
      var result = await nodePackageNpmCheck(path);
      expect(result.packageJsonExists, isFalse);
      expect(result.nodeModulesExists, isFalse);
      expect(result.dependencies, isEmpty);
      expect(result.isOk, isFalse);
      expect(result.npmInstallNeeded, isFalse);
      expect(result.constraintIssues, ['package.json not found in $path']);
      expect(result.installedIssues, ['node_modules not found in $path']);

      // no-op
      result = await nodePackageNpmInstallIfNeeded(path);
      expect(result.isOk, isFalse);
      expect(Directory(join(path, 'node_modules')).existsSync(), isFalse);
    });

    test('ok', () async {
      var path = await emptyDir('ok');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0'},
        'devDependencies': {'firebase-functions': '>=7.3.2'},
      });
      await writeInstalled(path, 'firebase-admin', '14.5.0');
      await writeInstalled(path, 'firebase-functions', '8.0.0');
      var result = await nodePackageNpmCheck(
        path,
        minConstraints: {
          'firebase-admin': '^14.4.0',
          'firebase-functions': '^7.0.0',
          // not declared, ignored
          '@google-cloud/firestore': '^9.1.0',
        },
        requiredDependencies: ['firebase-admin'],
      );
      expect(result.isOk, isTrue, reason: result.toString());
      expect(result.issues, isEmpty);
      expect(result.npmInstallNeeded, isFalse);
      expect(result.dependencies.map((e) => e.name), [
        'firebase-admin',
        'firebase-functions',
      ]);
      var dependency = result.dependencies.first;
      expect(dependency.constraint, '^14.4.0');
      expect(dependency.minConstraint, '^14.4.0');
      expect(dependency.minVersion, Version(14, 4, 0));
      expect(dependency.constraintMinVersion, Version(14, 4, 0));
      expect(dependency.installedVersion, Version(14, 5, 0));
      expect(dependency.required, isTrue);
      expect(dependency.isDevDependency, isFalse);
      expect(result.dependencies.last.isDevDependency, isTrue);
      expect(result.dependencies.last.required, isFalse);

      // install if needed is a no-op
      result = await nodePackageNpmInstallIfNeeded(
        path,
        minConstraints: {'firebase-admin': '^14.4.0'},
      );
      expect(result.isOk, isTrue);
    });

    test('missing required', () async {
      var path = await emptyDir('missing_required');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0'},
      });
      await writeInstalled(path, 'firebase-admin', '14.4.0');
      var result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-functions': '^7.3.2'},
        requiredDependencies: ['firebase-functions'],
      );
      expect(result.isConstraintOk, isFalse);
      expect(result.isInstalledOk, isTrue);
      expect(result.npmInstallNeeded, isFalse);
      expect(result.constraintIssues, [
        'firebase-functions: missing in package.json (min ^7.3.2)',
      ]);
      expect(result.constraintFailures.map((e) => e.name), [
        'firebase-functions',
      ]);
    });

    test('constraint below min', () async {
      var path = await emptyDir('below_min');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.2.0'},
      });
      await writeInstalled(path, 'firebase-admin', '14.2.0');
      var result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '^14.4.0'},
      );
      expect(result.isConstraintOk, isFalse);
      expect(result.isInstalledOk, isFalse);
      expect(result.isOk, isFalse);
      // npm install alone would not fix it
      expect(result.npmInstallNeeded, isFalse);
      expect(result.constraintIssues, [
        'firebase-admin: "^14.2.0" is below min ^14.4.0',
      ]);
      expect(result.installedIssues, [
        'firebase-admin: installed 14.2.0 is below min ^14.4.0',
      ]);

      // A plain version min constraint works too
      result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '14.4.0'},
      );
      expect(result.constraintIssues, [
        'firebase-admin: "^14.2.0" is below min 14.4.0',
      ]);

      // Same lower bound is ok
      result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '^14.2.0'},
      );
      expect(result.isOk, isTrue, reason: result.toString());
    });

    test('no lower bound', () async {
      var path = await emptyDir('no_lower_bound');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '*', 'other': ''},
      });
      await writeInstalled(path, 'firebase-admin', '14.4.0');
      await writeInstalled(path, 'other', '1.0.0');
      var result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '^14.4.0'},
      );
      expect(result.constraintIssues, [
        'firebase-admin: "*" has no lower bound, min ^14.4.0',
      ]);
      expect(result.isInstalledOk, isTrue);
      // Without min constraint, it is fine
      result = await nodePackageNpmCheck(path);
      expect(result.isOk, isTrue, reason: result.toString());
    });

    test('not installed', () async {
      var path = await emptyDir('not_installed');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0'},
        'devDependencies': {'firebase-functions': '^7.3.2'},
      });
      var result = await nodePackageNpmCheck(path);
      expect(result.isConstraintOk, isTrue);
      expect(result.isInstalledOk, isFalse);
      expect(result.npmInstallNeeded, isTrue);
      expect(result.installedIssues, [
        'node_modules not found in $path',
        'firebase-admin: not installed',
        'firebase-functions: not installed',
      ]);

      // dev dependencies excluded
      result = await nodePackageNpmCheck(path, includeDevDependencies: false);
      expect(result.dependencies.map((e) => e.name), ['firebase-admin']);

      // node_modules exists but a module is missing
      await writeInstalled(path, 'firebase-admin', '14.4.0');
      result = await nodePackageNpmCheck(path);
      expect(result.nodeModulesExists, isTrue);
      expect(result.npmInstallNeeded, isTrue);
      expect(result.installedIssues, ['firebase-functions: not installed']);
    });

    test('installed mismatch', () async {
      var path = await emptyDir('installed_mismatch');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0'},
      });
      // package.json was bumped, node_modules not updated
      await writeInstalled(path, 'firebase-admin', '14.2.0');
      var result = await nodePackageNpmCheck(path);
      expect(result.isConstraintOk, isTrue);
      expect(result.npmInstallNeeded, isTrue);
      expect(result.installedIssues, [
        'firebase-admin: installed 14.2.0 does not match "^14.4.0"',
      ]);

      // Installed version too new for the min constraint upper bound is fine,
      // only the lower bound matters
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '>=14.4.0'},
      });
      await writeInstalled(path, 'firebase-admin', '15.0.0');
      result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '^14.4.0'},
      );
      expect(result.isOk, isTrue, reason: result.toString());
    });

    test('non registry', () async {
      var path = await emptyDir('non_registry');
      await writePackageJson(path, {
        'dependencies': {
          'local': 'file:../local',
          'repo': 'github:user/repo',
          'bad': 'dummy',
        },
      });
      await writeInstalled(path, 'local', '1.0.0');
      await writeInstalled(path, 'repo', '1.0.0');
      await writeInstalled(path, 'bad', '1.0.0');
      var result = await nodePackageNpmCheck(path);
      // version cannot be checked but installation can
      expect(result.constraintIssues, ['bad: unsupported constraint "dummy"']);
      expect(result.isInstalledOk, isTrue);

      result = await nodePackageNpmCheck(
        path,
        minConstraints: {'local': '^1.0.0'},
      );
      expect(result.constraintIssues, [
        'local: cannot check "file:../local" against min ^1.0.0',
        'bad: unsupported constraint "dummy"',
      ]);
    });

    test('invalid min constraint', () async {
      var path = await emptyDir('invalid_min');
      await writePackageJson(path, {
        'dependencies': {'firebase-admin': '^14.4.0'},
      });
      await writeInstalled(path, 'firebase-admin', '14.4.0');
      var result = await nodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': 'dummy'},
      );
      expect(result.constraintIssues, [
        'firebase-admin: invalid min constraint "dummy"',
      ]);
    });

    test('gcf', () async {
      var path = await emptyDir('gcf');
      var functionsPath = gcfNodePackageFunctionsPath(path);
      expect(functionsPath, join(path, 'deploy', 'functions'));
      await writePackageJson(functionsPath, {
        'dependencies': {
          'firebase-admin': '^14.4.0',
          'firebase-functions': '^7.3.2',
        },
      });
      await writeInstalled(functionsPath, 'firebase-admin', '14.4.0');
      await writeInstalled(functionsPath, 'firebase-functions', '7.3.2');
      var result = await gcfNodePackageNpmCheck(
        path,
        minConstraints: {'firebase-admin': '^14.4.0'},
        requiredDependencies: ['firebase-admin', 'firebase-functions'],
      );
      expect(result.path, functionsPath);
      expect(result.isOk, isTrue, reason: result.toString());

      var builder = GcfNodeAppBuilder(
        options: GcfNodeAppOptions(packageTop: path),
      );
      result = await builder.npmCheck(
        minConstraints: {'firebase-admin': '^15.0.0'},
      );
      expect(result.isOk, isFalse);
      expect(result.constraintIssues, [
        'firebase-admin: "^14.4.0" is below min ^15.0.0',
      ]);
    });
  });
}
