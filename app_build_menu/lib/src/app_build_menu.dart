import 'package:dev_build/build_support.dart';
import 'package:dev_build/menu/menu_io.dart';
import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_node_build/app_build.dart';
import 'package:tekartik_app_node_build/gcf_build.dart';

Future main(List<String> arguments) async {
  mainMenuConsole(arguments, menuAppContent);
}

void gcfMenuAppContent({
  List<GcfNodeAppBuilder>? builders,
  GcfNodeAppOptions? options,
}) {
  if (builders != null) {
    for (var builder in builders) {
      menu(
        'target ${builder.target ?? '${builder.options.projectId} - ${basename(builder.options.srcDir)}'}',
        () {
          gcfMenuAppBuilderContent(builder: builder);
        },
      );
    }
  } else {
    var builder = GcfNodeAppBuilder(options: options);
    gcfMenuAppBuilderContent(builder: builder);
  }
}

void gcfMenuAppBuilderContent({required GcfNodeAppBuilder builder}) {
  menu('npm', () {
    item('npm install', () async {
      await builder.npmInstall();
    });
    item('npm upgrade firebase-functions', () async {
      await builder.npmUpgrade();
    });
    item('npm upgrade firebase-admin', () async {
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
    item('serveFunctions', () async {
      await builder.serveFunctions();
    });
    item('clean', () async {
      await builder.clean();
    });

    item('build & serve', () async {
      await builder.buildAndServe();
    });
    item('build & serve functions', () async {
      await builder.buildAndServeFunctions();
    });
    item('deployFunctions', () async {
      await builder.deployFunctions();
    });

    item('build and deploy functions', () async {
      await builder.buildAndDeployFunctions();
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
    return <String, Object?>{};
  }();

  menu('pub', () async {
    enter(() async {
      write('App path: ${absolute(path)}');
      var pubspec = await checkPubspec;
      write('Package: ${pubspec['name']}');
    });

    item('list sub projects', () async {
      await recursivePackagesRun(
        [path],
        action: (path) {
          write('project: ${absolute(path)}');
        },
      );
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
      await packageRunCi(
        path,
        options: PackageRunCiOptions(pubUpgradeOnly: true),
      );
    });
  });
}
