import 'package:flutter/material.dart';

class KitapSecScreen extends StatefulWidget {
  final List<Map<String, dynamic>> kitaplar;
  const KitapSecScreen({Key? key, required this.kitaplar}) : super(key: key);

  @override
  State<KitapSecScreen> createState() => _KitapSecScreenState();
}

class _KitapSecScreenState extends State<KitapSecScreen> {
  String _arama = '';
  String _kitapTuru = 'Hepsi'; // 'TrRoman', 'YabanciRoman', 'Hepsi'

  @override
  Widget build(BuildContext context) {
    final filtreliKitaplar = widget.kitaplar.where((kitap) {
      final arama = _arama.toLowerCase();
      final tur = kitap['KitapTuru']?.toString() ?? '';
      final turFiltre = _kitapTuru == 'Hepsi' || tur == _kitapTuru;
      return turFiltre &&
          (kitap['KitapAdi'].toString().toLowerCase().contains(arama) ||
              kitap['KitapNo'].toString().toLowerCase().contains(arama) ||
              (kitap['Yazar']?.toString().toLowerCase().contains(arama) ??
                  false));
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Seç')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Kitap adı, yazar veya no ile ara',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _arama = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kitapTuru == 'TrRoman'
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: _kitapTuru == 'TrRoman'
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _kitapTuru = 'TrRoman'),
                    child: const Text('Yerli Romanlar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kitapTuru == 'YabanciRoman'
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: _kitapTuru == 'YabanciRoman'
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () =>
                        setState(() => _kitapTuru = 'YabanciRoman'),
                    child: const Text('Yabancı Romanlar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kitapTuru == 'Hepsi'
                          ? Colors.blue
                          : Colors.grey[300],
                      foregroundColor: _kitapTuru == 'Hepsi'
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => setState(() => _kitapTuru = 'Hepsi'),
                    child: const Text('Hepsi'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtreliKitaplar.length,
              itemBuilder: (context, i) {
                final kitap = filtreliKitaplar[i];
                return ListTile(
                  title: Text(kitap['KitapAdi'] ?? ''),
                  subtitle: Text(
                    'No: ${kitap['KitapNo'] ?? ''}  Yazar: ${kitap['Yazar'] ?? '-'}',
                  ),
                  trailing: Text(
                    kitap['KitapTuru'] == 'TrRoman' ? 'Yerli' : 'Yabancı',
                  ),
                  onTap: () => Navigator.pop(context, kitap),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
