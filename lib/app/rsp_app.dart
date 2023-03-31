import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rsp_web/app/authentication_page.dart';
import 'package:rsp_web/features/authentication/authentication_bloc.dart';

class RSPApp extends StatelessWidget {
  const RSPApp({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<AuthenticationBloc>(
        create: (context) => AuthenticationBloc()..add(const AuthenticationEventAuthenticationRequested()),
        child: const AuthenticationPage(),
      ),
    );
  }
}