@TestOn('node || vm')
library;

import 'package:test/test.dart';

void main() {
  test('print', () {
    print('raw print');
  });
}
