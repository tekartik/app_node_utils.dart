import 'package:process_run/shell.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var shell = Shell();

  if (dartVersion >= Version(2, 12, 0, pre: '0')) {
    for (var dir in [
      'app_build',
      'node_utils',
    ]) {
      shell = shell.pushd(join('..', dir));
      await shell.run('''
    
    pub get
    dart tool/travis.dart
    
''');
      shell = shell.popd();
    }
  }
}
