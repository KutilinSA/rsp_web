import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web3/ethereum.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(const AuthenticationState.initial()) {
    on<AuthenticationEventAuthenticationRequested>(_onAuthenticationRequested);
  }

  Future<void> _onAuthenticationRequested(
    AuthenticationEventAuthenticationRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.inProgress));

    final eth = ethereum;
    if (eth == null) {
      emit(state.copyWith(status: AuthenticationStatus.noEthereumError));
      return;
    }

    try {
      final accounts = await eth.requestAccount();
      emit(state.copyWith(
        status: AuthenticationStatus.success,
        accounts: accounts,
      ));
    } on Object catch (e) {
      emit(state.copyWith(
        status: e is EthereumUserRejected
            ? AuthenticationStatus.canceledError
            : AuthenticationStatus.undefinedError,
      ));
    }
  }
}