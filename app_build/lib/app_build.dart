/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'package:tekartik_build_node/build_node.dart'
    show nodePackageBuild, nodePackageCheck, nodePackageRunTest;
export 'package:tekartik_build_node/package.dart'
    show nodePackageRunCi, NodePackageRunCiOptions;

export 'src/build.dart'
    show
        nodePackageRun,
        nodePackageCopyToDeploy,
        nodePackageClean,
        NodeAppBuilder;
export 'src/build_common.dart' show NodeAppOptions;
export 'src/copy_to_deploy.dart' show nodeCopyToDeploy;
export 'src/run.dart' show nodeBuild, nodeRun, nodeBuildAndRun, nodeRunTest;

// TODO: Export any libraries intended for clients of this package.
