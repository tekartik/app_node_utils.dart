---
name: tekartik-app-node-build-gcf
description: >-
  Use when building, emulating or deploying Dart-written Google Cloud /
  Firebase Functions (or Aliyun Function Compute) with tekartik_app_node_build:
  GcfNodeAppBuilder and GcfNodeAppOptions (projectId, functions, port, region,
  deployDir), gcfNodePackageBuild, gcfNodePackageServeFunctions,
  gcfNodePackageDeployFunctions, gcfNodePackageBuildAndServe,
  gcfNodeBuildAndServe, gcfNodePackageCopyToDeploy, gcfNodePackageNpmCheck,
  gcfNodePackageNpmInstallIfNeeded, nodePackageNpmCheck with
  NodePackageNpmCheckResult / NodePackageNpmDependencyCheck, getDefaultProjectId,
  and afcNodeBuild / afcNodeDeploy from afc_build.dart.
---

# Google Cloud Functions builds (tekartik_app_node_build)

`package:tekartik_app_node_build/gcf_build.dart` compiles `bin/main.dart` to
`deploy/functions/index.js`, then shells out to the `firebase` CLI to emulate or
deploy the functions; `npm_build.dart` checks the npm dependencies of that
generated package. These are `dart:io` tool scripts: put them in `tool/`, and
keep the function code itself (firebase_functions interop) in `bin/` and `lib/`.
The plain node-app build (no Firebase) is covered by
[tekartik-app-node-build-setup](../tekartik-app-node-build-setup/SKILL.md).

## Guidelines

* Git dependency (not on pub.dev), in `dev_dependencies`:
  ```yaml
  dev_dependencies:
    tekartik_app_node_build:
      git:
        url: https://github.com/tekartik/app_node_utils.dart
        path: app_build
      version: '>=0.1.0'
    build_runner:
    build_web_compilers:
  ```
  Requires `node`, `npm` and the `firebase` CLI on the PATH, plus a `deploy/`
  folder initialized with `firebase init` (its `functions/package.json` is the
  node package that gets deployed). Add `deploy/functions/index.js` to
  `.gitignore`: it is generated.
* Imports: `package:tekartik_app_node_build/gcf_build.dart` (GCF build, serve,
  deploy, `GcfNodeAppBuilder`, `GcfNodeAppOptions` and the npm check result
  types), `package:tekartik_app_node_build/npm_build.dart` (npm checks alone),
  `package:tekartik_app_node_build/afc_build.dart` (Aliyun).
  `gcf_build.dart` also re-exports `CommonAppBuilder` / `CommonAppBuilderExt`
  from `tekartik_common_build`.
* Prefer `GcfNodeAppBuilder(options: GcfNodeAppOptions(...))`.
  `GcfNodeAppOptions({projectId, packageTop, deployDir, srcDir, srcFile, port,
  functions, region})` extends `NodeAppOptions`: `packageTop` defaults to `'.'`,
  `deployDir` to `'deploy'`, `srcDir` to `'bin'`, `srcFile` to `main.dart`.
  `functions` restricts every serve/deploy to those function names, `port` is
  the emulator port. `copyWith(...)` derives a dev/prod variant.
  Without options the builder uses `getDefaultProjectId()`, which reads the
  `TEKARTIK_FIREBASE_PROJECT_ID` environment variable and falls back to
  `'-unset-project-id-'`.
* Builder methods: `build()` (compile + copy to `deploy/functions/index.js`,
  generating the version file first when the project has one),
  `copyToDeploy()`, `serveFunctions({functions})` (`firebase emulators:start
  --only functions:<name>`), `serve()` (legacy `firebase serve`),
  `buildAndServe()`, `buildAndServeFunctions({functions})`,
  `deployFunctions({functions, force})` (`firebase deploy --only functions`),
  `buildAndDeployFunctions({functions, force})`, `clean()`, `npmInstall()`,
  `npmCheck(...)`, `npmInstallIfNeeded(...)`, `npmUpgrade()` (firebase-functions
  latest), `npmUpgradeFirebaseAdmin()`, plus `deployFullPath` and `path`.
  `force: true` on a deploy adds `--force`: functions missing from the deploy
  folder are deleted and runtime upgrade prompts are skipped - use it only in
  an unattended script.
* `generateVersion()`, `generateVersionIfNeeded()` and `bumpVersion(patch: ,
  minor: , major: )` come from `CommonAppBuilderExt` and work on any
  `GcfNodeAppBuilder`.
* Function-level equivalents, first argument is the package path:
  `gcfNodePackageBuild(path, directory: 'bin', deployDirectory: 'deploy',
  srcFile: , debug: )`, `gcfNodePackageCopyToDeploy(path, ...)`,
  `gcfNodePackageServeFunctions(path, deployDirectory: , projectId: ,
  functions: , port: )`, `gcfNodePackageDeployFunctions(path, ...)`,
  `gcfNodePackageBuildAndServe(path, ...)`, `gcfNodePackageServe(path,
  directory: 'deploy', projectId: , port: )`, `gcfNodePackageNpmInstall(path,
  force: , deployDirectory: )`, `gcfNodePackageFunctionsPath(path,
  deployDirectory: )`. The `gcfNode*` variants without `Package`
  (`gcfNodeBuildAndServe`, `gcfNodeCopyToDeploy`, `gcfNodeServe`) act on `'.'`.
* npm checks (`npm_build.dart`, also exported by `app_build.dart` and
  `gcf_build.dart`): `nodePackageNpmCheck(path, minConstraints: {'firebase-admin':
  '^14.4.0'}, requiredDependencies: [...], includeDevDependencies: )` reads
  `package.json` plus `node_modules` and reports without touching anything;
  `nodePackageNpmInstallIfNeeded(path, ..., updatePackageJson: , force: ,
  verbose: )` runs `npm install` when the installed versions are stale and,
  with `updatePackageJson: true`, raises constraints below the minimum with
  `npm install --save <name>@<constraint>`. The `gcfNodePackage*` versions of
  both target `<deployDir>/functions` instead of `path`.
* `NodePackageNpmCheckResult`: `isOk`, `isConstraintOk`, `isInstalledOk`,
  `npmInstallNeeded`, `issues` / `constraintIssues` / `installedIssues`
  (`List<String>`), `dependencies` (`List<NodePackageNpmDependencyCheck>` with
  `name`, `constraint`, `installedVersion`, `isDevDependency`, `minConstraint`,
  `required`, `isOk`, `constraintIssue`, `installedIssue`),
  `packageJsonExists`, `nodeModulesExists`. `Version` and `VersionConstraint`
  (`package:pub_semver`) are re-exported by `npm_build.dart`.
* Aliyun Function Compute (`afc_build.dart`, uses the `fun` CLI):
  `afcNodeBuild({directory, deployDirectory})`, `afcNodeCopyToDeploy(...)`,
  `afcNodeDeploy({deployDirectory})` returning an `AfcDeployResult` whose `url`
  is parsed from the `fun deploy` output, and `afcNodeServe(...)`.
* `gcfNodePackageServeFunctionsCommand`, `gcfNodePackageDeployFunctionsCommand`
  and the `gcfDeployDirDefault` constants live in `src/gcf_common.dart` and are
  not exported: do not import them from application code.
* All of these shell out and throw a `ShellException` when the CLI fails; they
  print the command output as it comes, they do not parse it (except
  `afcNodeDeploy`).

## Examples

### tool/dev.dart: build then emulate or deploy

```dart
import 'package:tekartik_app_node_build/gcf_build.dart';

var builder = GcfNodeAppBuilder(
  options: GcfNodeAppOptions(
    projectId: 'my-project-dev',
    packageTop: '.',
    srcDir: 'bin',
    srcFile: 'main.dart',
    port: 5001,
  ),
);

Future<void> main(List<String> args) async {
  if (args.contains('deploy')) {
    await builder.buildAndDeployFunctions();
  } else {
    await builder.buildAndServeFunctions();
  }
}
```

### Dev and prod variants with copyWith and a single function

```dart
import 'package:tekartik_app_node_build/gcf_build.dart';

var devOptions = GcfNodeAppOptions(
  projectId: 'my-project-dev',
  functions: ['api'],
);
var prodOptions = devOptions.copyWith(projectId: 'my-project-prod');

Future<void> deployProd() async {
  var builder = GcfNodeAppBuilder(options: prodOptions);
  await builder.bumpVersion(patch: true);
  await builder.build();
  await builder.deployFunctions(functions: ['api']);
}
```

### Without a builder, on an explicit package path

```dart
import 'package:tekartik_app_node_build/gcf_build.dart';

Future<void> main() async {
  var path = 'packages/my_functions';
  await gcfNodePackageBuild(path, directory: 'bin', srcFile: 'main.dart');
  await gcfNodePackageNpmInstallIfNeeded(path);
  await gcfNodePackageServeFunctions(path, projectId: 'my-project-dev', port: 5001);
}
```

### Checking the npm dependencies of the generated functions package

```dart
import 'dart:io';

import 'package:tekartik_app_node_build/npm_build.dart';

Future<void> main() async {
  var result = await nodePackageNpmInstallIfNeeded(
    'deploy/functions',
    minConstraints: {'firebase-admin': '^14.4.0', 'firebase-functions': '^7.0.0'},
    requiredDependencies: ['firebase-admin'],
    updatePackageJson: true,
  );
  if (!result.isOk) {
    for (var issue in result.issues) {
      stderr.writeln(issue);
    }
    exitCode = 1;
  }
}
```

### Aliyun function compute build and deploy

```dart
import 'dart:io';

import 'package:tekartik_app_node_build/afc_build.dart';

Future<void> main() async {
  await afcNodeBuild(directory: 'bin'); // build/bin/main.dart.js -> deploy/index.js
  var result = await afcNodeDeploy();
  stdout.writeln('deployed at ${result.url}');
}
```

## Common mistakes

* Deploying without `firebase init` in `deploy/`: the build writes
  `deploy/functions/index.js` but the CLI has no `firebase.json` to read.
* Passing `functions: ['api']` to a deploy and expecting the other functions to
  survive a `force: true` run: `--force` deletes functions missing from the
  deploy folder.
* Relying on `getDefaultProjectId()` without setting
  `TEKARTIK_FIREBASE_PROJECT_ID`: the command then runs with
  `--project -unset-project-id-`.
* Calling `serve()` (legacy `firebase serve`) when you want the emulator suite:
  use `serveFunctions()`.
* Running the npm check against the package root instead of
  `deploy/functions` (or using the `gcfNodePackage*` helpers, which add it).
