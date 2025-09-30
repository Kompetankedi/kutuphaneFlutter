import 'package:mssql_connection/mssql_connection.dart';

class SqlService {
  late final MssqlConnection mssqlConnection;
  bool isConnected = false;

  // Servis yapıcı (constructor), bağlantıyı başlatır
  SqlService() {
    mssqlConnection = MssqlConnection.getInstance();
  }

  // Bağlantı Bilgileri
  final String _ip = '127.0.0.1';
  final String _port = '1433';
  final String _databaseName = 'dbkutuphane';
  final String _username = 'flutter';
  final String _password = 'pro';
  final int _timeout = 15;

  Future<bool> connect() async {
    isConnected = await mssqlConnection.connect(
      ip: _ip,
      port: _port,
      databaseName: _databaseName,
      username: _username,
      password: _password,
      timeoutInSeconds: _timeout,
    );
    return isConnected;
  }

  // Veri Okuma Metodu
  Future<String> getData(String query) async {
    if (!isConnected) {
      throw Exception("Veritabanı bağlantısı kurulu değil.");
    }
    return await mssqlConnection.getData(query);
  }

  // Veri Yazma Metodu (INSERT, UPDATE, DELETE)
  Future<String> writeData(String query) async {
    if (!isConnected) {
      throw Exception("Veritabanı bağlantısı kurulu değil.");
    }
    return await mssqlConnection.writeData(query);
  }
}