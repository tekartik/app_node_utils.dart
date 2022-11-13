import 'package:tekartik_app_node_build_menu/app_build_menu.dart';
import 'package:tekartik_app_node_build_menu/src/bin/nbm.dart';

Future<void> main(List<String> arguments) async {
  nbm(arguments);
  nodeMenuAppContent(options: NodeAppOptions());
}
