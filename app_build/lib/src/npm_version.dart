import 'package:pub_semver/pub_semver.dart';

/// Version spec prefixes that don't refer to a published registry version.
const _nonRegistryPrefixes = [
  'file:',
  'link:',
  'portal:',
  'workspace:',
  'git:',
  'git+',
  'github:',
  'http:',
  'https:',
  'npm:',
];

/// True if [constraint] refers to a regular published npm package version
/// range (as opposed to a local path, a git url, an alias...).
bool npmVersionConstraintIsRegistry(String constraint) {
  constraint = constraint.trim();
  for (var prefix in _nonRegistryPrefixes) {
    if (constraint.startsWith(prefix)) {
      return false;
    }
  }
  // git shorthand (`user/repo`)
  if (constraint.contains('/')) {
    return false;
  }
  return true;
}

/// A partial npm version: `1`, `1.2`, `1.2.3`, `1.x`, `1.2.x`, `1.2.3-beta`.
class _NpmPartialVersion {
  final int major;
  final int? minor;
  final int? patch;
  final String? pre;
  final String? build;

  _NpmPartialVersion({
    required this.major,
    this.minor,
    this.patch,
    this.pre,
    this.build,
  });

  /// True if major, minor and patch are all specified.
  bool get isFull => minor != null && patch != null;

  /// The version, missing parts being 0.
  Version get version =>
      Version(major, minor ?? 0, patch ?? 0, pre: pre, build: build);

  /// The first version *not* matched by the partial version.
  ///
  /// `1` -> `2.0.0`, `1.2` -> `1.3.0`, `1.2.3` -> `1.2.4`
  Version get next {
    if (minor == null) {
      return Version(major + 1, 0, 0);
    }
    if (patch == null) {
      return Version(major, minor! + 1, 0);
    }
    return Version(major, minor!, patch! + 1);
  }
}

final _partialVersionRegExp = RegExp(
  r'^v?(\d+|x|X|\*)(?:\.(\d+|x|X|\*))?(?:\.(\d+|x|X|\*))?'
  r'(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?$',
);

/// Returns null for a wildcard (`x`, `*`).
_NpmPartialVersion? _parsePartialVersion(String text) {
  var match = _partialVersionRegExp.firstMatch(text.trim());
  if (match == null) {
    throw FormatException('Invalid npm version "$text"');
  }
  int? part(int index) {
    var value = match.group(index);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  var major = part(1);
  if (major == null) {
    // x, X or *
    return null;
  }
  var minor = part(2);
  var patch = minor == null ? null : part(3);
  return _NpmPartialVersion(
    major: major,
    minor: minor,
    patch: patch,
    pre: match.group(4),
    build: match.group(5),
  );
}

/// Parse a full npm version (`1.2.3`, `v1.2.3`, `=1.2.3`).
Version npmVersionParse(String text) {
  text = text.trim();
  if (text.startsWith('=')) {
    text = text.substring(1).trim();
  }
  var partial = _parsePartialVersion(text);
  if (partial == null || !partial.isFull) {
    throw FormatException('Invalid npm version "$text"');
  }
  return partial.version;
}

/// Parse a full npm version, null if invalid.
Version? npmVersionTryParse(String? text) {
  if (text == null) {
    return null;
  }
  try {
    return npmVersionParse(text);
  } catch (_) {
    return null;
  }
}

final _comparatorRegExp = RegExp(r'^(\^|~|>=|<=|>|<|=)?(.*)$');

/// `>= 1.2.3` -> `>=1.2.3`
final _operatorSpaceRegExp = RegExp(r'(\^|~|>=|<=|>|<|=)\s+');

/// Parse a single comparator (`^1.2.3`, `~1.2`, `>=1.0.0`, `1.x`, `2`...).
VersionConstraint _parseComparator(String text) {
  var match = _comparatorRegExp.firstMatch(text)!;
  var operator = match.group(1) ?? '';
  var partial = _parsePartialVersion(match.group(2)!);
  if (partial == null) {
    // wildcard
    return VersionConstraint.any;
  }
  var version = partial.version;
  switch (operator) {
    case '^':
      Version max;
      if (partial.major != 0) {
        max = Version(partial.major + 1, 0, 0);
      } else if (partial.minor == null) {
        // ^0 -> <1.0.0
        max = Version(1, 0, 0);
      } else if (partial.minor != 0) {
        max = Version(0, partial.minor! + 1, 0);
      } else if (partial.patch == null) {
        // ^0.0 -> <0.1.0
        max = Version(0, 1, 0);
      } else {
        // ^0.0.3 -> <0.0.4
        max = Version(0, 0, partial.patch! + 1);
      }
      return VersionRange(min: version, max: max, includeMin: true);
    case '~':
      Version max;
      if (partial.minor == null) {
        max = Version(partial.major + 1, 0, 0);
      } else {
        max = Version(partial.major, partial.minor! + 1, 0);
      }
      return VersionRange(min: version, max: max, includeMin: true);
    case '>=':
      return VersionRange(min: version, includeMin: true);
    case '>':
      if (partial.isFull) {
        return VersionRange(min: version);
      }
      // >1.2 -> >=1.3.0
      return VersionRange(min: partial.next, includeMin: true);
    case '<=':
      if (partial.isFull) {
        return VersionRange(max: version, includeMax: true);
      }
      // <=1.2 -> <1.3.0
      return VersionRange(max: partial.next);
    case '<':
      return VersionRange(max: version);
    default:
      // '=' or exact/partial version
      if (partial.isFull) {
        return version;
      }
      // 1.2 -> >=1.2.0 <1.3.0
      return VersionRange(min: version, max: partial.next, includeMin: true);
  }
}

final _hyphenRangeRegExp = RegExp(r'^(.+?)\s+-\s+(.+)$');

/// Parse a range without `||`.
VersionConstraint _parseRange(String text) {
  text = text.trim();
  if (text.isEmpty || text == 'latest') {
    return VersionConstraint.any;
  }
  // Hyphen range: `1.2.3 - 2.3.4`
  var hyphenMatch = _hyphenRangeRegExp.firstMatch(text);
  if (hyphenMatch != null) {
    var min = _parsePartialVersion(hyphenMatch.group(1)!);
    var max = _parsePartialVersion(hyphenMatch.group(2)!);
    if (max == null) {
      return VersionRange(min: min?.version, includeMin: true);
    }
    if (max.isFull) {
      return VersionRange(
        min: min?.version,
        max: max.version,
        includeMin: true,
        includeMax: true,
      );
    }
    // 1.2.3 - 2.3 -> >=1.2.3 <2.4.0
    return VersionRange(min: min?.version, max: max.next, includeMin: true);
  }

  // Space separated comparators are intersected.
  var normalized = text.replaceAllMapped(
    _operatorSpaceRegExp,
    (match) => match.group(1)!,
  );
  var constraint = VersionConstraint.any;
  for (var part in normalized.split(RegExp(r'\s+'))) {
    if (part.isEmpty) {
      continue;
    }
    constraint = constraint.intersect(_parseComparator(part));
  }
  return constraint;
}

/// Convert an npm version range (as found in `package.json`) to a
/// [VersionConstraint].
///
/// Supported: `*`, `x`, `latest`, empty, `1`, `1.2`, `1.2.3`, `1.x`, `1.2.x`,
/// `^1.2.3`, `~1.2.3`, `>=1.2.3`, `>1.2.3`, `<=1.2.3`, `<1.2.3`, `=1.2.3`,
/// hyphen ranges (`1.2.3 - 2.3.4`), space separated comparators
/// (`>=1.2.3 <2.0.0`) and `||` unions.
///
/// Throws a [FormatException] for anything else (local paths, git urls...).
VersionConstraint npmVersionConstraintParse(String text) {
  text = text.trim();
  if (!npmVersionConstraintIsRegistry(text)) {
    throw FormatException('Unsupported npm version constraint "$text"');
  }
  try {
    var parts = text.split('||');
    if (parts.length == 1) {
      return _parseRange(text);
    }
    return VersionConstraint.unionOf(parts.map(_parseRange));
  } on FormatException {
    rethrow;
  } catch (e) {
    throw FormatException('Invalid npm version constraint "$text" ($e)');
  }
}

/// Convert an npm version range to a [VersionConstraint], null if not
/// supported.
VersionConstraint? npmVersionConstraintTryParse(String? text) {
  if (text == null) {
    return null;
  }
  try {
    return npmVersionConstraintParse(text);
  } catch (_) {
    return null;
  }
}

/// The lower bound of a constraint, null if unbounded (`*`) or empty.
///
/// For `^1.2.3` returns `1.2.3`.
Version? versionConstraintMinVersion(VersionConstraint constraint) {
  if (constraint is VersionRange) {
    // Includes Version (min == max == version)
    return constraint.min;
  }
  if (constraint is VersionUnion) {
    // ranges are sorted
    return constraint.ranges.first.min;
  }
  return null;
}

/// The lower bound of an npm version range, null if unbounded (`*`) or
/// not supported.
///
/// For `^1.2.3` returns `1.2.3`.
Version? npmVersionConstraintMinVersion(String text) {
  var constraint = npmVersionConstraintTryParse(text);
  if (constraint == null) {
    return null;
  }
  return versionConstraintMinVersion(constraint);
}

/// True if [version] is allowed by the npm version range [constraint].
///
/// Throws a [FormatException] if [constraint] is not supported.
bool npmVersionConstraintAllows(String constraint, Version version) =>
    npmVersionConstraintParse(constraint).allows(version);
