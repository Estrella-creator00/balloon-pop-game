import 'package:cloud_functions/cloud_functions.dart';

abstract interface class RankingFunctionsClient {
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]);
}

class FirebaseRankingFunctionsClient implements RankingFunctionsClient {
  FirebaseRankingFunctionsClient({FirebaseFunctions? functions})
      : _functions = functions;

  static const region = 'asia-northeast3';

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _instance =>
      _functions ?? FirebaseFunctions.instanceFor(region: region);

  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    final result = await _instance.httpsCallable(name).call<Object?>(data);
    final value = result.data;
    if (value is! Map) return const {};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
}

enum OnlineDataDeletionFailure { offline, unauthenticated, server }

class OnlineDataDeletionException implements Exception {
  const OnlineDataDeletionException(this.failure);

  final OnlineDataDeletionFailure failure;
}
