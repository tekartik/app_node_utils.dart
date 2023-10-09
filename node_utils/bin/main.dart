import 'package:stack_trace/stack_trace.dart';
import 'package:tekartik_app_node_utils/node_utils.dart';
// ignore: depend_on_referenced_packages
import 'package:tekartik_common_utils/env_utils.dart';

Future main() async {
  print('Hi node utils ${platform.environment}');
  console.out.writeln('console.out');
  console.err.writeln('console.err');
  console.out.writeln('isDebug: $isDebug');

  //assert(1 == 0);
  assert(() {
    print('running assert');
    return true;
  }());
  void testThrow() {
    try {
      throw StateError('simple exception');
    } catch (e, st) {
      print(e);
      print('original stack trace');
      print(st);
      print('formatted');
      print(Trace.format(st));
    }
  }

  testThrow();
  print('End of main success');
}
