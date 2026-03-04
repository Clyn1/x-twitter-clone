// lib/models/auth_state.dart

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
  bool get isSuccess => status == AuthStatus.success;
  
  // Use a sentinel so we can explicitly clear errorMessage by passing null
  AuthState copyWith({AuthStatus? status, Object? errorMessage = _sentinel}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const initial = AuthState();
}

const Object _sentinel = Object();