import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rsp_web/app/home_page.dart';
import 'package:rsp_web/features/authentication/authentication_bloc.dart';

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) => BlocListener<AuthenticationBloc, AuthenticationState>(
    listenWhen: (previous, current) => previous.status != current.status,
    listener: (context, state) {
      if (state.status == AuthenticationStatus.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => HomePage(accounts: state.accounts),
          ),
        );
      }
    },
    child: Scaffold(
      body: Center(
        child: BlocSelector<AuthenticationBloc, AuthenticationState, AuthenticationStatus>(
          selector: (state) => state.status,
          builder: (context, status) {
            if (status.isError) {
              final String errorText;
              switch (status) {
                case AuthenticationStatus.noEthereumError:
                  errorText = 'No ethereum provider!';
                  break;
                case AuthenticationStatus.canceledError:
                  errorText = 'Authentication rejected!';
                  break;
                default:
                  errorText = 'Undefined error';
                  break;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error while connecting wallet'),
                  const SizedBox(height: 16),
                  Text(errorText),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.read<AuthenticationBloc>()
                        .add(const AuthenticationEventAuthenticationRequested()),
                    child: const Text('Try again'),
                  ),
                ],
              );
            }

            return const SizedBox(
              height: 200,
              width: 200,
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    ),
  );
}