// lib/models/profile_setup_state.dart

enum ProfileSetupStatus { initial, loading, success, error }

class ProfileSetupState {
  final ProfileSetupStatus status;
  final String? errorMessage;

  const ProfileSetupState({
    this.status = ProfileSetupStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == ProfileSetupStatus.loading;
  bool get isError => status == ProfileSetupStatus.error;
  bool get isSuccess => status == ProfileSetupStatus.success;

  ProfileSetupState copyWith({
    ProfileSetupStatus? status,
    Object? errorMessage = _sentinel,
  }) {
    return ProfileSetupState(
      status: status ?? this.status,
      errorMessage:
          errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    );
  }

  static const initial = ProfileSetupState();
}

const Object _sentinel = Object();