import 'package:dev_test/package.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:process_run/shell.dart';

Future main() async {
  if (dartVersion >= Version(2, 12, 0, pre: '0')) {
    for (var dir in [
      'app_build',
      'node_utils',
    ]) {
      await packageRunCi(join('..', dir));
    }
  }
}
