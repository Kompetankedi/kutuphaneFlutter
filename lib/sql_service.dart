// lib/sql_service.dart

import 'package:mssql_connection/mssql_connection.dart';
import 'package:shared_preferences/shared_preferences.dart'; // EKLENDİ

class SqlService {
  late final MssqlConnection mssqlConnection;
  bool isConnected = false;

  // Varsayılan Bağlantı Bilgileri (Eğer Kayıt Yoksa Kullanılır)
  final String _defaultIp = '127.0.0.1';
  final String _defaultPort = '1433';
  final String _databaseName = 'dbkutuphane';
  final String _username = 'flutter';
  final String _password = 'pro';
  final int _timeout = 15;

  // Mevcut Ayarları Tutmak İçin (UI'da Göstermek veya bağlantı kurmak için)
  String currentIp = '127.0.0.1';
  String currentPort = '1433';

  // Servis yapıcı (constructor)
  SqlService() {
    mssqlConnection = MssqlConnection.getInstance();
    // Yapıcıda ayarları asenkron olarak yüklüyoruz.
    loadSettings();
  }

  // EKLENDİ: Kayıtlı ayarları yükler
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Kayıtlı IP'yi al, yoksa varsayılanı kullan
    currentIp = prefs.getString('server_ip') ?? _defaultIp;
    // Kayıtlı Port'u al, yoksa varsayılanı kullan
    currentPort = prefs.getString('server_port') ?? _defaultPort;
  }

  // EKLENDİ: Yeni ayarları kaydeder
  Future<void> saveSettings(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    await prefs.setString('server_port', port);
    // Servisteki aktif ayarları da güncelle
    currentIp = ip;
    currentPort = port;
  }


  Future<bool> connect() async {
    // Bağlantıdan önce ayarların yüklendiğinden emin ol
    await loadSettings();

    // Eski bağlantı varsa kapat (uygulama içinde ayar değiştirilirse)
    if (isConnected) {
      // mssql_connection paketinin disconnect metodu varsa burada çağrılmalıdır.
      // Yoksa isConnected'ı false yapıp yeni bağlantıyı denemek yeterlidir.
      isConnected = false;
    }

    isConnected = await mssqlConnection.connect(
      ip: currentIp, // currentIp kullanılıyor
      port: currentPort, // currentPort kullanılıyor
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
      // Bağlantı yoksa, tekrar kurmayı dene
      bool success = await connect();
      if (!success) {
        throw Exception("Veritabanı bağlantısı kurulu değil ve yeniden kurulamadı.");
      }
    }
    return await mssqlConnection.getData(query);
  }

  // Veri Yazma Metodu (INSERT, UPDATE, DELETE)
  Future<String> writeData(String query) async {
    if (!isConnected) {
      // Bağlantı yoksa, tekrar kurmayı dene
      bool success = await connect();
      if (!success) {
        throw Exception("Veritabanı bağlantısı kurulu değil ve yeniden kurulamadı.");
      }
    }
    return await mssqlConnection.writeData(query);
  }
}