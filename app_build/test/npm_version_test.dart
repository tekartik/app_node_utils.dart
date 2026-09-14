@TestOn('vm')
library;

import 'package:tekartik_app_node_build/npm_build.dart';
import 'package:test/test.dart';

void main() {
  group('npm_version', () {
    test('npmVersionParse', () {
      expect(npmVersionParse('1.2.3'), Version(1, 2, 3));
      expect(npmVersionParse('v1.2.3'), Version(1, 2, 3));
      expect(npmVersionParse('=1.2.3'), Version(1, 2, 3));
      expect(npmVersionParse(' 1.2.3 '), Version(1, 2, 3));
      expect(npmVersionParse('1.2.3-beta.1'), Version.parse('1.2.3-beta.1'));
      expect(npmVersionParse('1.2.3+build'), Version.parse('1.2.3+build'));
      expect(() => npmVersionParse('1.2'), throwsFormatException);
      expect(() => npmVersionParse('^1.2.3'), throwsFormatException);
      expect(() => npmVersionParse('dummy'), throwsFormatException);
      expect(npmVersionTryParse('1.2.3'), Version(1, 2, 3));
      expect(npmVersionTryParse('1.2'), isNull);
      expect(npmVersionTryParse(null), isNull);
    });

    test('npmVersionConstraintIsRegistry', () {
      expect(npmVersionConstraintIsRegistry('^1.2.3'), isTrue);
      expect(npmVersionConstraintIsRegistry('*'), isTrue);
      expect(npmVersionConstraintIsRegistry(''), isTrue);
      expect(npmVersionConstraintIsRegistry('file:../local'), isFalse);
      expect(npmVersionConstraintIsRegistry('github:user/repo'), isFalse);
      expect(npmVersionConstraintIsRegistry('user/repo'), isFalse);
      expect(
        npmVersionConstraintIsRegistry('https://example.com/pkg.tgz'),
        isFalse,
      );
      expect(npmVersionConstraintIsRegistry('npm:other@1.0.0'), isFalse);
    });

    void expectRange(
      String text,
      String expected, {
      List<String> allowed = const [],
      List<String> notAllowed = const [],
    }) {
      var constraint = npmVersionConstraintParse(text);
      expect(constraint.toString(), expected, reason: text);
      for (var version in allowed) {
        expect(
          constraint.allows(Version.parse(version)),
          isTrue,
          reason: '$text should allow $version',
        );
      }
      for (var version in notAllowed) {
        expect(
          constraint.allows(Version.parse(version)),
          isFalse,
          reason: '$text should not allow $version',
        );
      }
    }

    test('any', () {
      for (var text in ['*', '', ' ', 'x', 'X', 'latest', '*.x']) {
        expect(npmVersionConstraintParse(text), VersionConstraint.any);
      }
    });

    test('exact', () {
      expectRange('1.2.3', '1.2.3', allowed: ['1.2.3'], notAllowed: ['1.2.4']);
      expectRange('=1.2.3', '1.2.3');
      expectRange('v1.2.3', '1.2.3');
      expectRange('1.2.3-beta.1', '1.2.3-beta.1');
    });

    test('partial', () {
      expectRange(
        '1',
        '>=1.0.0 <2.0.0',
        allowed: ['1.0.0', '1.9.9'],
        notAllowed: ['0.9.9', '2.0.0'],
      );
      expectRange('1.x', '>=1.0.0 <2.0.0');
      expectRange('1.X', '>=1.0.0 <2.0.0');
      expectRange('1.*', '>=1.0.0 <2.0.0');
      expectRange('1.x.x', '>=1.0.0 <2.0.0');
      expectRange(
        '1.2',
        '>=1.2.0 <1.3.0',
        allowed: ['1.2.0', '1.2.9'],
        notAllowed: ['1.1.9', '1.3.0'],
      );
      expectRange('1.2.x', '>=1.2.0 <1.3.0');
      expectRange('1.2.*', '>=1.2.0 <1.3.0');
    });

    test('caret', () {
      expectRange(
        '^14.4.0',
        '>=14.4.0 <15.0.0',
        allowed: ['14.4.0', '14.9.9'],
        notAllowed: ['14.3.9', '15.0.0'],
      );
      expectRange('^1.2.3', '>=1.2.3 <2.0.0');
      expectRange('^1.2', '>=1.2.0 <2.0.0');
      expectRange('^1', '>=1.0.0 <2.0.0');
      expectRange('^0.2.3', '>=0.2.3 <0.3.0');
      expectRange('^0.2', '>=0.2.0 <0.3.0');
      expectRange('^0.0.3', '>=0.0.3 <0.0.4');
      expectRange('^0.0', '>=0.0.0 <0.1.0');
      expectRange('^0.0.x', '>=0.0.0 <0.1.0');
      expectRange('^0', '>=0.0.0 <1.0.0');
      expectRange('^0.x', '>=0.0.0 <1.0.0');
      expectRange('^1.2.3-beta.2', '>=1.2.3-beta.2 <2.0.0');
    });

    test('tilde', () {
      expectRange(
        '~1.2.3',
        '>=1.2.3 <1.3.0',
        allowed: ['1.2.3', '1.2.9'],
        notAllowed: ['1.2.2', '1.3.0'],
      );
      expectRange('~1.2', '>=1.2.0 <1.3.0');
      expectRange('~1', '>=1.0.0 <2.0.0');
      expectRange('~0.2.3', '>=0.2.3 <0.3.0');
      expectRange('~0.2', '>=0.2.0 <0.3.0');
      expectRange('~0', '>=0.0.0 <1.0.0');
    });

    test('comparators', () {
      expectRange(
        '>=1.2.3',
        '>=1.2.3',
        allowed: ['1.2.3'],
        notAllowed: ['1.2.2'],
      );
      expectRange('>= 1.2.3', '>=1.2.3');
      expectRange('>=1.2', '>=1.2.0');
      expectRange(
        '>1.2.3',
        '>1.2.3',
        allowed: ['1.2.4'],
        notAllowed: ['1.2.3'],
      );
      expectRange('>1.2', '>=1.3.0', allowed: ['1.3.0'], notAllowed: ['1.2.9']);
      expectRange(
        '<=1.2.3',
        '<=1.2.3',
        allowed: ['1.2.3'],
        notAllowed: ['1.2.4'],
      );
      expectRange('<=1.2', '<1.3.0', allowed: ['1.2.9'], notAllowed: ['1.3.0']);
      expectRange(
        '<1.2.3',
        '<1.2.3',
        allowed: ['1.2.2'],
        notAllowed: ['1.2.3'],
      );
      expectRange('<1.2', '<1.2.0');
      expectRange('=1.2', '>=1.2.0 <1.3.0');
    });

    test('intersection', () {
      expectRange(
        '>=1.2.3 <2.0.0',
        '>=1.2.3 <2.0.0',
        allowed: ['1.2.3', '1.9.9'],
        notAllowed: ['1.2.2', '2.0.0'],
      );
      expectRange('>=1.2.3   <2.0.0', '>=1.2.3 <2.0.0');
      expectRange('>= 1.2.3 < 2.0.0', '>=1.2.3 <2.0.0');
      expectRange('^1.2.3 <1.5.0', '>=1.2.3 <1.5.0');
      // empty
      expect(
        npmVersionConstraintParse('>=2.0.0 <1.0.0'),
        VersionConstraint.empty,
      );
    });

    test('hyphen', () {
      expectRange(
        '1.2.3 - 2.3.4',
        '>=1.2.3 <=2.3.4',
        allowed: ['1.2.3', '2.3.4'],
        notAllowed: ['1.2.2', '2.3.5'],
      );
      expectRange('1.2 - 2.3.4', '>=1.2.0 <=2.3.4');
      expectRange('1.2.3 - 2.3', '>=1.2.3 <2.4.0');
      expectRange('1.2.3 - 2', '>=1.2.3 <3.0.0');
      expectRange('1.2.3 - *', '>=1.2.3');
    });

    test('union', () {
      expectRange(
        '1.2.3 || >=2.0.0 <3.0.0',
        '1.2.3 or >=2.0.0 <3.0.0',
        allowed: ['1.2.3', '2.5.0'],
        notAllowed: ['1.2.4', '3.0.0'],
      );
      expectRange('^1.0.0 || ^2.0.0', '>=1.0.0 <2.0.0 or >=2.0.0 <3.0.0');
    });

    test('invalid', () {
      for (var text in [
        'dummy',
        'file:../local',
        'github:user/repo',
        'https://example.com/pkg.tgz',
        '^',
        '>=',
        '1.2.3.4',
      ]) {
        expect(
          () => npmVersionConstraintParse(text),
          throwsFormatException,
          reason: text,
        );
        expect(npmVersionConstraintTryParse(text), isNull, reason: text);
      }
      expect(npmVersionConstraintTryParse(null), isNull);
    });

    test('min version', () {
      expect(npmVersionConstraintMinVersion('^14.4.0'), Version(14, 4, 0));
      expect(npmVersionConstraintMinVersion('14.4.0'), Version(14, 4, 0));
      expect(npmVersionConstraintMinVersion('~1.2'), Version(1, 2, 0));
      expect(
        npmVersionConstraintMinVersion('>=1.2.3 <2.0.0'),
        Version(1, 2, 3),
      );
      expect(npmVersionConstraintMinVersion('>1.2.3'), Version(1, 2, 3));
      expect(npmVersionConstraintMinVersion('2'), Version(2, 0, 0));
      expect(
        npmVersionConstraintMinVersion('^2.0.0 || ^1.5.0'),
        Version(1, 5, 0),
      );
      expect(npmVersionConstraintMinVersion('*'), isNull);
      expect(npmVersionConstraintMinVersion('<2.0.0'), isNull);
      expect(npmVersionConstraintMinVersion('file:../local'), isNull);
      expect(npmVersionConstraintMinVersion('dummy'), isNull);
      // empty
      expect(npmVersionConstraintMinVersion('>=2.0.0 <1.0.0'), isNull);
      expect(versionConstraintMinVersion(VersionConstraint.any), isNull);
      expect(versionConstraintMinVersion(VersionConstraint.empty), isNull);
      expect(versionConstraintMinVersion(Version(1, 2, 3)), Version(1, 2, 3));
    });

    test('npmVersionConstraintAllows', () {
      expect(npmVersionConstraintAllows('^14.4.0', Version(14, 4, 0)), isTrue);
      expect(npmVersionConstraintAllows('^14.4.0', Version(14, 2, 0)), isFalse);
      expect(npmVersionConstraintAllows('*', Version(14, 2, 0)), isTrue);
      expect(
        () => npmVersionConstraintAllows('file:../local', Version(1, 0, 0)),
        throwsFormatException,
      );
    });
  });
}
