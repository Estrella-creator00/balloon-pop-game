import 'progress_storage_native.dart';

Future<void> initializeProgressStorage() => ProgressStorage.initialize();

Future<void> flushProgressStorage() => ProgressStorage.flush();
