export 'pop_sound_stub.dart'
    if (dart.library.io) 'pop_sound_native.dart'
    if (dart.library.js_interop) 'pop_sound_web.dart';
