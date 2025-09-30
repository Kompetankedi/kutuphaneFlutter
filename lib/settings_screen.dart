// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'sql_service.dart';

class SettingsScreen extends StatefulWidget {
  final SqlService sqlService;
  const SettingsScreen({super.key, required this.sqlService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ipController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    // SqlService'taki mevcut veya varsayılan değerlerle controller'ları başlat
    _ipController = TextEditingController(text: widget.sqlService.currentIp);
    _portController = TextEditingController(text: widget.sqlService.currentPort);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String newIp = _ipController.text;
      String newPort = _portController.text;

      // SqlService üzerinden ayarları kaydet
      await widget.sqlService.saveSettings(newIp, newPort);

      // Başarılı mesajı göster ve geri dön
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Ayarlar başarıyla kaydedildi! Bağlantının güncellenmesi için bir sonraki işleme veya yeniden başlatmaya kadar bekleyin.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunucu Ayarları'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Uygulamanın bağlanacağı MSSQL sunucusunun IP adresi ve portunu ayarlayın.',
                style: TextStyle(fontSize: 16),
              ),
              const Divider(height: 30),

              // IP Adresi Alanı
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Sunucu IP Adresi',
                  hintText: 'Örn: 127.0.0.1 veya 192.168.1.10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                ),
                keyboardType: TextInputType.text, // IP için metin tipi daha uygun
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'IP adresi gereklidir.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Port Alanı
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port Numarası',
                  hintText: 'Varsayılan: 1433',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Port numarası gereklidir.';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir numara girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('AYARLARI KAYDET'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}