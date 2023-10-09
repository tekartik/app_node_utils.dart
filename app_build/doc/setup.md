## Setup

- Create a dart package project
- Add dependency

    In `pubspec.yaml`:
    ```yaml
    dev_dependencies:
      tekartik_app_node_build:
        git:
          url: https://github.com/tekartik/app_node_utils.dart
          path: app_build
          ref: dart3a
        version: '>=0.1.0'
    
      # Needed direct dependencies
      build_runner:
      build_web_compilers:
    ```
- create `tool/run_ci.dart` doc (you can copy it from here)

    ```dart
    import 'package:tekartik_app_node_build/package.dart';
    
    Future main() async {
      await nodePackageRunCi('.');
    }
    ```
- create `build.yaml`

    ```yaml
    targets:
      $default:
        sources:
          - "$package$"
          - "lib/**"
          - "bin/**"
          - "test/**"
        builders:
          build_web_compilers|entrypoint:
            generate_for:
            - bin/**
            options:
              compiler: dart2js
    ```
  
- In `analysis_options.yaml` add

    ```yaml
    analyzer:
      exclude:
        - build/**
    ```