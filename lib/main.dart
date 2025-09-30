import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'tr_roman_screen.dart';
import 'yabanci_roman_screen.dart';
import 'odunc_islemleri_screen.dart';

// Tüm uygulama boyunca tek bir servis örneği kullanmak için global olarak tanımlıyoruz
final SqlService sqlService = SqlService();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okul Kütüphanesi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isConnected = false;
  String _connectionMessage = "Bağlantı kontrol ediliyor...";

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  // Veritabanı bağlantısını kontrol eden metot
  Future<void> _checkConnection() async {
    bool success = await sqlService.connect();

    setState(() {
      _isConnected = success;
      _connectionMessage = success
          ? "Veritabanı BAĞLI. İşlem yapabilirsiniz."
          : "Bağlantı BAŞARISIZ. Lütfen SQL Server ayarlarını kontrol edin.";
    });
  }

  // Menüde tıklanınca sayfa yönlendirmesi
  void _navigateToScreen(Widget screen) {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce bağlantı hatasını giderin!")),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphane Yönetim Sistemi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bağlantı Durumu Kartı
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _isConnected ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(_isConnected ? Icons.check_circle : Icons.error, color: _isConnected ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionMessage,
                    style: TextStyle(
                      color: _isConnected ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _checkConnection,
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Menüler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // --- TÜRKÇE ROMANLAR ---
          _buildMenuTile(
            title: 'Türkçe Roman İşlemleri',
            subtitle: 'Kitapları gör, ekle, sil ve güncelle (TrRoman)',
            icon: Icons.menu_book,
            onTap: () => _navigateToScreen(TrRomanScreen(sqlService: sqlService)),
          ),

          // --- YABANCI ROMANLAR ---
          _buildMenuTile(
            title: 'Yabancı Roman İşlemleri',
            subtitle: 'Kitapları gör, ekle, sil ve güncelle (YabanciRoman)',
            icon: Icons.language,
            onTap: () {
              _navigateToScreen(YabanciRomanScreen(sqlService: sqlService));
            },
          ),

          // --- ÖDÜNÇ İŞLEMLERİ (YÖNLENDİRME AKTİF) ---
          _buildMenuTile(
            title: 'Ödünç İşlemleri',
            subtitle: 'Ödünç verme ve iade kayıtları (Islemler)',
            icon: Icons.swap_horiz,
            onTap: () {
              // Yönlendirme, yeni oluşturulan ekrana yapılıyor.
              _navigateToScreen(OduncIslemleriScreen(sqlService: sqlService));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}