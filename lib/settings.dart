import 'package:rsp_web/secrets.dart';

abstract class Settings {
  static const String rpcServerAddress = SECRET_RPC_SERVER_ADDRESS;
  static const String contractAddress = SECRET_CONTRACT_ADDRESS;

  const Settings._();
}
