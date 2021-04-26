import 'console.dart';

class NoneConsole extends Console {
  @override
  ConsoleSink? get err => null;

  @override
  ConsoleSink? get out => null;
}

final NoneConsole console = NoneConsole();
