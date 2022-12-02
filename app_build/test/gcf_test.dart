@TestOn('vm')
import 'package:tekartik_app_node_build/src/gcf_common.dart';
import 'package:test/test.dart';

void main() {
  group('gcf', () {
    group('option', () {
      test('no param', () {
        GcfNodeAppOptions();
      });
    });
    test('gcfNodePackageServeFunctionsCommand', () {
      expect(gcfNodePackageServeFunctionsCommand(),
          'firebase serve --only functions');
      expect(gcfNodePackageServeFunctionsCommand(projectId: 'my_prj'),
          'firebase --project my_prj serve --only functions');
      expect(
          gcfNodePackageServeFunctionsCommand(
              projectId: 'my_prj', functions: ['function1', 'function2']),
          'firebase --project my_prj serve --only functions:function1,functions:function2');
    });
    test('gcfNodePackageDeployFunctionsCommand', () {
      expect(gcfNodePackageDeployFunctionsCommand(),
          'firebase deploy --only functions');
      expect(gcfNodePackageDeployFunctionsCommand(projectId: 'my_prj'),
          'firebase --project my_prj deploy --only functions');
      expect(
          gcfNodePackageDeployFunctionsCommand(
              functions: ['function1', 'function2']),
          'firebase deploy --only functions:function1,functions:function2');
    });
  });
}
