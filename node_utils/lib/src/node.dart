export 'node_stub.dart'
    if (dart.library.js_interop) 'node_impl.dart'
    if (dart.library.io) 'node_io.dart';
