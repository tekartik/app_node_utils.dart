import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:test/test.dart';

void main() {
  group('console', () {
    test('out', () {
      console.out!.writeln('console out');
    });
    test('err', () {
      console.err!.writeln('console err');
    });
  });
}
