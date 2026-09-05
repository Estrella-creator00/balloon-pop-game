import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseInitializer = Future<void> Function();
typedef FirebaseUidReader = String? Function();
typedef FirebaseAnonymousSigner = Future<String> Function();
typedef FirebaseSignerOut = Future<void> Function();

class FirebaseRankingRuntime {
  FirebaseRankingRuntime({
    FirebaseInitializer? initialize,
    FirebaseUidReader? currentUid,
    FirebaseAnonymousSigner? signInAnonymously,
    FirebaseSignerOut? signOut,
  })  : _initialize = initialize ?? _initializeDefault,
        _currentUid =
            currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
        _signInAnonymously = signInAnonymously ?? _signInDefault,
        _signOut = signOut ?? _signOutDefault;

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
  final FirebaseSignerOut _signOut;
  Future<void>? _initialization;
  Future<String>? _authentication;
  bool _suppressAutomaticSignIn = false;

  Future<void> ensureInitialized() =>
      _initialization ??= _initialize().catchError((Object error) {
        _initialization = null;
        throw error;
      });

  Future<String> ensureUid({bool reactivateAfterDeletion = false}) {
    if (_suppressAutomaticSignIn && !reactivateAfterDeletion) {
      return Future.error(
        StateError('Online account was deleted. Open ranking to start again.'),
      );
    }
    if (reactivateAfterDeletion) _suppressAutomaticSignIn = false;
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

  Future<void> markCurrentUserDeleted() async {
    await ensureInitialized();
    _authentication = null;
    await _signOut();
    _suppressAutomaticSignIn = true;
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

  static Future<void> _signOutDefault() => FirebaseAuth.instance.signOut();

  @visibleForTesting
  bool get hasStartedInitialization => _initialization != null;

  bool get automaticSignInSuppressed => _suppressAutomaticSignIn;
}
