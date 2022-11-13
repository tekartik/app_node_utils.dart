import 'package:stack_trace/stack_trace.dart';
import 'package:tekartik_app_node_utils/node_utils.dart';

Future main() async {
  print('Hi node utils ${platform.environment}');
  console.out.writeln('console.out');
  console.out.writeln('console.err');

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
