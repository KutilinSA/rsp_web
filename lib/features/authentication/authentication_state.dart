part of 'authentication_bloc.dart';

enum AuthenticationStatus {
  notRequested,
  inProgress,
  noEthereumError,
  canceledError,
  undefinedError,
  success,
}

extension AuthenticationStatusX on AuthenticationStatus {
  bool get isError => this == AuthenticationStatus.noEthereumError
      || this == AuthenticationStatus.canceledError
      || this == AuthenticationStatus.undefinedError;
}

class AuthenticationState extends Equatable {
  final AuthenticationStatus status;
  final List<String> accounts;

  @override
  List<Object> get props => [status, accounts];

  const AuthenticationState._({ required this.status, required this.accounts, });

  const AuthenticationState.initial() :
      status = AuthenticationStatus.notRequested,
      accounts = const [];

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    List<String>? accounts,
  }) => AuthenticationState._(
    status: status ?? this.status,
    accounts: accounts ?? this.accounts,
  );
}