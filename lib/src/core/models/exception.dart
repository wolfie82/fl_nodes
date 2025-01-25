import 'entities.dart';

class RunnerException implements Exception {
  final String message;
  final NodeInstance node;

  RunnerException(this.message, this.node);

  @override
  String toString() => 'RunnerException: $message';
}
