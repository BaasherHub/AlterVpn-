abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class VpnFailure extends Failure {
  const VpnFailure([super.message = 'VPN error occurred']);
}

class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to parse data']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage error occurred']);
}
