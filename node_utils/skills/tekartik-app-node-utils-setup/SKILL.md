---
name: tekartik-app-node-utils-setup
description: >-
  Use when writing Dart code that must run both on node (compiled with dart2js
  through build_runner/build_web_compilers) and on the Dart VM with
  tekartik_app_node_utils: the console/console.out/console.err ConsoleSink
  writeln output, the platform getter and its environment map, platformContext
  (PlatformContext with .node/.io/.browser), the
  package:tekartik_app_node_utils/node_utils.dart import, dart_test.yaml with
  the node platform, and the bin/ dart2js build.yaml setup for a node app.
---

# Node/VM runtime utilities (tekartik_app_node_utils)

`tekartik_app_node_utils` is a thin universal-platform layer for Dart code that
is compiled to node *and* run on the Dart VM: a `console` sink that maps to
`console.log`/`console.error` on node and to `stdout`/`stderr` on io, plus a
`platform`/`platformContext` pair giving the environment variables and the
current platform on either side. It is deliberately tiny; the build/deploy side
lives in the sibling packages `tekartik_app_node_build` and
`tekartik_app_node_build_menu`.

## Guidelines

* Git dependency (not on pub.dev):
  ```yaml
  dependencies:
    tekartik_app_node_utils:
      git:
        url: https://github.com/tekartik/app_node_utils.dart
        path: node_utils
      version: '>=0.1.0'
  ```
* Single import: `package:tekartik_app_node_utils/node_utils.dart`. It exports
  exactly three names: `console`, `platform` and `platformContext`. Everything
  else under `lib/src/` is private to the package; never import it.
* The library is safe to import anywhere: the implementation is picked with a
  conditional import (`dart.library.js_interop` -> node, `dart.library.io` ->
  io, otherwise a stub). On the stub `platform` and `platformContext` throw
  `UnsupportedError`, and `console` is a no-op sink.
* `console.out` and `console.err` are `ConsoleSink`s (a `Sink<List<int>>` and
  `StringSink`). Only `writeln()` is implemented on node, where it forwards to
  `console.log` / `console.error`; `write`, `writeAll`, `writeCharCode` and
  `add` are no-ops there. Always use `console.out.writeln(...)` /
  `console.err.writeln(...)` and build the whole line yourself.
* On io, `console` writes to `stdout` / `stderr` and every `StringSink` method
  works, but do not rely on that in shared code.
* `print()` also works on node (dart2js maps it to `console.log`), but it does
  not give you a stderr channel: use `console.err` for errors.
* `platform.environment` is a `Map<String, String>`: `process.env` on node,
  `shellEnvironment` from `package:process_run/shell.dart` on io (so it honors
  process_run's user environment, not just `Platform.environment`).
* `platformContext` is a `PlatformContext` from
  `package:tekartik_platform/context.dart` (`platformContextNode` on node,
  `platformContextIo` on io). Use `platformContext.node`, `.io`, `.browser`
  (nullable) to branch, and `platform.isWindows` / `isMacOS` / `isLinux` on
  the non-null one. Add an explicit `tekartik_platform` dependency if you want
  to name the `PlatformContext`, `Node` or `Io` types in your own signatures:
  this package does not re-export them.
* Do not instantiate anything: `console`, `platform` and `platformContext` are
  top-level getters/finals, there is no factory to configure.
* Tests: declare the platforms in `dart_test.yaml`
  ```yaml
  platforms:
    - node
    - vm
  ```
  and mark VM/node-only tests with `@TestOn('node || vm')`. Running the node
  platform requires `node` on the PATH and `build_web_compilers` +
  `tekartik_build_node` in `dev_dependencies`; `dart test -p vm` alone needs
  nothing extra.
* A node executable is `bin/main.dart` compiled with dart2js via `build.yaml`:
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
  Then drive the build from `tool/` scripts with `nodeRun()`,
  `nodeRunTest()` or `NodeAppBuilder().buildAndRun()` from
  `tekartik_app_node_build` (dev dependency), rather than calling `webdev` or
  `build_runner` by hand.
* Stack traces from dart2js output are unreadable raw: format them with
  `Trace.format(stackTrace)` from `package:stack_trace/stack_trace.dart`.

## Examples

### Node entry point printing the environment

```dart
import 'package:tekartik_app_node_utils/node_utils.dart';

Future<void> main() async {
  console.out.writeln('running on node: ${platformContext.node != null}');
  console.out.writeln('HOME: ${platform.environment['HOME']}');
  console.err.writeln('this one goes to stderr / console.error');
}
```

### Branching on the platform context

```dart
import 'package:tekartik_app_node_utils/node_utils.dart';

String describeHost() {
  var context = platformContext;
  var node = context.node;
  if (node != null) {
    return 'node (windows: ${node.isWindows})';
  }
  var io = context.io;
  if (io != null) {
    return 'io (linux: ${io.isLinux})';
  }
  return 'unsupported';
}
```

### Error reporting with a formatted stack trace

```dart
import 'package:stack_trace/stack_trace.dart';
import 'package:tekartik_app_node_utils/node_utils.dart';

Future<void> runSafe(Future<void> Function() action) async {
  try {
    await action();
  } catch (e, st) {
    console.err.writeln('failed: $e');
    console.err.writeln(Trace.format(st));
  }
}
```

### Test running on both node and vm

```dart
@TestOn('node || vm')
library;

import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:test/test.dart';

void main() {
  test('environment', () {
    expect(platform.environment, isNotEmpty);
  });
  test('console', () {
    console.out.writeln('console out');
    console.err.writeln('console err');
  });
}
```

### tool/ scripts building and running the node app

```dart
// tool/run_main.dart: compiles bin/main.dart with dart2js and runs it on node.
import 'package:tekartik_app_node_build/app_build.dart';

Future<void> main() async {
  await NodeAppBuilder().buildAndRun();
}
```

## Common mistakes

* Using `console.out.write(...)` or `writeAll(...)` and seeing nothing on node:
  only `writeln` is implemented there.
* Importing `package:tekartik_app_node_utils/src/console/console.dart` or
  `src/node.dart` directly instead of `node_utils.dart`.
* Expecting `platformContext.browser` to be non-null: this package targets node
  and io, not the browser.
* Naming `PlatformContext` in your code without adding the `tekartik_platform`
  git dependency (`url: https://github.com/tekartik/platform.dart`,
  `path: platform`).
