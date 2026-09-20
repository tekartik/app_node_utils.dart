---
name: tekartik-app-node-build-setup
description: >-
  Use when writing tool/ scripts that compile a Dart package to a Node.js app
  with tekartik_app_node_build: NodeAppBuilder and NodeAppOptions
  (packageTop/deployDir/srcDir/srcFile), compile(), compileAndRun(), run(),
  copyToDeploy(), clean(), the nodeBuild/nodeRun/nodeBuildAndRun/nodeRunTest
  shortcuts, nodePackageBuild, nodePackageCompileJs, nodePackageCopyToDeploy,
  nodePackageRun, nodePackageClean, nodePackageRunTest, nodePackageRunCi with
  NodePackageRunCiOptions, NodeAppRunOptions, the build.yaml dart2js setup and
  the deploy/index.js output.
---

# Dart to Node build scripts (tekartik_app_node_build)

`tekartik_app_node_build` drives the Dart-to-JavaScript compilation of a node
app: compile `bin/main.dart` with dart2js (through `tekartik_build_node`), copy
the result to `deploy/index.js`, run it with `node`, and run the package CI
(`dart analyze`, `dart format`, vm and node tests). Everything uses `dart:io`
and shells out, so it belongs in `tool/` scripts, never in the app code itself.
For Google Cloud Functions / Firebase deployment and the npm dependency checks,
see [tekartik-app-node-build-gcf](../tekartik-app-node-build-gcf/SKILL.md).

## Guidelines

* Git dependency (not on pub.dev), normally in `dev_dependencies` of the node
  app package:
  ```yaml
  dev_dependencies:
    tekartik_app_node_build:
      git:
        url: https://github.com/tekartik/app_node_utils.dart
        path: app_build
      version: '>=0.1.0'
    # Needed direct dependencies of the app itself
    build_runner:
    build_web_compilers:
  ```
  `node` and `npm` must be on the PATH.
* Imports: `package:tekartik_app_node_build/app_build.dart` is the entry point
  for a plain node app. It re-exports the `tekartik_build_node` primitives
  (`nodePackageBuild`, `nodePackageCheck`, `nodePackageRunTest`,
  `nodePackageCompileJs`, `nodePackageRunCi`, `NodePackageRunCiOptions`).
  `package:tekartik_app_node_build/package.dart` only re-exports
  `nodePackageRunCi` / `NodePackageRunCiOptions` (handy for `tool/run_ci.dart`).
* Required `build.yaml` at the package root, or the build warns
  (`Missing 'build.yaml'`) and produces nothing:
  ```yaml
  targets:
    $default:
      sources: ["$package$", "lib/**", "bin/**", "test/**"]
      builders:
        build_web_compilers|entrypoint:
          generate_for: [bin/**]
          options:
            compiler: dart2js
  ```
  Add `build/**` to the `analyzer: exclude:` list of `analysis_options.yaml`,
  and a `dart_test.yaml` with `platforms: [node]` (or `[node, vm]`).
* Prefer `NodeAppBuilder` over the bare functions.
  `NodeAppOptions({packageTop, deployDir, srcDir, srcFile})` defaults to
  `packageTop: '.'`, `deployDir: 'deploy'`, `srcDir: 'bin'`,
  `srcFile: 'main.dart'`.
  - `compile()` runs `nodePackageCompileJs` on `<srcDir>/<srcFile>` (direct
    `dart compile js`, no `build_runner`) then copies the output to
    `<deployDir>/<basename>.js`.
  - `run({basename, runOptions})` copies again and runs `node
    deploy/<basename>.js`, after an `npm install` in the deploy folder when it
    has a `package.json` but no `node_modules`.
  - `compileAndRun({runOptions})` is the usual one-shot for `tool/`.
  - `copyToDeploy({basename})` and `clean()` (deletes `build/` and
    `deploy/index.js`) round it out.
  - `build()` and `buildAndRun()` still exist but go through `build_runner`
    and are documented as superseded by `compile()` / `compileAndRun()`.
* `NodeAppRunOptions({required Stream<List<int>>? stdin})` is the only run
  option: pass `NodeAppRunOptions(stdin: stdin)` (from `dart:io`) to forward
  the terminal input to the spawned node process, `stdin: null` to close it.
* Package-level functions, all taking the package path as first argument:
  `nodePackageBuild(path, directory: 'node', debug: )` (build_runner),
  `nodePackageCompileJs(path, input: , output: , debug: , optimizationLevel: )`
  (dart2js, `input` defaults to `node/main.dart`),
  `nodePackageCopyToDeploy(path, directory: , deployDirectory: , basename: )`
  (copies `build/<directory>/<basename>.dart.js` to
  `<deployDirectory>/<basename>.js`), `nodePackageRun(path, deployDirectory: ,
  basename: , runOptions: )`, `nodePackageClean(path)`,
  `nodePackagePathNpmInstall(path, force: )`.
* Current-directory shortcuts (they operate on `.`, `directory` defaults to
  `bin`): `nodeBuild()`, `nodeCopyToDeploy(directory: , dstDir: )`,
  `nodeRun()`, `nodeBuildAndRun()`, `nodeRunTest()`. Use them for one-liner
  `tool/` scripts; use the `nodePackage*` variants for multi-package repos.
* Tests: `nodePackageRunTest(path, testFiles: )` runs `dart test -p node` in
  that package after checking `build.yaml` and installing node modules;
  `nodeRunTest()` does the same in the current directory.
* CI: `tool/run_ci.dart` calling `nodePackageRunCi('.')` runs pub get, format,
  analyze, then the vm and node tests. Narrow it with
  `NodePackageRunCiOptions(noNodeTest: , noVmTest: , noPubGet: , noFormat: ,
  noAnalyze: , noNpmInstall: , noOverride: )`. A `tool/run_ci_override.dart`
  file in the package takes over unless `noOverride` is true.
* These functions shell out and print to stdout/stderr; they throw a
  `ShellException` on failure. Nothing returns the compiled path, so rely on
  the conventional `build/` and `deploy/` layout.
* Do not import `package:tekartik_app_node_build/src/...`; `afc_build.dart`
  (Aliyun Function Compute) and `gcf_build.dart` are the only other public
  entry points.

## Examples

### tool/run_ci.dart

```dart
import 'package:tekartik_app_node_build/package.dart';

Future<void> main() async {
  await nodePackageRunCi('.');
}
```

### tool/compile_and_run.dart with explicit options

```dart
import 'package:tekartik_app_node_build/app_build.dart';

Future<void> main() async {
  var builder = NodeAppBuilder(
    options: NodeAppOptions(
      packageTop: '.',
      srcDir: 'bin',
      srcFile: 'main.dart',
      deployDir: 'deploy',
    ),
  );
  await builder.clean();
  await builder.compileAndRun();
}
```

### One-liner build, copy and run in the current package

```dart
import 'package:tekartik_app_node_build/app_build.dart';

Future<void> main(List<String> args) async {
  if (args.contains('build')) {
    await nodeBuild(); // build_runner + dart2js on bin/
    await nodeCopyToDeploy(); // build/bin/main.dart.js -> deploy/index.js
    return;
  }
  await nodeBuildAndRun(); // build, copy, then `node deploy/index.js`
}
```

### Forwarding stdin to the node process

```dart
import 'dart:io';

import 'package:tekartik_app_node_build/app_build.dart';

Future<void> main() async {
  var builder = NodeAppBuilder(options: NodeAppOptions(srcFile: 'server.dart'));
  await builder.compile();
  await builder.run(runOptions: NodeAppRunOptions(stdin: stdin));
}
```

### Running the node tests of another package

```dart
import 'package:tekartik_app_node_build/app_build.dart';

Future<void> main() async {
  var path = 'packages/my_node_app';
  await nodePackageCheck(path); // warns when build.yaml is missing
  await nodePackageRunTest(path); // dart test -p node
  await nodePackageRunCi(path, NodePackageRunCiOptions(noVmTest: true));
}
```

## Common mistakes

* Calling `nodePackageBuild(path)` without `directory:` when the sources are in
  `bin/`: the default directory is `node`.
* Forgetting `build.yaml` or the `build_runner` / `build_web_compilers` dev
  dependencies: the build silently produces no `build/bin/main.dart.js`.
* Importing `app_build.dart` from the node app code: it is `dart:io` tooling
  for `tool/` scripts only.
* Expecting `clean()` to remove the whole `deploy/` folder: it only deletes
  `build/` and `deploy/index.js`.
