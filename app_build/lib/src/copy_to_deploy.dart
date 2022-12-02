import 'package:tekartik_app_node_build/src/build.dart';

/// Convert main.dart to index.js
Future nodeCopyToDeploy(
    {String directory = 'bin', String dstDir = 'deploy'}) async {
  await nodePackageCopyToDeploy('.',
      directory: directory, deployDirectory: dstDir);
}
