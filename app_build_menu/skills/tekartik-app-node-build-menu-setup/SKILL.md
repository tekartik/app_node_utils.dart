---
name: tekartik-app-node-build-menu-setup
description: >-
  Use when writing a tool/ console menu that builds, runs, emulates or deploys
  a Dart node app or Google Cloud Function with tekartik_app_node_build_menu:
  mainMenuConsole, menu, item, enter, write, nodeMenuAppContent,
  gcfMenuAppContent, gcfMenuAppBuilderContent, menuAppContent, the re-exported
  NodeAppBuilder/NodeAppOptions/GcfNodeAppBuilder/GcfNodeAppOptions builders,
  and the nbm global command.
---

# Node app build menu (tekartik_app_node_build_menu)

`tekartik_app_node_build_menu` wraps the `tekartik_app_node_build` builders in a
`dev_build` console menu: a single `tool/build_menu.dart` (or `tool/nbm.dart`)
script gives interactive - and scriptable - build / run / serve / deploy items
for a Dart app compiled to node, including Google Cloud (Firebase) Functions
targets. It is `dart:io` tooling: `tool/` and `bin/` only.

## Guidelines

* Git dependency (not on pub.dev), in `dev_dependencies` of the node app
  package:
  ```yaml
  dev_dependencies:
    tekartik_app_node_build_menu:
      git:
        url: https://github.com/tekartik/app_node_utils.dart
        path: app_build_menu
      version: '>=0.3.0'
    # Needed direct dependencies of the app itself
    build_runner:
    build_web_compilers:
  ```
* One import is enough: `package:tekartik_app_node_build_menu/app_build_menu.dart`
  re-exports `package:dev_build/menu/menu_io.dart` (`mainMenuConsole`,
  `initMenuConsole`, `menu`, `item`, `enter`, `leave`, `write`, `writeln`,
  `prompt`, `command`, `menuRun`) plus the whole of
  `tekartik_app_node_build`'s `app_build.dart` (`NodeAppBuilder`,
  `NodeAppOptions`, `nodeBuild`, `nodeRun`, `nodePackageRunCi`, ...),
  `gcf_build.dart` (`GcfNodeAppBuilder`, `GcfNodeAppOptions`,
  `gcfNodePackageBuild`, ...) and `afc_build.dart` (`afcNodeBuild`,
  `afcNodeDeploy`). Do not import those packages again next to it.
* Script shape: `void main(List<String> args) => mainMenuConsole(args, () {
  ...declare menus... });`. The declaration callback is synchronous; only
  `item` (and `enter`) bodies may be async. Run it with
  `dart run tool/build_menu.dart`; extra arguments pick menus/items
  non-interactively, which is how the same script is reused in CI.
* `nodeMenuAppContent(options: NodeAppOptions(...))` declares a `node_build`
  submenu with `build`, `run`, `clean` and `build & run` around a
  `NodeAppBuilder`. `options` is required (use `NodeAppOptions()` for the
  defaults `packageTop: '.'`, `srcDir: 'bin'`, `deployDir: 'deploy'`).
* `gcfMenuAppContent(builders: [...])` declares one `target ...` submenu per
  `GcfNodeAppBuilder`, labelled with the builder's `target` when set, otherwise
  `<projectId> - <srcDir>`. Called with `options:` (and no `builders:`) it
  declares the items inline for a single implicit
  `GcfNodeAppBuilder(options: options)`.
* `gcfMenuAppBuilderContent(builder: )` is the per-builder content, useful
  inside your own `menu(...)`: an `npm` submenu (`npm install`,
  `npm upgrade firebase-functions`, `npm upgrade firebase-admin`) and a
  `gcf_build` submenu (`build`, `serve`, `serveFunctions`, `clean`,
  `build & serve`, `build & serve functions`, `deployFunctions`,
  `build and deploy functions`, and a `setup once` item running
  `firebase functions:artifacts:setpolicy --days 7`, which uses
  `options.region` when set).
* `menuAppContent({path = '.'})` adds an unrelated `pub` submenu for the
  package at `path`: `list sub projects`, `run_ci`, `run_ci (node)`,
  `pub_get`, `pub_upgrade`. Combine it with the build menus in the same
  `mainMenuConsole` callback; it is what the `nbm` command declares.
* Declare the builders/options as top level `var`s so the other tool scripts
  of the package (`tool/build_and_deploy_dev.dart`) reuse exactly the same
  options without the menu.
* The `nbm` executable (`executables: nbm: nbm`) is a ready-made menu for any
  package directory: from this package run `dart pub global activate -s path .`
  then `nbm [<app path> <menu args...>]` (default path: the current
  directory). It only declares `menuAppContent`, i.e. the `pub` submenu; for
  build/deploy items write your own script as shown below.
* Anything beyond `mainMenuConsole` from `package:dev_build/menu/menu_io.dart`
  is a plain `dev_build` menu API: `menu` nests, `item` is a leaf action,
  `enter` runs when a menu is displayed, `write`/`writeln` print inside it.
* Requires `node` and `npm` on the PATH, the `firebase` CLI for the gcf items,
  and the usual `build.yaml` with the `build_web_compilers|entrypoint` dart2js
  target for `bin/**` (see the `tekartik_app_node_build` skills).

## Examples

### Node app menu for the current package

```dart
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

void main(List<String> args) {
  mainMenuConsole(args, () {
    nodeMenuAppContent(options: NodeAppOptions(packageTop: '.', srcDir: 'bin'));
    menuAppContent();
  });
}
```

### Google Cloud Functions targets (dev and prod)

```dart
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

var devBuilder = GcfNodeAppBuilder(
  target: 'dev',
  options: GcfNodeAppOptions(
    projectId: 'my-project-dev',
    packageTop: '.',
    srcFile: 'main.dart',
    port: 5001,
  ),
);
var prodBuilder = GcfNodeAppBuilder(
  target: 'prod',
  options: devBuilder.options.copyWith(projectId: 'my-project'),
);

void main(List<String> args) {
  mainMenuConsole(args, () {
    gcfMenuAppContent(builders: [devBuilder, prodBuilder]);
    menuAppContent();
  });
}
```

### Single implicit gcf builder

```dart
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

void main(List<String> args) {
  mainMenuConsole(args, () {
    gcfMenuAppContent(
      options: GcfNodeAppOptions(
        projectId: 'my-project-dev',
        functions: ['api'],
      ),
    );
  });
}
```

### Custom items next to the generated ones

```dart
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

var builder = GcfNodeAppBuilder(
  options: GcfNodeAppOptions(projectId: 'my-project-dev'),
);

void main(List<String> args) {
  mainMenuConsole(args, () {
    menu('gcf', () {
      enter(() {
        write('project: ${builder.options.projectId}');
        write('deploy: ${builder.deployFullPath}');
      });
      gcfMenuAppBuilderContent(builder: builder);
      item('npm check', () async {
        var result = await builder.npmInstallIfNeeded(
          minConstraints: {'firebase-admin': '^14.4.0'},
        );
        write('npm ok: ${result.isOk}');
      });
    });
  });
}
```

### Menu plus a non-interactive script sharing the options

```dart
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

var appOptions = NodeAppOptions(packageTop: '.', srcFile: 'main.dart');

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    mainMenuConsole(args, () {
      nodeMenuAppContent(options: appOptions);
    });
    return;
  }
  // tool/build_menu.dart build: same options, no menu.
  await NodeAppBuilder(options: appOptions).compileAndRun();
}
```

## Common mistakes

* Making the `mainMenuConsole` callback `async`: only `item`/`enter` bodies
  may be futures.
* Expecting `nbm` to expose build or deploy items: it only declares the `pub`
  submenu (`menuAppContent`).
* Calling `gcfMenuAppContent()` with neither `builders:` nor `options:`: the
  implicit builder then falls back to `getDefaultProjectId()`
  (`TEKARTIK_FIREBASE_PROJECT_ID`, else `-unset-project-id-`).
* Adding `tekartik_app_node_build` imports next to `app_build_menu.dart`:
  everything is already re-exported, so the extra import is redundant (and
  flagged by `unnecessary_import`).
