// odunc_islemleri_screen.dart - TAM KOD (Tablo ve Sütun Adları Düzeltildi, Filtre Korundu)
import 'package:flutter/material.dart';
import 'sql_service.dart';
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
  List<Map<String, dynamic>> _filteredOduncKayitlari = [];
  bool _isLoading = true;
  String _errorMessage = '';

  OduncFilter _currentFilter = OduncFilter.all;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOduncKayitlari();
    _searchController.addListener(_filterRecords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. VERİ ÇEKME İŞLEMİ (Tablo ve Sütun Adları Düzeltildi) ---
  Future<void> _fetchOduncKayitlari() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _oduncKayitlari = [];
      _filteredOduncKayitlari = [];
    });

    try {
      // TABLO ADI DÜZELTİLDİ ve gerekli tüm sütunlar eklendi
      String query =
          'SELECT id, Oisim, Okitap, Osınıf, Oalınmatarihi, Oiadetarih, Oalındımı, Okitapid FROM dbo.Oislemler';
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _oduncKayitlari = data.cast<Map<String, dynamic>>();
        _filterRecords();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ödünç Kayıtları çekilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- 2. FİLTRELEME İŞLEMİ (Sütun Adları Düzeltildi) ---
  void _filterRecords() {
    final String searchText = _searchController.text.toLowerCase();

    // 1. Durum filtresi uygulanır.
    List<Map<String, dynamic>> statusFilteredList;

    if (_currentFilter == OduncFilter.notReturned) {
      statusFilteredList = _oduncKayitlari.where((kayit) {
        // SÜTUN ADI DÜZELTİLDİ: Oalındımı
        final alindiMi =
            kayit['Oalındımı']?.toString().toUpperCase().trim() ?? '';
        return alindiMi == 'ALINMADI';
      }).toList();
    } else {
      statusFilteredList = _oduncKayitlari;
    }

    // 2. Arama metni filtresi uygulanır.
    setState(() {
      if (searchText.isEmpty) {
        _filteredOduncKayitlari = statusFilteredList;
      } else {
        // SÜTUN ADLARI DÜZELTİLDİ: Oisim, Okitap, Osınıf
        _filteredOduncKayitlari = statusFilteredList.where((kayit) {
          final oisim = kayit['Oisim']?.toString().toLowerCase() ?? '';
          final okitap = kayit['Okitap']?.toString().toLowerCase() ?? '';
          final osinif = kayit['Osınıf']?.toString().toLowerCase() ?? '';

          return oisim.contains(searchText) ||
              okitap.contains(searchText) ||
              osinif.contains(searchText);
        }).toList();
      }
    });
  }

  // --- 3. SİLME İŞLEMİ (Tablo Adı Düzeltildi ve Onay Korundu) ---
  Future<void> _deleteRecord(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) return;

    // KAYIT SİLME ONAYI KORUNDU
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
      // TABLO ADI DÜZELTİLDİ: Oislemler
      String query = 'DELETE FROM Oislemler WHERE id = $id';
      await widget.sqlService.writeData(query);

      _fetchOduncKayitlari();
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
      _fetchOduncKayitlari();
    }
  }

  // SÜTUN ADLARI DÜZELTİLDİ: Oalınmatarihi, Oiadetarih
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
          hintText: 'Öğrenci, Kitap veya Sınıf Ara...',
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
            _filterRecords();
          });
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
            onPressed: _fetchOduncKayitlari,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120.0),
          child: Column(children: [_buildSearchBar(), _buildFilterButtons()]),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text('Hata: $_errorMessage'))
          : _filteredOduncKayitlari.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'Aramanıza uygun kayıt bulunamadı.'
                    : 'Kayıt bulunamadı.',
              ),
            )
          : ListView.builder(
              itemCount: _filteredOduncKayitlari.length,
              itemBuilder: (context, index) {
                final kayit = _filteredOduncKayitlari[index];

                // SÜTUN ADLARI DÜZELTİLDİ: Oisim, Okitap, Osınıf, Oalınmatarihi, Oiadetarih, Oalındımı
                String oisim = kayit['Oisim']?.toString() ?? 'Bilinmiyor';
                String okitap = kayit['Okitap']?.toString() ?? 'Kitap Adı Yok';
                String osinif = kayit['Osınıf']?.toString() ?? '—';
                String alindiMi =
                    kayit['Oalındımı']?.toString().toUpperCase().trim() ??
                    'Bilinmiyor';
                String alinmaTarihi = _formatDate(kayit['Oalınmatarihi']);
                String iadeTarihi = _formatDate(
                  kayit['Oiadedarihi'],
                  isIade: true,
                ); // Tarih formatı metodu güncellendi
                dynamic id = kayit['id'];

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
                      '$okitap',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ), // Kitap adı
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Öğrenci: $oisim - $osinif',
                        ), // Öğrenci ve Sınıf birleştirildi
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
    );
  }
}
