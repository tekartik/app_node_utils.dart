import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('platform', () {
      expect(platform.environment, isNotEmpty);
    });
  });
}
