// lib/add_edit_yabanci_roman_screen.dart

import 'package:flutter/material.dart';
import 'sql_service.dart';

class AddEditYabanciRomanScreen extends StatefulWidget {
  final SqlService sqlService;
  final Map<String, dynamic>? roman;

  const AddEditYabanciRomanScreen({super.key, required this.sqlService, this.roman});

  @override
  State<AddEditYabanciRomanScreen> createState() => _AddEditYabanciRomanScreenState();
}

class _AddEditYabanciRomanScreenState extends State<AddEditYabanciRomanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controller'lar
  late final TextEditingController _kitapAdiController;
  late final TextEditingController _kitapYazarController;
  late final TextEditingController _kitapNoController;

  bool get isEditing => widget.roman != null;

  @override
  void initState() {
    super.initState();
    // Mevcut verilerle controller'ları doldurun
    _kitapAdiController = TextEditingController(text: widget.roman?['KitapAdi']?.toString() ?? '');
    _kitapYazarController = TextEditingController(text: widget.roman?['KitapYazar']?.toString() ?? '');
    _kitapNoController = TextEditingController(text: widget.roman?['KitapNo']?.toString() ?? '');
  }

  @override
  void dispose() {
    _kitapAdiController.dispose();
    _kitapYazarController.dispose();
    _kitapNoController.dispose();
    super.dispose();
  }

  // SQL SORGUSU İÇİN ÖZEL KARAKTERLERİ KAÇIRAN FONKSİYON
  String _cleanStringForSql(String text) {
    return text
        .replaceAll("'", "''")     // Tek tırnakları çift tırnağa çevir (en yaygın hata çözümü)
        .replaceAll("\\", "\\\\"); // Ters bölüyü kaçır (bazı sunucularda gerekli olabilir)
  }

  // INSERT veya UPDATE işlemini gerçekleştiren ana fonksiyon
  Future<void> _saveRoman() async {
    if (!_formKey.currentState!.validate()) return;

    // --- GÜVENLİK İÇİN ÖZEL KARAKTER KAÇIŞI UYGULANIYOR ---
    final String kitapAdi = _cleanStringForSql(_kitapAdiController.text);
    final String kitapYazar = _cleanStringForSql(_kitapYazarController.text);

    final int kitapNo = int.tryParse(_kitapNoController.text) ?? 0;

    String query;
    String successMessage;

    if (isEditing) {
      // GÜNCELLEME (UPDATE) SORGUSU
      final String idString = widget.roman!['id'].toString();
      final int id = int.parse(idString);

      query = '''
        UPDATE YabanciRoman SET  
        KitapAdi = N'$kitapAdi',          
        KitapYazar = N'$kitapYazar',      
        KitapNo = $kitapNo 
        WHERE id = $id
      ''';
      successMessage = 'Yabancı Kitap başarıyla güncellendi.';
    } else {
      // EKLEME (INSERT) SORGUSU
      query = '''
        INSERT INTO YabanciRoman (KitapAdi, KitapYazar, KitapNo) 
        VALUES (N'$kitapAdi', N'$kitapYazar', $kitapNo)
      ''';
      successMessage = 'Yabancı Kitap başarıyla eklendi.';
    }

    try {
      await widget.sqlService.writeData(query);

      if (mounted) {
        // İşlem başarılı, listeyi yenilemek için sinyal gönder
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      // Hata mesajını konsola ve ekrana yazdırıyoruz.
      print("SQL Yazma Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext setContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Yabancı Kitap Düzenle (ID: ${widget.roman!['id']})' : 'Yeni Yabancı Kitap Ekle'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _kitapAdiController,
                decoration: const InputDecoration(labelText: 'Kitap Adı', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Kitap Adı gereklidir.' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kitapYazarController,
                decoration: const InputDecoration(labelText: 'Kitap Yazar', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Yazar adı gereklidir.' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kitapNoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kitap No', border: OutlineInputBorder()),
                validator: (value) => value == null || int.tryParse(value) == null ? 'Geçerli bir numara girin.' : null,
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              ElevatedButton.icon(
                onPressed: _saveRoman,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'DEĞİŞİKLİKLERİ KAYDET' : 'KİTAP EKLE'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}