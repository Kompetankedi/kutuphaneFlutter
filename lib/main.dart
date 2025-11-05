import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sql_service.dart';
import 'tr_roman_screen.dart';
import 'yabanci_roman_screen.dart';
import 'odunc_islemleri_screen.dart';
import 'settings_screen.dart'; // EKLENDİ
import 'theme_provider.dart'; // EKLENDİ

// Tüm uygulama boyunca tek bir servis örneği kullanmak için global olarak tanımlıyoruz
final SqlService sqlService = SqlService();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Okul Kütüphanesi',
          theme: themeProvider.currentTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MainMenuScreen(),
        );
      },
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
    // Başlangıçta ayarlar yüklenecek ve bağlantı kontrol edilecek.
    _checkConnection();
  }

  // Veritabanı bağlantısını kontrol eden metot
  Future<void> _checkConnection() async {
    setState(() {
      _connectionMessage = "Bağlantı kontrol ediliyor...";
      _isConnected = false;
    });

    try {
      // Bağlantıdan önce loadSettings otomatik çağrılacak.
      bool success = await sqlService.connect();
      if (mounted) {
        setState(() {
          _isConnected = success;
          if (_isConnected) {
            _connectionMessage = "Bağlantı Başarılı!";
          } else {
            _connectionMessage = "Bağlantı Kurulamadı! Ayarları kontrol edin.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectionMessage = "Bağlantı Hatası: ${e.toString()}";
        });
      }
    }
  }

  // Ekranlar arası geçiş metodu
  void _navigateToScreen(Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => screen)).then((_) {
      // Bir ekrandan geri dönüldüğünde gerekirse bağlantı durumunu tekrar kontrol et
      _checkConnection();
    });
  }

  // Ayarlar ekranına yönlendirme
  void _navigateToSettingsScreen() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => SettingsScreen(sqlService: sqlService),
          ),
          // Ayarlar ekranından dönüldüğünde bağlantıyı tekrar kontrol et
        )
        .then((_) {
          _checkConnection();
          setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okul Kütüphanesi Ana Menü'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Ayarlar İkonu
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettingsScreen,
          ),
        ],
      ),
      // BODY KISMI: Ana Column'daki gereksiz boşluklar kaldırıldı.
      body: SingleChildScrollView(
        // Padding sadece yatayda bırakıldı. Üstteki boşluk kaldırıldı.
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Üste yasla
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bağlantı Durumu Kartı (Margin ile üstten ve alttan boşluk veriliyor)
            Card(
              color: _isConnected
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade800
                        : Colors.green.shade100)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade800
                        : Colors.red.shade100),
              margin: const EdgeInsets.only(
                top: 10,
                bottom: 10,
              ), // Üstteki boşluğu 10 yaptı
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected
                          ? 'Bağlantı Durumu: Başarılı'
                          : 'Bağlantı Durumu: Hata',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isConnected
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade200
                                  : Colors.green.shade800)
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade200
                                  : Colors.red.shade800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_connectionMessage),
                    Text(
                      'IP: ${sqlService.currentIp}, Port: ${sqlService.currentPort}',
                    ),
                    const SizedBox(height: 8),
                    // Bağlantı kurulamadıysa yeniden dene butonu
                    if (!_isConnected)
                      ElevatedButton.icon(
                        onPressed: _checkConnection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Dene'),
                      ),
                  ],
                ),
              ),
            ),

            // AYIRICI KULLANILDI. ARTIK GEREKSİZ SIZEDBOX YOK.
            const Divider(height: 40),

            // --- TÜRK ROMANLARI ---
            _buildMenuTile(
              title: 'Türk Roman İşlemleri',
              subtitle: 'Kitapları gör, ekle, sil ve güncelle (TrRoman)',
              icon: Icons.menu_book,
              onTap: () =>
                  _navigateToScreen(TrRomanScreen(sqlService: sqlService)),
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
      ),
    );
  }

  Widget _buildMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
