import 'package:process_run/shell_run.dart';

import 'copy_to_deploy.dart';

Future build({String directory = 'bin'}) async {
  var shell = Shell();
  await shell.run('''
# pub run build_runner build --output=$directory:build/$directory -- -p node
pub run build_runner build --output=build/ -- -p node
''');
  await nodeCopyToDeploy(directory: directory);
}
