/// Node app common options.
class NodeAppOptions {
  /// App packages (default to '.')
  late final String packageTop;

  /// Typically 'deploy' for a single node app
  late final String deployDir;

  /// Typically 'bin' to 'node', default to 'bin'
  late final String srcDir;

  /// Default to main.dart, inside $srcDir
  final String? srcFile;

  NodeAppOptions(
      {String? packageTop, String? deployDir, String? srcDir, this.srcFile}) {
    this.packageTop = packageTop ?? '.';
    this.deployDir = deployDir ?? 'deploy';
    this.srcDir = srcDir ?? 'bin';
  }
}
