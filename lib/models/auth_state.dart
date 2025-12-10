// Base sealed class for authentication state
sealed class AuthState {
  const AuthState();
}

// State when user is authenticated
class AuthStateAuthenticated extends AuthState {
  final String userId;
  
  const AuthStateAuthenticated(this.userId);
}

// State when user is not authenticated
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

// State when authentication state is being checked
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

// State when there's an authentication error
class AuthStateError extends AuthState {
  final String message;
  
  const AuthStateError(this.message);
}
