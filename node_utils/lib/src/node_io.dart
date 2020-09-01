import 'package:tekartik_app_node_utils/src/node_common.dart';
import 'package:tekartik_platform/context.dart' as pc;
import 'package:tekartik_platform_io/context_io.dart' as pc;

pc.PlatformContext get platformContext => pc.platformContextIo;

class PlatformIo implements Platform {
  @override
  Map<String, String> get environment => platformContext.io.environment;
}

final platform = PlatformIo();
