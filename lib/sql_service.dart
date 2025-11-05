// lib/sql_service.dart

import 'package:mssql_connection/mssql_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _initializeSettings();
  }

  // EKLENDİ: Ayarları başlatmak için güvenli bir yöntem
  Future<void> _initializeSettings() async {
    try {
      await loadSettings();
    } catch (e) {
      print("Ayarlar yüklenirken hata oluştu: \$e");
      // Varsayılan ayarları kullan
      currentIp = _defaultIp;
      currentPort = _defaultPort;
    }
  }

  // EKLENDİ: Kayıtlı ayarları yükler
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Kayıtlı IP'yi al, yoksa varsayılanı kullan
      currentIp = prefs.getString('server_ip') ?? _defaultIp;
      // Kayıtlı Port'u al, yoksa varsayılanı kullan
      currentPort = prefs.getString('server_port') ?? _defaultPort;
    } catch (e) {
      print("SharedPreferences hatası: \$e");
      rethrow;
    }
  }

  // EKLENDİ: Yeni ayarları kaydeder
  Future<void> saveSettings(String ip, String port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);
      await prefs.setString('server_port', port);
      // Servisteki aktif ayarları da güncelle
      currentIp = ip;
      currentPort = port;
    } catch (e) {
      print("Ayarlar kaydedilirken hata oluştu: \$e");
      rethrow;
    }
  }

  /// Veritabanına bağlanmayı dener.
  /// Başarılı olursa `null` döner.
  /// Başarısız olursa hatayı açıklayan bir `String` mesajı döner.
  Future<String?> connect() async {
    // Bağlantıdan önce ayarların yüklendiğinden emin ol
    try {
      await loadSettings();
    } catch (e) {
      print("Ayarlar yüklenemedi: \$e");
      return "Cihaz hafızasından sunucu ayarları okunamadı.";
    }

    // Eski bağlantı varsa yeniden bağlanmak için sıfırla
    if (isConnected) {
      isConnected = false;
    }

    try {
      isConnected = await mssqlConnection.connect(
        ip: currentIp,
        port: currentPort,
        databaseName: _databaseName,
        username: _username,
        password: _password,
        timeoutInSeconds: _timeout,
      );
      
      return isConnected ? null : "Bağlantı kurulamadı, ancak sunucudan detaylı hata alınamadı.";

    } catch (e) {
      print("Bağlantı hatası: \$e");
      isConnected = false;

      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('login failed')) {
        return 'Giriş başarısız. Kullanıcı adı veya şifre yanlış.';
      }
      if (errorMessage.contains('ssl') || errorMessage.contains('certificate') || errorMessage.contains('handshake')) {
        return 'Güvenli bağlantı hatası (SSL/TLS). Sunucu sertifikası geçerli olmayabilir.';
      }
      if (errorMessage.contains('timeout')) {
        return 'Bağlantı zaman aşımına uğradı. Sunucu IP/Port ayarlarını ve ağ bağlantınızı kontrol edin.';
      }
      if (errorMessage.contains('network is unreachable') || errorMessage.contains('connection refused')) {
        return 'Sunucuya ulaşılamıyor. Sunucu kapalı olabilir veya IP/Port ayarları yanlış.';
      }
      
      return 'Bilinmeyen bir bağlantı hatası oluştu: \${e.toString()}';
    }
  }

  // Veri Okuma Metodu
  Future<String> getData(String query) async {
    if (!isConnected) {
      // Bağlantı yoksa, tekrar kurmayı dene
      final String? error = await connect();
      if (error != null) {
        throw Exception(
          "Veritabanı bağlantısı kurulamadı: \$error",
        );
      }
    }
    return await mssqlConnection.getData(query);
  }

  // Veri Yazma Metodu (INSERT, UPDATE, DELETE)
  Future<String> writeData(String query) async {
    if (!isConnected) {
      // Bağlantı yoksa, tekrar kurmayı dene
      final String? error = await connect();
      if (error != null) {
        throw Exception(
          "Veritabanı bağlantısı kurulamadı: \$error",
        );
      }
    }
    return await mssqlConnection.writeData(query);
  }
}
