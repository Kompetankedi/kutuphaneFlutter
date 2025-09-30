// lib/add_edit_odunc_screen.dart
import 'package:flutter/material.dart';
import 'sql_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddEditOduncScreen extends StatefulWidget {
  final SqlService sqlService;
  final Map<String, dynamic>? kayit;

  const AddEditOduncScreen({super.key, required this.sqlService, this.kayit});

  @override
  State<AddEditOduncScreen> createState() => _AddEditOduncScreenState();
}

class _AddEditOduncScreenState extends State<AddEditOduncScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _oisimController;
  late final TextEditingController _osinifController;

  List<Map<String, dynamic>> _kitaplar = [];
  Map<String, dynamic>? _selectedKitap;
  bool _isLoadingKitaplar = true;
  String? _kitaplarError;

  late DateTime _alinmaTarihi;
  DateTime? _iadeTarihi;

  String _alindiMiStatus = 'ALINMADI';

  bool get isEditing => widget.kayit != null;

  DateTime _parseNvarcharDate(String dateStr) {
    dateStr = dateStr.trim();
    if (dateStr.isEmpty || dateStr.toUpperCase() == 'NULL') {
      return DateTime.now();
    }

    try {
      if (dateStr.contains('-')) return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (_) {}

    try {
      if (dateStr.contains('.')) return DateFormat('dd.MM.yyyy').parse(dateStr);
    } catch (_) {}

    try {
      return DateFormat('MMM dd yyyy hh:mma', 'en_US').parse(dateStr);
    } catch (_) {}

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print(
        "KRİTİK HATA: Eski verideki tarih formatı ayrılamadı: $dateStr, Hata: $e",
      );
      return DateTime.now();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchKitaplar();

    if (isEditing) {
      _oisimController = TextEditingController(
        text: widget.kayit!['Oisim']?.toString() ?? '',
      );
      _osinifController = TextEditingController(
        text: widget.kayit!['Osınıf']?.toString() ?? '',
      );

      String alinmaTarihiStr =
          widget.kayit!['Oalınmatarihi']?.toString().trim() ?? '';
      _alinmaTarihi = _parseNvarcharDate(alinmaTarihiStr);

      // 🔹 Burada düzeltildi: Oiadetarihi → Oiadetarih
      String iadeTarihiStr =
          widget.kayit!['Oiadetarih']?.toString().trim() ?? '';
      if (iadeTarihiStr.isNotEmpty) {
        _iadeTarihi = _parseNvarcharDate(iadeTarihiStr);
      } else {
        _iadeTarihi = null;
      }

      _alindiMiStatus =
          widget.kayit!['Oalındımı']?.toString().toUpperCase().trim() ??
              'ALINMADI';
    } else {
      _oisimController = TextEditingController();
      _osinifController = TextEditingController();
      _alinmaTarihi = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
    }
  }

  @override
  void dispose() {
    _oisimController.dispose();
    _osinifController.dispose();
    super.dispose();
  }

  Future<void> _fetchKitaplar() async {
    try {
      String query = '''
        SELECT KitapAdi, KitapNo, id, 'TrRoman' as KitapTuru FROM TrRoman
        UNION ALL
        SELECT KitapAdi, KitapNo, id, 'YabanciRoman' as KitapTuru FROM YabanciRoman
      ''';
      String jsonResult = await widget.sqlService.getData(query);

      List<dynamic> data = jsonDecode(jsonResult);

      setState(() {
        _kitaplar = data.cast<Map<String, dynamic>>();
        _isLoadingKitaplar = false;

        if (isEditing) {
          String currentKitapAdi = widget.kayit!['Okitap']?.toString() ?? '';
          _selectedKitap = _kitaplar.firstWhere(
                (k) => k['KitapAdi']?.toString() == currentKitapAdi,
            orElse: () => null!,
          );
        }
      });
    } catch (e) {
      setState(() {
        _kitaplarError = 'Kitap listesi çekilemedi: ${e.toString()}';
        _isLoadingKitaplar = false;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, {
        required bool isAlinmaTarihi,
      }) async {
    DateTime initialDate = isAlinmaTarihi
        ? _alinmaTarihi
        : (_iadeTarihi ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      DateTime finalDate = DateTime(picked.year, picked.month, picked.day);

      setState(() {
        if (isAlinmaTarihi) {
          _alinmaTarihi = finalDate;
        } else {
          _iadeTarihi = finalDate;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate() ||
        (!isEditing && _selectedKitap == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun ve bir kitap seçin.'),
        ),
      );
      return;
    }

    String _cleanString(String text) {
      return text.replaceAll("'", "''");
    }

    final String oisim = _cleanString(_oisimController.text);
    final String osinif = _cleanString(_osinifController.text);

    final String alinmaTarihiFormatted = DateFormat(
      'yyyy-MM-dd',
    ).format(_alinmaTarihi);

    String query;
    String successMessage;

    if (isEditing) {
      final int id = int.tryParse(widget.kayit!['id'].toString()) ?? 0;

      String iadeTarihiSQLValue;
      if (_alindiMiStatus == 'ALINDI' && _iadeTarihi != null) {
        iadeTarihiSQLValue = DateFormat('yyyy-MM-dd').format(_iadeTarihi!);
      } else {
        iadeTarihiSQLValue = '';
      }

      // 🔹 Burada da düzeltildi: Oiadetarihi → Oiadetarih
      query =
      '''
  UPDATE Oislemler SET  
    Oisim = N'$oisim',          
    Osınıf = N'$osinif',
    Oalınmatarihi = N'$alinmaTarihiFormatted',
    Oiadetarih = N'$iadeTarihiSQLValue',
    Oalındımı = N'$_alindiMiStatus'
  WHERE id = $id
      ''';
      successMessage = 'Ödünç kaydı bilgileri başarıyla güncellendi.';
    } else {
      final String okitap = _cleanString(
        _selectedKitap!['KitapAdi']?.toString() ?? 'Bilinmeyen Kitap',
      );
      final int okitapid =
          int.tryParse(_selectedKitap!['KitapNo']?.toString() ?? '0') ?? 0;

      query =
      '''
        INSERT INTO Oislemler (Oisim, Okitap, Okitapid, Oalınmatarihi, Oalındımı, Osınıf) 
        VALUES (N'$oisim', N'$okitap', $okitapid, N'$alinmaTarihiFormatted', N'ALINMADI', N'$osinif')
      ''';
      successMessage = 'Kitap başarıyla ödünç verildi.';
    }

    try {
      await widget.sqlService.writeData(query);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      print("SQL Yazma Hatası: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu: ${e.toString()}')));
    }
  }

  Widget _buildKitapWidget() {
    if (!isEditing) {
      if (_isLoadingKitaplar) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_kitaplarError != null || _kitaplar.isEmpty) {
        return Text(
          _kitaplarError ?? 'Kütüphanede ödünç verilebilecek kitap bulunamadı.',
          style: const TextStyle(color: Colors.red),
        );
      }

      return DropdownButtonFormField<Map<String, dynamic>>(
        decoration: const InputDecoration(
          labelText: 'Verilecek Kitap Seçin',
          border: OutlineInputBorder(),
        ),
        value: _selectedKitap,
        hint: const Text('Kitap Seçiniz'),
        items: _kitaplar.map((kitap) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: kitap,
            child: Text(
              '${kitap['KitapAdi']} (No: ${kitap['KitapNo']}) - ${kitap['KitapTuru'] == 'TrRoman' ? 'T' : 'Y'}',
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedKitap = newValue;
          });
        },
        validator: (value) => value == null ? 'Lütfen bir kitap seçin.' : null,
      );
    } else {
      return Card(
        color: Colors.blue.shade50,
        child: ListTile(
          title: Text(
            widget.kayit!['Okitap']?.toString() ?? 'Kitap Adı Yok',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Kitap No: ${widget.kayit!['Okitapid']?.toString() ?? '—'}',
          ),
          leading: const Icon(Icons.book),
        ),
      );
    }
  }

  Widget _buildDateSelector(
      String label,
      DateTime? date, {
        required bool isAlinmaTarihi,
      }) {
    String dateText = date != null
        ? DateFormat('dd.MM.yyyy').format(date)
        : 'Tarih Seçilmedi';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $dateText',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                _selectDate(context, isAlinmaTarihi: isAlinmaTarihi),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Seç/Değiştir'),
          ),
          if (!isAlinmaTarihi && date != null)
            TextButton(
              onPressed: () => setState(() {
                _iadeTarihi = null;
              }),
              child: const Text('Temizle', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext setContext) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Ödünç Kaydını Düzenle (ID: ${widget.kayit!['id']})'
              : 'Yeni Ödünç Kaydı Ekle',
        ),
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
                controller: _oisimController,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci Adı Soyadı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Öğrenci Adı gereklidir.'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _osinifController,
                decoration: const InputDecoration(
                  labelText: 'Sınıfı (Örn: 10-C)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Sınıf bilgisi gereklidir.'
                    : null,
              ),
              const SizedBox(height: 24),

              _buildKitapWidget(),

              const SizedBox(height: 24),

              if (isEditing) ...[
                _buildDateSelector(
                  'Ödünç Veriliş Tarihi',
                  _alinmaTarihi,
                  isAlinmaTarihi: true,
                ),
                _buildDateSelector(
                  'İade Ediliş Tarihi',
                  _iadeTarihi,
                  isAlinmaTarihi: false,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'İade Durumu',
                    border: OutlineInputBorder(),
                  ),
                  value: _alindiMiStatus,
                  items: ['ALINDI', 'ALINMADI'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _alindiMiStatus = newValue!;
                      if (newValue == 'ALINDI' && _iadeTarihi == null) {
                        _iadeTarihi = DateTime.now();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (!isEditing)
                Text(
                  'Ödünç Veriliş Tarihi: ${DateFormat('dd.MM.yyyy').format(_alinmaTarihi)} (Şimdi)',
                ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _saveRecord,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'KAYDI GÜNCELLE' : 'ÖDÜNÇ VER'),
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
