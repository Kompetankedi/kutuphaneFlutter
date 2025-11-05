// yabanci_roman_screen.dart - Otomatik Kaydırma Eklendi
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
  final ScrollController _scrollController = ScrollController(); // KAYDIRMA KONTROLCÜSÜ

  @override
  void initState() {
    super.initState();
    _fetchRomans();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // KONTROLCÜYÜ TEMİZLE
    super.dispose();
  }

  Future<void> _fetchRomans({bool scrollToBottom = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String query = 'SELECT id, KitapAdi, KitapYazar, KitapNo FROM dbo.YabanciRoman ORDER BY id'; // ID'ye göre sırala
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _romanlar = data.cast<Map<String, dynamic>>();
        _filterRecords();
        _isLoading = false;
      });

      // EĞER YENİ KAYIT EKLENDİYSE LİSTENİN SONUNA GİT
      if (scrollToBottom && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Yabancı Romanlar çekilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterRecords() {
    final String searchText = _searchController.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        _filteredRomanlar = _romanlar;
      } else {
        _filteredRomanlar = _romanlar.where((roman) {
          final kitapAd = roman['KitapAdi']?.toString().toLowerCase() ?? '';
          final yazar = roman['KitapYazar']?.toString().toLowerCase() ?? '';
          final id = roman['id']?.toString().toLowerCase() ?? '';
          final kitapNo = roman['KitapNo']?.toString().toLowerCase() ?? '';

          return kitapAd.contains(searchText) ||
              yazar.contains(searchText) ||
              id.contains(searchText) ||
              kitapNo.contains(searchText);
        }).toList();
      }
    });
  }

  Future<void> _deleteYabanciRoman(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) return;

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

  // YENİ KİTAP EKLENDİĞİNDE LİSTENİN SONUNA GİTMEYİ TETİKLE
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
      _fetchRomans(scrollToBottom: roman == null);
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ID, Kitap Adı, Yazar veya Kitap No Ara...',
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
            onPressed: () => _fetchRomans(),
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
              controller: _scrollController, // KONTROLCÜYÜ ATA
              itemCount: _filteredRomanlar.length,
              itemBuilder: (context, index) {
                final roman = _filteredRomanlar[index];

                String ad = roman['KitapAdi']?.toString() ?? 'Bilinmiyor';
                String yazar = roman['KitapYazar']?.toString() ?? 'Bilinmiyor';
                String kitapNo = roman['KitapNo']?.toString() ?? '—';
                dynamic id = roman['id'];

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
