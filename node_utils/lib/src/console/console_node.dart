library;

import 'dart:js_interop';
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

class _ConsoleErrorSink extends _ConsoleSink {
  @override
  void writeln([Object? obj = '']) {
    // devPrint('err.writeln($obj)');
    _consoleError(obj?.jsify());
  }
}

class _ConsoleOutSink extends _ConsoleSink {
  @override
  void writeln([Object? obj = '']) {
    // devPrint('out.writeln($obj)');
    _consoleLog(obj?.jsify());
  }
}

abstract class _ConsoleSink implements ConsoleSink {
  @override
  void add(List<int> data) {
    // TODO: implement add
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void write(Object? obj) {
    // TODO: implement write
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    // TODO: implement writeAll
  }

  @override
  void writeCharCode(int charCode) {
    // TODO: implement writeCharCode
  }
}

final Console console = _Console();
