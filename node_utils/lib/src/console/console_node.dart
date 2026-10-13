library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tekartik_app_node_utils/src/console/console.dart';

class _Console implements Console {
  @override
  final _ConsoleSink out = _ConsoleOutSink();
  @override
  final _ConsoleSink err = _ConsoleErrorSink();
}

@JS('console.error')
external void _consoleError(JSAny? object);

@JS('console.log')
external void _consoleLog(JSAny? object);

/// A node writable stream (process.stdout or process.stderr).
extension type _JSWritable._(JSObject _) implements JSObject {
  external bool write(JSAny chunk);
}

@JS('process.stdout')
external _JSWritable get _processStdout;

@JS('process.stderr')
external _JSWritable get _processStderr;

class _ConsoleErrorSink extends _ConsoleSink {
  @override
  _JSWritable get _stream => _processStderr;

  @override
  void writeln([Object? obj = '']) {
    _consoleError('$obj'.toJS);
  }
}

class _ConsoleOutSink extends _ConsoleSink {
  @override
  _JSWritable get _stream => _processStdout;

  @override
  void writeln([Object? obj = '']) {
    _consoleLog('$obj'.toJS);
  }
}

/// write, writeAll and writeCharCode write without a new line to the process
/// stream, writeln goes through console.log/console.error.
abstract class _ConsoleSink implements ConsoleSink {
  _JSWritable get _stream;

  @override
  void add(List<int> data) {
    _stream.write(Uint8List.fromList(data).toJS);
  }

  @override
  void close() {}

  @override
  void write(Object? obj) {
    _stream.write('$obj'.toJS);
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }
}

final Console console = _Console();
