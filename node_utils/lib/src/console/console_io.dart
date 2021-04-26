import 'dart:io';

import 'package:tekartik_app_node_utils/src/console/console.dart';
//import '../../new_console.dart' hide console;

class _Console implements Console {
  @override
  final _ConsoleSink out = _ConsoleSink(stdout);
  @override
  final _ConsoleSink err = _ConsoleSink(stderr);
}

class _ConsoleSink implements ConsoleSink {
  final IOSink ioSink;
  _ConsoleSink(this.ioSink);

  @override
  void add(List<int> data) => ioSink.add(data);

  @override
  void close() => ioSink.close();

  @override
  void write(Object? obj) => ioSink.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    ioSink.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    ioSink.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = '']) {
    ioSink.writeln(obj);
  }
}

Console console = _Console();
