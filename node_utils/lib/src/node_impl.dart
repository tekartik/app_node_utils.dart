import 'package:tekartik_app_node_utils/src/node_common.dart';
import 'package:tekartik_platform/context.dart' as pc;
import 'package:tekartik_platform_node/context_node.dart' as pc;

pc.PlatformContext get platformContext => pc.platformContextNode;

class PlatformNode implements Platform {
  @override
  Map<String, String> get environment => platformContext.node!.environment;
}

final platform = PlatformNode();
