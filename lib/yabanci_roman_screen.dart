// yabanci_roman_screen.dart - Otomatik Kaydırma Eklendi
import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:async';
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
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageSize = 30;
  int _offset = 0;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _refreshRomans();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshRomans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _romanlar = [];
      _offset = 0;
      _hasMore = true;
    });

    await _loadRomansPage();
  }

  Future<void> _loadRomansPage() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final String searchText = _searchController.text.trim();
      final String escapedSearch = searchText.replaceAll("'", "''");
      final String whereClause = escapedSearch.isEmpty
          ? ''
          : "WHERE KitapAdi LIKE '%$escapedSearch%' OR KitapYazar LIKE '%$escapedSearch%' OR CAST(id AS VARCHAR(20)) LIKE '%$escapedSearch%' OR KitapNo LIKE '%$escapedSearch%'";

      final String query =
          'SELECT id, KitapAdi, KitapYazar, KitapNo FROM dbo.YabanciRoman $whereClause ORDER BY id OFFSET $_offset ROWS FETCH NEXT $_pageSize ROWS ONLY';
      final String jsonResult = await widget.sqlService.getData(query);

      final List<dynamic> data = jsonDecode(jsonResult);
      final List<Map<String, dynamic>> pageData = data
          .cast<Map<String, dynamic>>();

      setState(() {
        _romanlar.addAll(pageData);
        _offset += pageData.length;
        if (pageData.length < _pageSize) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Yabancı Romanlar çekilemedi: ${e.toString()}';
        _isLoading = false;
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _refreshRomans();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadRomansPage();
    }
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
      final String query = 'DELETE FROM YabanciRoman WHERE id = $id';
      await widget.sqlService.writeData(query);
      _refreshRomans();
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
      _refreshRomans();
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
                  onPressed: () {
                    _searchController.clear();
                    _refreshRomans();
                  },
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
            onPressed: _refreshRomans,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildSearchBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRomans,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text('Hata: $_errorMessage'))
            : _romanlar.isEmpty
            ? Center(
                child: Text(
                  _searchController.text.isNotEmpty
                      ? 'Aramanıza uygun kitap bulunamadı.'
                      : 'Kayıt bulunamadı.',
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                cacheExtent: 1000.0,
                itemCount: _romanlar.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _romanlar.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final roman = _romanlar[index];
                  final String ad =
                      roman['KitapAdi']?.toString() ?? 'Bilinmiyor';
                  final String yazar =
                      roman['KitapYazar']?.toString() ?? 'Bilinmiyor';
                  final String kitapNo = roman['KitapNo']?.toString() ?? '—';
                  final dynamic id = roman['id'];

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
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Düzenle',
                            onPressed: () => _navigateToAddEdit(roman: roman),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteYabanciRoman(id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
