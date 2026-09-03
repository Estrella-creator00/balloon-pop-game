import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseInitializer = Future<void> Function();
typedef FirebaseUidReader = String? Function();
typedef FirebaseAnonymousSigner = Future<String> Function();

class FirebaseRankingRuntime {
  FirebaseRankingRuntime({
    FirebaseInitializer? initialize,
    FirebaseUidReader? currentUid,
    FirebaseAnonymousSigner? signInAnonymously,
  })  : _initialize = initialize ?? _initializeDefault,
        _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _signInAnonymously = signInAnonymously ?? _signInDefault;

  static final FirebaseRankingRuntime instance = FirebaseRankingRuntime();

  static const FirebaseOptions _webOptions = FirebaseOptions(
    apiKey: 'AIzaSyBNQ6xwXxon6fdd-G5ewkdrHxj_gl4xqTw',
    appId: '1:855480037727:web:ef83b456ce2ecd98ff46ea',
    messagingSenderId: '855480037727',
    projectId: 'poppop-c8bc6',
    authDomain: 'poppop-c8bc6.firebaseapp.com',
    storageBucket: 'poppop-c8bc6.firebasestorage.app',
  );

  final FirebaseInitializer _initialize;
  final FirebaseUidReader _currentUid;
  final FirebaseAnonymousSigner _signInAnonymously;
  Future<void>? _initialization;
  Future<String>? _authentication;

  Future<void> ensureInitialized() =>
      _initialization ??= _initialize().catchError((Object error) {
        _initialization = null;
        throw error;
      });

  Future<String> ensureUid() {
    return _authentication ??= _authenticateOnce();
  }

  Future<String> _authenticateOnce() async {
    try {
      await ensureInitialized();
      final current = _currentUid();
      if (current != null) return current;
      return await _signInAnonymously();
    } finally {
      _authentication = null;
    }
  }

  static Future<void> _initializeDefault() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(options: kIsWeb ? _webOptions : null);
  }

  static Future<String> _signInDefault() async {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    final uid = credential.user?.uid;
    if (uid == null) {
      throw StateError('Anonymous Firebase user is unavailable.');
    }
    return uid;
  }

  @visibleForTesting
  bool get hasStartedInitialization => _initialization != null;
}
