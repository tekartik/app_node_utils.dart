import 'package:dev_test/build_support.dart';
import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_node_build/app_build.dart';
import 'package:tekartik_app_node_build/gcf_build.dart';
import 'package:tekartik_test_menu_io/test_menu_io.dart';

Future main(List<String> arguments) async {
  mainMenu(arguments, menuAppContent);
}

void gcfMenuAppContent({required GcfNodeAppOptions? options}) {
  var builder = GcfNodeAppBuilder(options: options);
  menu('npm', () {
    item('npm install', () async {
await builder.npmInstall();
    });
    item('npm upgrade', () async {
      await builder.npmUpgrade();
    });

  });
  menu('gcf_build', () {
    item('build', () async {
      await builder.build();
    });
    item('serve', () async {
      await builder.serve();
    });
    item('clean', () async {
      await builder.clean();
    });

    item('build & serve', () async {
      await builder.buildAndServe();
    });
    item('deployFunction', () async {
      await builder.deployFunctions();
    });

  });
}

void nodeMenuAppContent({required NodeAppOptions options}) {
  var builder = NodeAppBuilder(options: options);
  menu('node_build', () {
    item('build', () async {
      await builder.build();
    });
    item('run', () async {
      await builder.run();
    });
    item('clean', () async {
      await builder.clean();
    });

    item('build & run', () async {
      await builder.buildAndRun();
    });
  });
}

void menuAppContent({String path = '.'}) {
  Map pubspec;
  var checkPubspec = () async {
    try {
      pubspec = await pathGetPubspecYamlMap(path);
      return pubspec;
    } catch (_) {}
    return {};
  }();

  menu('pub', () async {
    enter(() async {
      write('App path: ${absolute(path)}');
      var pubspec = await checkPubspec;
      write('Package: ${pubspec['name']}');
    });

    item('list sub projects', () async {
      await recursivePackagesRun([path], action: (path) {
        write('project: ${absolute(path)}');
      });
    });

    item('run_ci', () async {
      await packageRunCi(path);
    });
    item('run_ci (node)', () async {
      await nodePackageRunCi(path);
    });
    item('pub_get', () async {
      await packageRunCi(path, options: PackageRunCiOptions(pubGetOnly: true));
    });
    item('pub_upgrade', () async {
      await packageRunCi(path,
          options: PackageRunCiOptions(pubUpgradeOnly: true));
    });
  });
}
