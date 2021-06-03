import 'console.dart';

class NoneConsole extends Console {
  @override
  final err = NonConsoleSink();

  @override
  final out = NonConsoleSink();
}

final NoneConsole console = NoneConsole();

class NonConsoleSink implements ConsoleSink {
  @override
  void add(List<int> data) {}

  @override
  void close() {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
}
