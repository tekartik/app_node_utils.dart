App node build utilities for Google function and Alibaba function compute.

See https://github.com/tekartik/build_node.dart for raw node build

## Setup

- See [setup](doc/setup.md)
- See [setup node only](doc/setup_node_only.md)

## Run test

```dart
await nodePackageRunCi('.');
```

## npm dependencies check

`package:tekartik_app_node_build/npm_build.dart` checks the `package.json`
of a node package against hard-coded minimum constraints and the installed
`node_modules`, running `npm install` only when needed:

```dart
import 'package:tekartik_app_node_build/npm_build.dart';

Future<void> main() async {
  var result = await nodePackageNpmInstallIfNeeded(
    '.',
    minConstraints: {'firebase-admin': '^14.4.0'},
    // bump package.json if below the minimum
    updatePackageJson: true,
  );
  print(result.isOk);
}
```

`nodePackageNpmCheck` does the same check without installing anything,
`gcfNodePackageNpmInstallIfNeeded` / `GcfNodeAppBuilder.npmInstallIfNeeded`
target the generated `deploy/functions` package.
