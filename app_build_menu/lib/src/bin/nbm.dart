import 'dart:io';

import 'package:args/args.dart';
import 'package:tekartik_app_node_build_menu/app_build_menu.dart';

Future<void> main(List<String> arguments) async {
  nbm(arguments);
}

/// Node build menu
void nbm(List<String> arguments) {
  var parser = ArgParser();
  var result = parser.parse(arguments);
  var appPath = result.rest;

  if (appPath.isEmpty) {
    appPath = [Directory.current.path];
  }
  mainMenu(appPath.sublist(1), () {
    menuAppContent(path: appPath.first);
  });
}
