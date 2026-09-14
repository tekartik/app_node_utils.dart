/// npm helpers: `package.json` constraints, installed versions and
/// `npm install` when needed.
library;

export 'package:pub_semver/pub_semver.dart' show Version, VersionConstraint;

export 'src/npm_check.dart'
    show
        NodePackageNpmCheckResult,
        NodePackageNpmDependencyCheck,
        nodePackageGetNpmDependencyConstraints,
        nodePackageGetNpmInstalledVersion,
        nodePackageNpmCheck,
        nodePackageNpmInstallIfNeeded,
        nodePackageReadPackageJson;
export 'src/npm_version.dart'
    show
        npmVersionConstraintAllows,
        npmVersionConstraintIsRegistry,
        npmVersionConstraintMinVersion,
        npmVersionConstraintParse,
        npmVersionConstraintTryParse,
        npmVersionParse,
        npmVersionTryParse,
        versionConstraintMinVersion;
