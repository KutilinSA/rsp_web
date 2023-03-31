import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<String> accounts;

  const HomePage({ required this.accounts, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Home page'),
          const SizedBox(height: 64),
          const Text('You are logged in,'),
          const Text('Ethereum provider is connected'),
          const SizedBox(height: 64),
          const Text('Available accounts:'),
          for (final account in accounts)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(account),
            ),
        ],
      ),
    ),
  );
}