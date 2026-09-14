import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_build_node/build_node.dart' show isNodePackageRoot;

import 'npm_version.dart';

/// `package.json` file name.
const npmPackageJsonFileName = 'package.json';

/// `node_modules` directory name.
const npmNodeModulesDirName = 'node_modules';

/// Read the `package.json` of the node package in [path].
Future<Map<String, Object?>> nodePackageReadPackageJson(String path) async {
  var content = await File(join(path, npmPackageJsonFileName)).readAsString();
  return (jsonDecode(content) as Map).cast<String, Object?>();
}

Map<String, String> _constraintMap(Object? section) {
  var map = <String, String>{};
  if (section is Map) {
    for (var entry in section.entries) {
      var value = entry.value;
      if (value is String) {
        map[entry.key.toString()] = value;
      }
    }
  }
  return map;
}

/// Read the npm dependency constraints (name -> version range) declared in
/// the `package.json` of [path].
///
/// Both `dependencies` and `devDependencies` are read unless
/// [includeDevDependencies] is false.
Future<Map<String, String>> nodePackageGetNpmDependencyConstraints(
  String path, {
  bool includeDevDependencies = true,
}) async {
  var packageJson = await nodePackageReadPackageJson(path);
  return {
    ..._constraintMap(packageJson['dependencies']),
    if (includeDevDependencies)
      ..._constraintMap(packageJson['devDependencies']),
  };
}

/// The `package.json` path of an installed module (`@scope/name` supported).
String _installedPackageJsonPath(String path, String name) =>
    joinAll([path, npmNodeModulesDirName, ...name.split('/'), 'package.json']);

/// Read the version of the npm package [name] installed in the `node_modules`
/// of [path], null if not installed.
Future<Version?> nodePackageGetNpmInstalledVersion(
  String path,
  String name,
) async {
  var file = File(_installedPackageJsonPath(path, name));
  if (!file.existsSync()) {
    return null;
  }
  try {
    var map = jsonDecode(await file.readAsString()) as Map;
    return npmVersionTryParse(map['version']?.toString());
  } catch (_) {
    return null;
  }
}

/// The check of a single npm dependency.
class NodePackageNpmDependencyCheck {
  /// The npm package name.
  final String name;

  /// The version range declared in `package.json`, null if not declared.
  final String? constraint;

  /// True if declared in `devDependencies`.
  final bool isDevDependency;

  /// The minimum version range required (`^14.4.0`), null if none.
  ///
  /// Only its lower bound is enforced.
  final String? minConstraint;

  /// True if the dependency must be declared in `package.json`.
  final bool required;

  /// The version installed in `node_modules`, null if not installed.
  final Version? installedVersion;

  /// Creates a dependency check.
  NodePackageNpmDependencyCheck({
    required this.name,
    required this.constraint,
    this.isDevDependency = false,
    required this.minConstraint,
    required this.required,
    required this.installedVersion,
  });

  /// True if declared in `package.json`.
  bool get isDeclared => constraint != null;

  /// True if the declared constraint is a regular registry version range.
  bool get isRegistryConstraint =>
      constraint != null && npmVersionConstraintIsRegistry(constraint!);

  /// The parsed declared constraint, null if missing or not supported.
  VersionConstraint? get versionConstraint =>
      npmVersionConstraintTryParse(constraint);

  /// The lower bound of the declared constraint, null if unbounded.
  Version? get constraintMinVersion {
    var versionConstraint = this.versionConstraint;
    if (versionConstraint == null) {
      return null;
    }
    return versionConstraintMinVersion(versionConstraint);
  }

  /// The lower bound of the minimum constraint, null if none.
  Version? get minVersion {
    var minConstraint = this.minConstraint;
    if (minConstraint == null) {
      return null;
    }
    return npmVersionConstraintMinVersion(minConstraint);
  }

  /// True if `package.json` is ok for this dependency:
  /// - declared if [required]
  /// - if declared, a valid version range
  /// - if declared and [minConstraint] is set, its lower bound is at least
  ///   the lower bound of [minConstraint]
  bool get isConstraintOk => constraintIssue == null;

  /// The `package.json` issue, null if ok.
  String? get constraintIssue {
    if (!isDeclared) {
      if (required) {
        return '$name: missing in package.json'
            '${minConstraint == null ? '' : ' (min $minConstraint)'}';
      }
      return null;
    }
    var minVersion = this.minVersion;
    if (minConstraint != null && minVersion == null) {
      return '$name: invalid min constraint "$minConstraint"';
    }
    if (!isRegistryConstraint) {
      if (minVersion != null) {
        return '$name: cannot check "$constraint" against min $minConstraint';
      }
      return null;
    }
    if (versionConstraint == null) {
      return '$name: unsupported constraint "$constraint"';
    }
    if (minVersion != null) {
      var constraintMinVersion = this.constraintMinVersion;
      if (constraintMinVersion == null) {
        return '$name: "$constraint" has no lower bound, min $minConstraint';
      }
      if (constraintMinVersion < minVersion) {
        return '$name: "$constraint" is below min $minConstraint';
      }
    }
    return null;
  }

  /// True if the installed version is ok:
  /// - installed if declared
  /// - allowed by the declared constraint
  /// - at least the lower bound of [minConstraint] if set
  bool get isInstalledOk => installedIssue == null;

  /// The installation issue, null if ok.
  String? get installedIssue {
    if (!isDeclared) {
      return null;
    }
    var installedVersion = this.installedVersion;
    if (installedVersion == null) {
      return '$name: not installed';
    }
    var versionConstraint = this.versionConstraint;
    if (versionConstraint != null &&
        !versionConstraint.allows(installedVersion)) {
      return '$name: installed $installedVersion does not match "$constraint"';
    }
    var minVersion = this.minVersion;
    if (minVersion != null && installedVersion < minVersion) {
      return '$name: installed $installedVersion is below min $minConstraint';
    }
    return null;
  }

  /// True if both `package.json` and the installed version are ok.
  bool get isOk => isConstraintOk && isInstalledOk;

  @override
  String toString() =>
      '$name: ${constraint ?? '(missing)'}'
      '${minConstraint == null ? '' : ' min $minConstraint'}'
      ' installed ${installedVersion ?? '(none)'}';
}

/// The result of an npm dependency check on a node package.
class NodePackageNpmCheckResult {
  /// The node package path.
  final String path;

  /// True if `package.json` exists.
  final bool packageJsonExists;

  /// True if `node_modules` exists.
  final bool nodeModulesExists;

  /// The checked dependencies.
  final List<NodePackageNpmDependencyCheck> dependencies;

  /// Creates a check result.
  NodePackageNpmCheckResult({
    required this.path,
    required this.packageJsonExists,
    required this.nodeModulesExists,
    required this.dependencies,
  });

  /// The `package.json` issues (missing dependency, constraint below
  /// minimum...).
  List<String> get constraintIssues => [
    if (!packageJsonExists) 'package.json not found in $path',
    for (var dependency in dependencies)
      if (dependency.constraintIssue != null) dependency.constraintIssue!,
  ];

  /// The installation issues (not installed, version mismatch...).
  List<String> get installedIssues => [
    if (!nodeModulesExists) 'node_modules not found in $path',
    for (var dependency in dependencies)
      if (dependency.installedIssue != null) dependency.installedIssue!,
  ];

  /// All issues.
  List<String> get issues => [...constraintIssues, ...installedIssues];

  /// True if `package.json` matches the minimum constraints and required
  /// dependencies.
  bool get isConstraintOk => constraintIssues.isEmpty;

  /// True if every checked dependency is installed with a matching version.
  bool get isInstalledOk => installedIssues.isEmpty;

  /// True if everything is ok.
  bool get isOk => isConstraintOk && isInstalledOk;

  /// True if `npm install` should fix the installation (i.e. `package.json`
  /// is ok but the installed versions are not).
  bool get npmInstallNeeded => isConstraintOk && !isInstalledOk;

  /// The dependencies whose `package.json` declaration must be fixed.
  List<NodePackageNpmDependencyCheck> get constraintFailures => dependencies
      .where((dependency) => !dependency.isConstraintOk)
      .toList(growable: false);

  @override
  String toString() =>
      'NodePackageNpmCheckResult($path, ${isOk ? 'ok' : issues.join(', ')})';
}

/// Check the npm dependencies of the node package in [path]:
/// - every declared registry dependency (`dependencies` and, unless
///   [includeDevDependencies] is false, `devDependencies`) must be installed
///   in `node_modules` with a version matching its constraint
/// - every declared dependency listed in [minConstraints] must have a
///   constraint (and an installed version) at least the lower bound of the
///   minimum constraint (`{'firebase-admin': '^14.4.0'}`)
/// - every name in [requiredDependencies] must be declared.
///
/// Nothing is installed nor modified, see [nodePackageNpmInstallIfNeeded].
Future<NodePackageNpmCheckResult> nodePackageNpmCheck(
  String path, {
  Map<String, String>? minConstraints,
  List<String>? requiredDependencies,
  bool includeDevDependencies = true,
}) async {
  minConstraints ??= {};
  requiredDependencies ??= [];
  var packageJsonExists = isNodePackageRoot(path);
  var nodeModulesExists = Directory(
    join(path, npmNodeModulesDirName),
  ).existsSync();
  var dependencies = <NodePackageNpmDependencyCheck>[];
  var constraints = <String, String>{};
  var devDependencyNames = <String>{};
  if (packageJsonExists) {
    var packageJson = await nodePackageReadPackageJson(path);
    constraints.addAll(_constraintMap(packageJson['dependencies']));
    if (includeDevDependencies) {
      var devConstraints = _constraintMap(packageJson['devDependencies']);
      devDependencyNames.addAll(devConstraints.keys);
      constraints.addAll(devConstraints);
    }
  }
  var names = <String>{
    ...constraints.keys,
    ...requiredDependencies,
    // Only declared dependencies are checked against the min constraints
  };
  for (var name in names) {
    var constraint = constraints[name];
    dependencies.add(
      NodePackageNpmDependencyCheck(
        name: name,
        constraint: constraint,
        isDevDependency: devDependencyNames.contains(name),
        minConstraint: minConstraints[name],
        required: requiredDependencies.contains(name),
        installedVersion: constraint == null
            ? null
            : await nodePackageGetNpmInstalledVersion(path, name),
      ),
    );
  }
  return NodePackageNpmCheckResult(
    path: path,
    packageJsonExists: packageJsonExists,
    nodeModulesExists: nodeModulesExists,
    dependencies: dependencies,
  );
}

/// Check the npm dependencies of the node package in [path] (see
/// [nodePackageNpmCheck]) and run `npm install` if the installed versions
/// don't match `package.json` or the [minConstraints].
///
/// If `package.json` itself is not ok (missing [requiredDependencies] or
/// constraint below the minimum) it is fixed with
/// `npm install --save <name>@<minConstraint>` when [updatePackageJson] is
/// true, otherwise the issues are reported on stderr and nothing is installed.
///
/// If [force] is true, `npm install` is always run.
///
/// This is a no-op if [path] is not a node package (no `package.json`).
///
/// Returns the final check result, [NodePackageNpmCheckResult.isOk] tells
/// whether the package is now up to date.
Future<NodePackageNpmCheckResult> nodePackageNpmInstallIfNeeded(
  String path, {
  Map<String, String>? minConstraints,
  List<String>? requiredDependencies,
  bool includeDevDependencies = true,
  bool updatePackageJson = false,
  bool force = false,
  bool verbose = false,
}) async {
  Future<NodePackageNpmCheckResult> check() => nodePackageNpmCheck(
    path,
    minConstraints: minConstraints,
    requiredDependencies: requiredDependencies,
    includeDevDependencies: includeDevDependencies,
  );

  var result = await check();
  if (!result.packageJsonExists) {
    if (verbose) {
      stdout.writeln('# no package.json in $path');
    }
    return result;
  }
  var shell = Shell(workingDirectory: path);

  if (!result.isConstraintOk) {
    var failures = result.constraintFailures;
    var fixable = failures
        .where((dependency) => dependency.minVersion != null)
        .toList();
    if (updatePackageJson && fixable.length == failures.length) {
      var dependencies = fixable.where(
        (dependency) => !dependency.isDevDependency,
      );
      var devDependencies = fixable.where(
        (dependency) => dependency.isDevDependency,
      );
      String arguments(Iterable<NodePackageNpmDependencyCheck> list) => list
          .map(
            (dependency) =>
                shellArgument('${dependency.name}@${dependency.minConstraint}'),
          )
          .join(' ');
      stdout.writeln(
        '# npm install $path (${failures.map((e) => e.constraintIssue).join(', ')})',
      );
      if (dependencies.isNotEmpty) {
        await shell.run('npm install --save ${arguments(dependencies)}');
      }
      if (devDependencies.isNotEmpty) {
        await shell.run('npm install --save-dev ${arguments(devDependencies)}');
      }
      result = await check();
    } else {
      stderr.writeln('# package.json in $path needs an update:');
      for (var issue in result.constraintIssues) {
        stderr.writeln('#   $issue');
      }
      return result;
    }
  }

  if (force || result.npmInstallNeeded) {
    stdout.writeln(
      '# npm install $path'
      '${force ? '' : ' (${result.installedIssues.join(', ')})'}',
    );
    await shell.run('npm install');
    result = await check();
    if (!result.isOk) {
      stderr.writeln('# ${result.path} still not up to date:');
      for (var issue in result.issues) {
        stderr.writeln('#   $issue');
      }
    }
  } else if (verbose) {
    stdout.writeln('# $path npm dependencies up to date');
  }
  return result;
}
