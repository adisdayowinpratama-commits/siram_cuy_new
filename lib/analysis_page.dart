part of 'main.dart';

class AnalysisPage extends StatefulWidget {
  final Color panel;
  final Color muted;
  final Color border;
  final ValueChanged<AnalysisRecord> onAnalyze;
  final ValueChanged<String> onChooseCrop;
  final AnalysisRecord? latest;
  final List<LandRecord> lands;

  const AnalysisPage({
    super.key,
    required this.panel,
    required this.muted,
    required this.border,
    required this.onAnalyze,
    required this.onChooseCrop,
    required this.latest,
    required this.lands,
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _landController = TextEditingController();
  String? _selectedLandName;
  double _ph = 6.2;
  String? _texture;
  String? _moisture;
  String? _fertility;
  String? _drainage;
  String? _sunlight;
  List<CropMatch>? _results;
  String? _statusMessage;

  @override
  void dispose() {
    _landController.dispose();
    super.dispose();
  }

  int _phScore(double value, CropProfile crop) {
    if (value >= crop.phMin && value <= crop.phMax) return 100;
    final distance = value < crop.phMin ? crop.phMin - value : value - crop.phMax;
    if (distance <= 0.5) return 75;
    if (distance <= 1.0) return 50;
    if (distance <= 1.5) return 25;
    return 0;
  }

  int _categoryScore(String value, List<String> goodValues) => goodValues.contains(value) ? 100 : 30;

  List<CropMatch> _calculateMatches() {
    final ranked = <CropMatch>[];
    for (final crop in cropProfiles) {
      final phScore = _phScore(_ph, crop);
      final textureScore = _categoryScore(_texture!, crop.textures);
      final moistureScore = _categoryScore(_moisture!, crop.moisture);
      final fertilityScore = _categoryScore(_fertility!, crop.fertility);
      final drainageScore = _categoryScore(_drainage!, crop.drainage);
      final sunlightScore = _categoryScore(_sunlight!, crop.sunlight);
      final score = ((phScore * 0.30) +
              (textureScore * 0.20) +
              (moistureScore * 0.15) +
              (fertilityScore * 0.10) +
              (drainageScore * 0.15) +
              (sunlightScore * 0.10))
          .round();

      final matches = <String>[];
      final cautions = <String>[];
      if (phScore == 100) {
        matches.add('pH ${_ph.toStringAsFixed(1)} berada dalam rentang acuan ${crop.phMin.toStringAsFixed(1)}–${crop.phMax.toStringAsFixed(1)}.');
      } else {
        cautions.add('pH ${_ph.toStringAsFixed(1)} berada di luar rentang acuan ${crop.phMin.toStringAsFixed(1)}–${crop.phMax.toStringAsFixed(1)}.');
      }
      if (textureScore == 100) {
        matches.add('Tekstur ${_texture!} termasuk jenis tanah yang diprioritaskan pada profil demo.');
      } else {
        cautions.add('Tekstur ${_texture!} bukan tekstur utama pada profil demo tanaman ini.');
      }
      if (moistureScore == 100) {
        matches.add('Kelembapan ${_moisture!} sesuai dengan kondisi yang dipilih untuk profil demo.');
      } else {
        cautions.add('Perhatikan kebutuhan air: input kelembapan saat ini ${_moisture!}.');
      }
      if (fertilityScore == 100) {
        matches.add('Kesuburan ${_fertility!} sesuai dengan asumsi kebutuhan pada profil demo.');
      } else {
        cautions.add('Kesuburan ${_fertility!} mungkin perlu dievaluasi melalui uji tanah.');
      }
      if (drainageScore < 100) {
        cautions.add('Drainase ${_drainage!} perlu dicek agar sesuai dengan kebutuhan tanaman.');
      } else {
        matches.add('Kondisi drainase sesuai dengan profil demo tanaman.');
      }
      if (sunlightScore < 100) {
        cautions.add('Periksa paparan matahari untuk tanaman ini.');
      } else {
        matches.add('Paparan matahari sesuai dengan profil demo tanaman.');
      }

      ranked.add(CropMatch(crop: crop, score: score, matches: matches, cautions: cautions));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  void _analyze() {
    if (_texture == null || _moisture == null || _fertility == null ||
        _drainage == null || _sunlight == null) {
      setState(() => _statusMessage = 'Pilih semua kondisi tanah terlebih dahulu, atau pilih lahan tersimpan yang memiliki data lengkap.');
      return;
    }
    final results = _calculateMatches();
    final record = AnalysisRecord(
      createdAt: DateTime.now(),
      landName: _landController.text.trim(),
      ph: _ph,
      texture: _texture!,
      moisture: _moisture!,
      fertility: _fertility!,
      drainage: _drainage!,
      sunlight: _sunlight!,
      results: results,
    );
    setState(() {
      _results = results;
      _statusMessage = _selectedLandName == null
          ? 'Analisis berhasil dibuat berdasarkan data yang kamu masukkan.'
          : 'Analisis untuk lahan $_selectedLandName berhasil dibuat menggunakan data tanah tersimpan.';
    });
    widget.onAnalyze(record);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const SectionHeading(title: 'Analisis kondisi tanah', subtitle: 'Lengkapi data untuk mendapat urutan rekomendasi'),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: widget.panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: widget.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormSectionTitle(number: '01', title: 'Identitas lahan', subtitle: 'Agar hasil analisis mudah dikenali'),
              const SizedBox(height: 13),
              DropdownButtonFormField<String?>(
                value: _selectedLandName,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: uiText('Pilih lahan tersimpan'),
                  hintText: uiText('Pilih lahan untuk memakai data tanahnya'),
                  prefixIcon: const Icon(Icons.landscape_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(uiText('Pilih lahan (input manual)'))),
                  ...widget.lands.map((land) => DropdownMenuItem<String?>(value: land.name, child: Text(land.name))),
                ],
                onChanged: (name) {
                  final matches = widget.lands.where((land) => land.name == name).toList();
                  setState(() {
                    _selectedLandName = name;
                    if (name == null || matches.isEmpty) {
                      _landController.clear();
                      _texture = null; _moisture = null; _fertility = null; _drainage = null; _sunlight = null;
                      _results = null;
                      _statusMessage = null;
                    } else {
                      final land = matches.first;
                      _landController.text = land.name;
                      if (land.ph != null) _ph = land.ph!.clamp(3.0, 10.0).toDouble();
                      _texture = ['Pasir', 'Lempung berpasir', 'Lempung', 'Liat'].contains(land.texture) ? land.texture : null;
                      _moisture = ['Kering', 'Sedang', 'Basah'].contains(land.moisture) ? land.moisture : null;
                      _fertility = ['Rendah', 'Sedang', 'Tinggi'].contains(land.fertility) ? land.fertility : null;
                      _drainage = ['Baik', 'Sedang', 'Buruk'].contains(land.drainage) ? land.drainage : null;
                      _sunlight = ['Matahari penuh', 'Matahari sebagian', 'Teduh'].contains(land.sunlight) ? land.sunlight : null;
                      _results = null;
                      _statusMessage = 'Data tanah dari lahan ${land.name} dimuat. Lengkapi data yang masih bertuliskan Pilih.';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _landController,
                decoration: InputDecoration(labelText: uiText('Nama lahan manual (opsional)'), prefixIcon: Icon(Icons.edit_location_alt_outlined), hintText: uiText('Isi jika belum memilih lahan tersimpan')),
                onChanged: (_) { if (_selectedLandName != null) setState(() => _selectedLandName = null); },
              ),
              const SizedBox(height: 22),
              const FormSectionTitle(number: '02', title: 'Data tanah', subtitle: 'Gunakan data hasil pengukuran bila tersedia'),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: Text(uiText('pH tanah'), style: TextStyle(fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Text(_ph.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 17)))]),
              Slider(value: _ph, min: 3, max: 10, divisions: 70, label: _ph.toStringAsFixed(1), onChanged: (value) => setState(() => _ph = value)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(uiText('Asam'), style: TextStyle(color: widget.muted, fontSize: 11)), Text(uiText('Netral ≈ 7'), style: TextStyle(color: widget.muted, fontSize: 11)), Text(uiText('Basa'), style: TextStyle(color: widget.muted, fontSize: 11))]),
              const SizedBox(height: 14),
              _dropdown<String>(label: 'Tekstur tanah', icon: Icons.grain_rounded, value: _texture, values: const ['Pasir', 'Lempung berpasir', 'Lempung', 'Liat'], onChanged: (v) => setState(() => _texture = v)),
              const SizedBox(height: 13),
              _dropdown<String>(label: 'Kelembapan tanah', icon: Icons.water_drop_outlined, value: _moisture, values: const ['Kering', 'Sedang', 'Basah'], onChanged: (v) => setState(() => _moisture = v)),
              const SizedBox(height: 13),
              _dropdown<String>(label: 'Kesuburan tanah', icon: Icons.eco_outlined, value: _fertility, values: const ['Rendah', 'Sedang', 'Tinggi'], onChanged: (v) => setState(() => _fertility = v)),
              const SizedBox(height: 13),
              _dropdown<String>(label: 'Drainase lahan', icon: Icons.water_outlined, value: _drainage, values: const ['Baik', 'Sedang', 'Buruk'], onChanged: (v) => setState(() => _drainage = v)),
              const SizedBox(height: 13),
              _dropdown<String>(label: 'Paparan matahari', icon: Icons.wb_sunny_outlined, value: _sunlight, values: const ['Matahari penuh', 'Matahari sebagian', 'Teduh'], onChanged: (v) => setState(() => _sunlight = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _analyze,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(uiText('Analisis tanah & rekomendasikan tanaman'), style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 11),
              Text(uiText('Tidak memakai sensor atau IoT. Hasil bergantung pada data manual yang diinput pengguna.'), style: TextStyle(fontSize: 11, color: widget.muted, height: 1.4)),
            ],
          ),
        ),
        if (_results != null) ...[
          const SizedBox(height: 24),
          const SectionHeading(title: 'Hasil rekomendasi', subtitle: 'Peringkat berdasarkan bobot kecocokan versi demo'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF15803D).withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22C55E)), const SizedBox(width: 10), Expanded(child: Text(uiText(_statusMessage ?? ''), style: const TextStyle(height: 1.4)))]),
          ),
          const SizedBox(height: 12),
          ..._results!.take(5).toList().asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _resultCard(entry.value, entry.key == 0, () => widget.onChooseCrop(entry.value.crop.name)),
          )),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: widget.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: widget.border)),
            child: Text(uiText('Catatan: skor adalah indikator demo dari aturan dan bobot yang ditanam dalam kode, bukan prediksi hasil panen. Data NPK, curah hujan, suhu, kedalaman tanah, varietas, dan lokasi belum dianalisis.'), style: TextStyle(color: widget.muted, fontSize: 11, height: 1.5)),
          ),
        ],
      ],
    );
  }

  Widget _dropdown<T>({required String label, required IconData icon, required T? value, required List<T> values, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, hintText: uiText('Pilih $label'), prefixIcon: Icon(icon)),
      hint: Text(uiText('Pilih $label')),
      items: values.map((item) => DropdownMenuItem<T>(value: item, child: Text(uiText(item.toString())))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _resultCard(CropMatch match, bool best, VoidCallback onChoose) {
    final color = match.score >= 85 ? const Color(0xFF22C55E) : match.score >= 70 ? const Color(0xFF3B82F6) : match.score >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: best ? color.withOpacity(0.8) : widget.border, width: best ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(15)), child: Text(match.crop.icon, style: const TextStyle(fontSize: 27))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(match.crop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), if (best) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(uiText('TERATAS'), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9)))]), const SizedBox(height: 3), Text(uiText(match.crop.subtitle), style: TextStyle(color: widget.muted, fontSize: 11)), Text(uiText(match.grade), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))])),
            const SizedBox(width: 8),
            Text('${match.score}%', style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 13),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: match.score / 100, minHeight: 7, backgroundColor: widget.border, color: color)),
          const SizedBox(height: 12),
          Text(uiText(match.crop.description), style: const TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          if (match.matches.isNotEmpty) ...[
            Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF22C55E)), const SizedBox(width: 6), Text(uiText('Faktor pendukung'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]),
            const SizedBox(height: 6),
            ...match.matches.take(3).map((item) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText('•  ')), Expanded(child: Text(uiText(item), style: TextStyle(color: widget.muted, fontSize: 11, height: 1.4)))]))),
          ],
          if (match.cautions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)), const SizedBox(width: 6), Text(uiText('Perlu diperhatikan'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))]),
            const SizedBox(height: 6),
            ...match.cautions.take(3).map((item) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText('•  ')), Expanded(child: Text(uiText(item), style: TextStyle(color: widget.muted, fontSize: 11, height: 1.4)))]))),
          ],
          const SizedBox(height: 9),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: Text(uiText('${uiText('Saran:')} ${uiText(match.crop.tips)}'), style: TextStyle(color: widget.muted, fontSize: 11, height: 1.45))),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onChoose, icon: const Icon(Icons.check_circle_outline_rounded), label: Text(uiText('Pilih tanaman untuk lahan')))),
        ],
      ),
    );
  }
}

