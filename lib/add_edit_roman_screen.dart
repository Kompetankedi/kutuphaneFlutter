// lib/add_edit_roman_screen.dart
import 'package:flutter/material.dart';
import 'sql_service.dart';

class AddEditRomanScreen extends StatefulWidget {
  final SqlService sqlService;
  final Map<String, dynamic>? roman;

  const AddEditRomanScreen({super.key, required this.sqlService, this.roman});

  @override
  State<AddEditRomanScreen> createState() => _AddEditRomanScreenState();
}

class _AddEditRomanScreenState extends State<AddEditRomanScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _kitapAdiController;
  late final TextEditingController _kitapYazarController;
  late final TextEditingController _kitapNoController;

  bool get isEditing => widget.roman != null;

  @override
  void initState() {
    super.initState();
    _kitapAdiController = TextEditingController(text: widget.roman?['KitapAdi']?.toString() ?? '');
    _kitapYazarController = TextEditingController(text: widget.roman?['KitapYazar']?.toString() ?? '');
    // KitapNo'nun veritabanında bigint veya int olduğunu varsayarak String'e çeviriyoruz
    _kitapNoController = TextEditingController(text: widget.roman?['KitapNo']?.toString() ?? '');
  }

  @override
  void dispose() {
    _kitapAdiController.dispose();
    _kitapYazarController.dispose();
    _kitapNoController.dispose();
    super.dispose();
  }

  Future<void> _saveRoman() async {
    if (!_formKey.currentState!.validate()) return;

    // Güvenlik ve Türkçe karakter için tırnaklama yapılıyor.
    final String kitapAdi = _kitapAdiController.text.replaceAll("'", "''");
    final String kitapYazar = _kitapYazarController.text.replaceAll("'", "''");
    final int kitapNo = int.tryParse(_kitapNoController.text) ?? 0;

    String query;
    String successMessage;

    if (isEditing) {
      // GÜNCELLEME (UPDATE) SORGUSU

      // *** KRİTİK DÜZELTME: Veritabanından gelen ID String ise int'e çevrilir (Hata Fixi) ***
      final String idString = widget.roman!['id'].toString();
      final int id = int.parse(idString);

      query = '''
        UPDATE TrRoman SET 
        KitapAdi = N'$kitapAdi',          
        KitapYazar = N'$kitapYazar',      
        KitapNo = $kitapNo 
        WHERE id = $id
      ''';
      successMessage = 'Kitap başarıyla güncellendi.';
    } else {
      // EKLEME (INSERT) SORGUSU
      query = '''
        INSERT INTO TrRoman (KitapAdi, KitapYazar, KitapNo) 
        VALUES (N'$kitapAdi', N'$kitapYazar', $kitapNo)
      ''';
      successMessage = 'Kitap başarıyla eklendi.';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: ${e.toString()}. SQL sorgusunu kontrol edin.')),
      );
      print("SQL Yazma Hatası: $e"); // Debug için konsola da yazdır
    }
  }

  @override
  Widget build(BuildContext setContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Kitap Düzenle (ID: ${widget.roman!['id']})' : 'Yeni Kitap Ekle'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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