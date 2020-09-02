import 'package:dev_test/package.dart';

Future main() async {
  for (var dir in [
    'app_build',
    'node_utils',
  ]) {
    print('project: $dir');
    await ioPackageRunCi(dir);
  }
}
