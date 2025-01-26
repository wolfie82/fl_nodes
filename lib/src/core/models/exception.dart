class RunnerException implements Exception {
  final String message;
  final String nodeId;

  RunnerException(this.message, this.nodeId);

  @override
  String toString() => 'RunnerException: $message';

  Map<String, dynamic> toJson() => {
        'message': message,
        'nodeId': nodeId,
      };

  static RunnerException fromJson(Map<String, dynamic> json) =>
      RunnerException(json['message'], json['nodeId']);
}
