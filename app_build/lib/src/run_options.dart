/// Runner options
class NodeAppRunOptions {
  /// Standard input forwarded to the spawned Node.js process.
  final Stream<List<int>>? stdin;

  /// Creates run options for a Node.js process execution.
  NodeAppRunOptions({required this.stdin});
}
