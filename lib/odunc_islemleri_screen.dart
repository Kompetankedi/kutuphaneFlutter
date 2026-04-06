// odunc_islemleri_screen.dart - TAM KOD (Tablo ve Sütun Adları Düzeltildi, Filtre Korundu)
import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'add_edit_odunc_screen.dart';

enum OduncFilter { all, notReturned }

class OduncIslemleriScreen extends StatefulWidget {
  final SqlService sqlService;
  const OduncIslemleriScreen({super.key, required this.sqlService});

  @override
  State<OduncIslemleriScreen> createState() => _OduncIslemleriScreenState();
}

class _OduncIslemleriScreenState extends State<OduncIslemleriScreen> {
  List<Map<String, dynamic>> _oduncKayitlari = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _pageSize = 50;
  int _offset = 0;
  String _errorMessage = '';

  OduncFilter _currentFilter = OduncFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _refreshOduncKayitlari();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshOduncKayitlari() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _oduncKayitlari = [];
      _offset = 0;
      _hasMore = true;
    });

    await _loadOduncKayitlariPage();
  }

  Future<void> _loadOduncKayitlariPage() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final String searchText = _searchController.text.trim();
      final String escapedSearch = searchText.replaceAll("'", "''");

      final String statusCondition = _currentFilter == OduncFilter.notReturned
          ? "WHERE UPPER(LTRIM(RTRIM(Oalındımı))) = 'ALINMADI'"
          : '';

      final String searchCondition = escapedSearch.isEmpty
          ? ''
          : "${statusCondition.isEmpty ? 'WHERE' : 'AND'} (Oisim LIKE '%$escapedSearch%' OR Okitap LIKE '%$escapedSearch%' OR Osınıf LIKE '%$escapedSearch%' OR CAST(id AS VARCHAR(20)) LIKE '%$escapedSearch%' OR Okitapid LIKE '%$escapedSearch%')";

      final String query =
          'SELECT id, Oisim, Okitap, Osınıf, Oalınmatarihi, Oiadetarih, Oalındımı, Okitapid FROM dbo.Oislemler $statusCondition $searchCondition ORDER BY id OFFSET $_offset ROWS FETCH NEXT $_pageSize ROWS ONLY';
      final String jsonResult = await widget.sqlService.getData(query);

      final List<dynamic> data = jsonDecode(jsonResult);
      final List<Map<String, dynamic>> pageData = data
          .cast<Map<String, dynamic>>();

      setState(() {
        _oduncKayitlari.addAll(pageData);
        _offset += pageData.length;
        if (pageData.length < _pageSize) {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ödünç Kayıtları çekilemedi: ${e.toString()}';
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
        _refreshOduncKayitlari();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadOduncKayitlariPage();
    }
  }

  Future<void> _deleteRecord(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kayıt Silme Onayı'),
        content: const Text(
          'Bu ödünç kaydını kalıcı olarak silmek istediğinizden emin misiniz?',
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
      final String query = 'DELETE FROM Oislemler WHERE id = $id';
      await widget.sqlService.writeData(query);

      _refreshOduncKayitlari();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödünç kaydı başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: ${e.toString()}')));
    }
  }

  void _navigateToAddEdit({Map<String, dynamic>? kayit}) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditOduncScreen(sqlService: widget.sqlService, kayit: kayit),
      ),
    );

    if (shouldRefresh == true) {
      _refreshOduncKayitlari();
    }
  }

  String _formatDate(dynamic dateString, {bool isIade = false}) {
    if (dateString == null ||
        dateString.toString().trim().isEmpty ||
        dateString.toString().toUpperCase() == 'NULL') {
      return isIade ? 'Bekleniyor' : '—';
    }
    try {
      return DateFormat(
        'dd.MM.yyyy',
      ).format(DateTime.parse(dateString.toString()));
    } catch (e) {
      return dateString.toString();
    }
  }

  Color _getStatusColor(String status) {
    String cleanStatus = status.toUpperCase().trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cleanStatus == 'ALINDI') {
      return isDark ? Colors.green.shade800 : Colors.green.shade50;
    } else if (cleanStatus == 'ALINMADI') {
      return isDark ? Colors.red.shade800 : Colors.red.shade50;
    }
    return isDark ? Colors.grey[850]! : Colors.white;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ID, Öğrenci, Kitap, Sınıf veya Kitap ID Ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _refreshOduncKayitlari();
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

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: SegmentedButton<OduncFilter>(
        segments: const <ButtonSegment<OduncFilter>>[
          ButtonSegment<OduncFilter>(
            value: OduncFilter.all,
            label: Text('Tümü'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment<OduncFilter>(
            value: OduncFilter.notReturned,
            label: Text('Teslim Edilmeyenler'),
            icon: Icon(Icons.warning_amber),
          ),
        ],
        selected: <OduncFilter>{_currentFilter},
        onSelectionChanged: (Set<OduncFilter> newSelection) {
          setState(() {
            _currentFilter = newSelection.first;
          });
          _refreshOduncKayitlari();
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withOpacity(0.1),
          selectedForegroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödünç İşlemleri'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEdit(),
            tooltip: 'Yeni Ödünç Kaydı Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOduncKayitlari,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Column(children: [_buildSearchBar(), _buildFilterButtons()]),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOduncKayitlari,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(child: Text('Hata: $_errorMessage'))
            : _oduncKayitlari.isEmpty
            ? Center(
                child: Text(
                  _searchController.text.isNotEmpty
                      ? 'Aramanıza uygun kayıt bulunamadı.'
                      : 'Kayıt bulunamadı.',
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                cacheExtent: 1000.0,
                itemCount: _oduncKayitlari.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _oduncKayitlari.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final kayit = _oduncKayitlari[index];
                  final String oisim =
                      kayit['Oisim']?.toString() ?? 'Bilinmiyor';
                  final String okitap =
                      kayit['Okitap']?.toString() ?? 'Kitap Adı Yok';
                  final String osinif = kayit['Osınıf']?.toString() ?? '—';
                  final String alindiMi =
                      kayit['Oalındımı']?.toString().toUpperCase().trim() ??
                      'Bilinmiyor';
                  final String alinmaTarihi = _formatDate(
                    kayit['Oalınmatarihi'],
                  );
                  final String iadeTarihi = _formatDate(
                    kayit['Oiadetarih'],
                    isIade: true,
                  );
                  final dynamic id = kayit['id'];

                  Widget actionButton;
                  if (alindiMi == 'ALINMADI') {
                    actionButton = IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.blue),
                      tooltip: 'Kitabı İade Et',
                      onPressed: () => _navigateToAddEdit(kayit: kayit),
                    );
                  } else {
                    actionButton = IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      tooltip: 'Kaydı Düzenle',
                      onPressed: () => _navigateToAddEdit(kayit: kayit),
                    );
                  }

                  return Card(
                    color: _getStatusColor(alindiMi),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(id.toString())),
                      title: Text(
                        okitap,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Öğrenci: $oisim - $osinif'),
                          Text('Veriliş: $alinmaTarihi'),
                          Text('İade: $iadeTarihi'),
                          const SizedBox(height: 4),
                          Text(
                            'Durum: $alindiMi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: alindiMi == 'ALINDI'
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.green.shade300
                                        : Colors.green.shade800)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.red.shade300
                                        : Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          actionButton,
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRecord(id),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
