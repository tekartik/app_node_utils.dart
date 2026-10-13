import 'package:path/path.dart';
import 'package:process_run/stdio.dart';

/// Copies the compiled js file [src] to [dst], creating the destination
/// directory when needed.
Future<File> copyCompiledJsToDeploy(String src, String dst) async {
  await Directory(dirname(dst)).create(recursive: true);
  var file = await File(src).copy(dst);
  stdout.writeln('copied to $file ${file.statSync()}');
  return file;
}
