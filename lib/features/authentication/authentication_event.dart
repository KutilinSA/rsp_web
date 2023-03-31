part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
}

class AuthenticationEventAuthenticationRequested extends AuthenticationEvent {
  @override
  List<Object?> get props => const [];

  const AuthenticationEventAuthenticationRequested();
}