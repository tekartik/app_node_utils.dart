import 'dart:io';

/// Convert main.dart to index.js
Future nodeCopyToDeploy(
    {String directory = 'bin', String dstDir = 'deploy'}) async {
  var src = File('build/$directory/main.dart.js');
  Future copy() async {
    var file = await src.copy('$dstDir/index.js');
    print('copied to ${file} ${await file.stat()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(dstDir).create(recursive: true);
    await copy();
  }
}
