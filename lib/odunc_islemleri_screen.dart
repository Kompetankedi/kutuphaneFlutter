import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'add_edit_odunc_screen.dart';

class OduncIslemleriScreen extends StatefulWidget {
  final SqlService sqlService;
  const OduncIslemleriScreen({super.key, required this.sqlService});

  @override
  State<OduncIslemleriScreen> createState() => _OduncIslemleriScreenState();
}

class _OduncIslemleriScreenState extends State<OduncIslemleriScreen> {
  List<Map<String, dynamic>> _oduncKayitlari = [];
  List<Map<String, dynamic>> _filteredOduncKayitlari = []; // Filtrelenmiş liste
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOduncKayitlari();
    _searchController.addListener(_filterRecords); // Arama dinleyicisi
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. VERİ ÇEKME İŞLEMİ ---
  Future<void> _fetchOduncKayitlari() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _oduncKayitlari = [];
      _filteredOduncKayitlari = [];
    });

    try {
      String query = 'SELECT * FROM dbo.Oislemler';
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _oduncKayitlari = data.cast<Map<String, dynamic>>();
        _filterRecords(); // Veri çekildikten sonra filtrele
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ödünç Kayıtları çekilemedi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- 2. ARAMA/FİLTRELEME İŞLEMİ ---
  void _filterRecords() {
    final String searchText = _searchController.text.toLowerCase();

    setState(() {
      if (searchText.isEmpty) {
        _filteredOduncKayitlari = _oduncKayitlari;
      } else {
        // Öğrenci Adı, Kitap Adı ve Sınıf ile arama yapılıyor
        _filteredOduncKayitlari = _oduncKayitlari.where((kayit) {
          final oisim = kayit['Oisim']?.toString().toLowerCase() ?? '';
          final okitap = kayit['Okitap']?.toString().toLowerCase() ?? '';
          final osinif = kayit['Osınıf']?.toString().toLowerCase() ?? '';

          return oisim.contains(searchText)
              || okitap.contains(searchText)
              || osinif.contains(searchText);
        }).toList();
      }
    });
  }

  // --- 3. SİLME İŞLEMİ ---
  Future<void> _deleteRecord(dynamic idDynamic) async {
    final int id = int.tryParse(idDynamic.toString()) ?? 0;

    if (id == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kayıt Silme Onayı'),
        content: const Text('Bu ödünç kaydını kalıcı olarak silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hayır')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Evet, Sil')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      String query = 'DELETE FROM Oislemler WHERE id = $id';
      await widget.sqlService.writeData(query);

      _fetchOduncKayitlari();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödünç kaydı başarıyla silindi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silme hatası: ${e.toString()}')),
      );
    }
  }

  // --- 4. YÖNLENDİRME (EKLEME/GÜNCELLEME) ---
  void _navigateToAddEdit({Map<String, dynamic>? kayit}) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditOduncScreen(
          sqlService: widget.sqlService,
          kayit: kayit, // Güncelleme için kayıt gönderilir, Yeni kayıt için null
        ),
      ),
    );

    // Formdan 'true' sinyali gelirse listeyi yenile
    if (shouldRefresh == true) {
      _fetchOduncKayitlari();
    }
  }

  // --- 5. YARDIMCI METOTLAR (TARİH VE RENK) ---

  String _formatDate(dynamic dateString) {
    if (dateString == null || dateString.toString().trim().isEmpty || dateString.toString().toUpperCase() == 'NULL') {
      return '—';
    }
    try {
      // Örnek format: "Oct 9 2023 12:00:00" -> "09.10.2023"
      return DateFormat('dd.MM.yyyy').format(DateTime.parse(dateString.toString()));
    } catch (e) {
      return dateString.toString();
    }
  }

  Color _getStatusColor(String status) {
    String cleanStatus = status.toUpperCase().trim();
    if (cleanStatus == 'ALINDI') {
      return Colors.green.shade50;
    } else if (cleanStatus == 'ALINMADI') {
      // Not: İade tarihi geçmişse rengi daha koyu yapmak için burada mantık eklenebilir.
      return Colors.red.shade50;
    }
    return Colors.white;
  }

  // --- 6. UI (WIDGET) OLUŞTURMA ---

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
        title: const Text('Ödünç İşlemleri'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddEdit(), // Ekleme Formuna Yönlendirme
            tooltip: 'Yeni Ödünç Kaydı Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOduncKayitlari,
            tooltip: 'Yenile',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildSearchBar(), // Arama çubuğu eklendi
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text('Hata: $_errorMessage'))
          : _filteredOduncKayitlari.isEmpty
          ? Center(child: Text(_searchController.text.isNotEmpty ? 'Aramanıza uygun kayıt bulunamadı.' : 'Kayıt bulunamadı.'))
          : ListView.builder(
        itemCount: _filteredOduncKayitlari.length,
        itemBuilder: (context, index) {
          final kayit = _filteredOduncKayitlari[index];

          String oisim = kayit['Oisim']?.toString() ?? 'Bilinmiyor';
          String okitap = kayit['Okitap']?.toString() ?? 'Kitap Adı Yok';
          String osinif = kayit['Osınıf']?.toString() ?? '—';
          String alindiMi = kayit['Oalındımı']?.toString() ?? 'Bilinmiyor';
          String alinmaTarihi = _formatDate(kayit['Oalınmatarihi']);
          String iadeTarihi = _formatDate(kayit['Oiadetarihi']);
          dynamic id = kayit['id'];

          // İade durumuna göre aksiyon butonu (İade et veya Düzenle)
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
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text(id.toString())),
              title: Text('$okitap - $osinif', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Öğrenci: $oisim'),
                  Text('Veriliş: $alinmaTarihi'),
                  Text('İade: $iadeTarihi'),
                  const SizedBox(height: 4),
                  Text(
                    'Durum: $alindiMi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alindiMi == 'ALINDI' ? Colors.green.shade800 : Colors.red.shade800,
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