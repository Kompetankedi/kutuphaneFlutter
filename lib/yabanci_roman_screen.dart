// yabanci_roman_screen.dart - TAM KOD (Tablo ve Sütun Adları Düzeltildi)
import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:convert';
import 'add_edit_yabanci_roman_screen.dart';

class YabanciRomanScreen extends StatefulWidget {
  final SqlService sqlService;
  const YabanciRomanScreen({super.key, required this.sqlService});

  @override
  State<YabanciRomanScreen> createState() => _YabanciRomanScreenState();
}

class _YabanciRomanScreenState extends State<YabanciRomanScreen> {
  List<Map<String, dynamic>> _romanlar = [];
  List<Map<String, dynamic>> _filteredRomanlar = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRomans();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. VERİ ÇEKME İŞLEMİ (Tablo Adı Düzeltildi) ---
  Future<void> _fetchRomans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _romanlar = [];
      _filteredRomanlar = [];
    });

    try {
      // TABLO ADI DÜZELTİLDİ: dbo.YabanciRoman
      String query =
          'SELECT id, KitapAdi, KitapYazar, KitapNo FROM dbo.YabanciRoman';
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _romanlar = data.cast<Map<String, dynamic>>();
        _filterRecords();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Yabancı Romanlar çekilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- 2. FİLTRELEME (Sütun Adları Düzeltildi) ---
  void _filterRecords() {
    final String searchText = _searchController.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        _filteredRomanlar = _romanlar;
      } else {
        _filteredRomanlar = _romanlar.where((roman) {
          // SÜTUN ADLARI DÜZELTİLDİ: KitapAdi, KitapYazar
          final kitapAd = roman['KitapAdi']?.toString().toLowerCase() ?? '';
          final yazar = roman['KitapYazar']?.toString().toLowerCase() ?? '';

          return kitapAd.contains(searchText) || yazar.contains(searchText);
        }).toList();
      }
    });
  }

  // --- 3. SİLME İŞLEMİ (Tablo Adı Düzeltildi ve Onay Korundu) ---
  Future<void> _deleteYabanciRoman(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) return;

    // KAYIT SİLME ONAYI
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitap Silme Onayı'),
        content: const Text(
          'Bu yabancı roman kaydını kalıcı olarak silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TABLO ADI DÜZELTİLDİ: YabanciRoman
      String query = 'DELETE FROM YabanciRoman WHERE id = $id';
      await widget.sqlService.writeData(query);

      _fetchRomans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yabancı roman kaydı başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: ${e.toString()}')));
    }
  }

  void _navigateToAddEdit({Map<String, dynamic>? roman}) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditYabanciRomanScreen(
          sqlService: widget.sqlService,
          roman: roman,
        ),
      ),
    );

    if (shouldRefresh == true) {
      _fetchRomans();
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Kitap Adı veya Yazar Ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yabancı Romanlar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEdit(),
            tooltip: 'Yeni Roman Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRomans,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildSearchBar(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text('Hata: $_errorMessage'))
          : _filteredRomanlar.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'Aramanıza uygun kitap bulunamadı.'
                    : 'Kayıt bulunamadı.',
              ),
            )
          : ListView.builder(
              itemCount: _filteredRomanlar.length,
              itemBuilder: (context, index) {
                final roman = _filteredRomanlar[index];

                // SÜTUN ADLARI DÜZELTİLDİ: KitapAdi, KitapYazar, KitapNo
                String ad = roman['KitapAdi']?.toString() ?? 'Bilinmiyor';
                String yazar = roman['KitapYazar']?.toString() ?? 'Bilinmiyor';
                String kitapNo = roman['KitapNo']?.toString() ?? '—';
                dynamic id = roman['id'];
                // String sinif = roman['Ysınıf']?.toString() ?? '—'; // Bu sütun yok, kaldırıldı.

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(kitapNo)),
                    title: Text(
                      ad,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Yazar: $yazar\nKitap No: $kitapNo'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          tooltip: 'Düzenle',
                          onPressed: () => _navigateToAddEdit(roman: roman),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteYabanciRoman(id),
                        ),
                      ],
                    ),
                    isThreeLine: false,
                  ),
                );
              },
            ),
    );
  }
}
