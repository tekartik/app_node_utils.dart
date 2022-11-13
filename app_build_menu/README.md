# tekartik_build_menu_flutter

Flutter build utils in a menu

## Setup

In `pubspec.yaml`:

```yaml
dev_dependencies:
  tekartik_app_node_build_menu:
    git: 
        url: https://github.com/tekartik/app_node_utils.dart
        ref: dart2_3
        path: app_build_menu
    version: '>=0.3.0'
    
  ...
  
  # Needed direct dependencies
  build_runner:
  build_web_compilers:
```
      
## nbm command

To activate

```shell
dart pub global activate -s path .
```

Run `nbm` to see the menu

See [app_build setup](../app_build/README.md) for more info