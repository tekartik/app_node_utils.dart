import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// true if flutter is supported
final isNodeSupported = whichSync('node') != null;

/// Install node modules for test.
Future nodeTestCheck(String dir) async {
  if ((File(join(dir, 'package.json')).existsSync())) {
    if (!(Directory(join(dir, 'node_modules')).existsSync())) {
      await Shell(workingDirectory: dir).run('npm install');
    }
  }
}
