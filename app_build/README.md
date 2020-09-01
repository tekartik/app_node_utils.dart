A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Setup

## Pure node project

Dependencies:
```yaml
  # Needed direct dependencies
  build_runner:
  build_node_compilers:
```

Create a dart_test.yaml:
```yaml
# This package's tests are very slow. Double the default timeout.
timeout: 2x

# This is a node-only package, so test on node.
platforms: [node]
```
## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
