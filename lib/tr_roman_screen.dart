// lib/tr_roman_screen.dart
import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:convert';
import 'add_edit_roman_screen.dart';

class TrRomanScreen extends StatefulWidget {
  final SqlService sqlService;
  const TrRomanScreen({super.key, required this.sqlService});

  @override
  State<TrRomanScreen> createState() => _TrRomanScreenState();
}

class _TrRomanScreenState extends State<TrRomanScreen> {
  List<Map<String, dynamic>> _romanlar = [];
  List<Map<String, dynamic>> _filteredRomanlar = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRomans();
    _searchController.addListener(_filterRomans);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. VERİ ÇEKME VE FİLTRELEME ---
  Future<void> _fetchRomans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _romanlar = [];
      _filteredRomanlar = [];
    });

    try {
      String query = 'SELECT id, KitapAdi, KitapYazar, KitapNo FROM TrRoman';
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _romanlar = data.cast<Map<String, dynamic>>();
        _filterRomans(); // Veri çekildikten sonra ilk filtrelemeyi yap
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri çekilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterRomans() {
    final String searchText = _searchController.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        _filteredRomanlar = _romanlar;
      } else {
        _filteredRomanlar = _romanlar.where((roman) {
          final kitapAdi = roman['KitapAdi']?.toString().toLowerCase() ?? '';
          final yazar = roman['KitapYazar']?.toString().toLowerCase() ?? '';
          // *** GÜNCELLEME: Kitap No da aramaya dahil edildi ***
          final kitapNo = roman['KitapNo']?.toString().toLowerCase() ?? '';

          return kitapAdi.contains(searchText)
              || yazar.contains(searchText)
              || kitapNo.contains(searchText);
        }).toList();
      }
    });
  }

  // --- 2. EKLEME / GÜNCELLEME İŞLEMİ İÇİN YÖNLENDİRME ---
  void _navigateToAddEdit({Map<String, dynamic>? roman}) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRomanScreen(
          sqlService: widget.sqlService,
          roman: roman,
        ),
      ),
    );

    // Formdan 'true' sinyali gelirse veriyi yenile
    if (shouldRefresh == true) {
      _fetchRomans();
    }
  }

  // --- 3. SİLME İŞLEMİ ---
  Future<void> _deleteRoman(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Silinecek kayıt ID\'si geçersiz.')),
      );
      return;
    }

    final String silinecekKitapAdi = _romanlar.firstWhere(
            (r) => r['id']?.toString() == idDynamic.toString(),
        orElse: () => {'KitapAdi': 'Bu kitabı'}
    )['KitapAdi']?.toString() ?? 'Bu kitabı';


    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('$silinecekKitapAdi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hayır')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Evet, Sil')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      String query = 'DELETE FROM TrRoman WHERE id = $id';
      await widget.sqlService.writeData(query);

      _fetchRomans();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: ${e.toString()}')),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Kitap Adı, Yazar veya Kitap No Ara...', // Hint güncellendi
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Türkçe Romanlar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEdit(),
            tooltip: 'Yeni Kitap Ekle',
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
          ? Center(child: Text(_searchController.text.isNotEmpty ? 'Aramanıza uygun kayıt bulunamadı.' : 'Kayıt bulunamadı.'))
          : ListView.builder(
        itemCount: _filteredRomanlar.length,
        itemBuilder: (context, index) {
          final roman = _filteredRomanlar[index];

          String kitapAdi = roman['KitapAdi']?.toString() ?? 'Başlık Yok';
          String yazar = roman['KitapYazar']?.toString() ?? 'Yazar Bilinmiyor';
          String kitapNo = roman['KitapNo']?.toString() ?? '—';
          dynamic id = roman['id'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text(kitapNo)),
              title: Text(kitapAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Yazar: $yazar'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToAddEdit(roman: roman),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRoman(id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}