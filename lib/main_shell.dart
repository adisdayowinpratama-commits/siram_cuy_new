part of 'main.dart';

class MainShell extends StatefulWidget {
  final bool darkMode;
  final bool english;
  final VoidCallback onToggleLanguage;
  final VoidCallback onToggleTheme;

  const MainShell({
    super.key,
    required this.darkMode,
    required this.english,
    required this.onToggleLanguage,
    required this.onToggleTheme,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  Database? _database;
  bool _loadingState = true;
  bool _restoringState = false;
  Future<void> _saveQueue = Future<void>.value();
  final List<AnalysisRecord> _history = [];
  final List<LandRecord> _lands = [];
  final List<IrrigationLog> _irrigationLogs = [];
  AnalysisRecord? _latest;
  final List<IrrigationPlan> _plans = [];

  String _irrigationLand = '';
  String _irrigationMoisture = 'Kering';
  String _scheduleLand = '';
  String _historyFilterLand = 'Semua lahan';
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _irrigationNoteController = TextEditingController();
  final TextEditingController _scheduleNoteController = TextEditingController();

  Color get _panel => widget.darkMode ? const Color(0xFF151D33) : Colors.white;
  Color get _muted => widget.darkMode ? const Color(0xFF9AA8C7) : const Color(0xFF667085);
  Color get _border => widget.darkMode ? const Color(0xFF303B5A) : const Color(0xFFE4E7F0);

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbPath = p.join(await getDatabasesPath(), 'siramcuy.db');
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE app_state (id INTEGER PRIMARY KEY, payload TEXT NOT NULL, updated_at TEXT NOT NULL)');
        },
      );
      final rows = await _database!.query('app_state', where: 'id = ?', whereArgs: [1], limit: 1);
      if (rows.isNotEmpty) {
        final data = jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
        _restoringState = true;
        _lands
          ..clear()
          ..addAll((data['lands'] as List? ?? []).map((e) => _landFromJson(Map<String, dynamic>.from(e))));
        _history
          ..clear()
          ..addAll((data['history'] as List? ?? []).map((e) => _analysisFromJson(Map<String, dynamic>.from(e))));
        _irrigationLogs
          ..clear()
          ..addAll((data['logs'] as List? ?? []).map((e) => _logFromJson(Map<String, dynamic>.from(e))));
        _latest = data['latest'] == null ? (_history.isEmpty ? null : _history.first) : _analysisFromJson(Map<String, dynamic>.from(data['latest']));
        _plans
          ..clear()
          ..addAll(((data['plans'] as List?) ?? (data['plan'] == null ? [] : [data['plan']])).map((e) => _planFromJson(Map<String, dynamic>.from(e))));
        _irrigationLand = data['irrigationLand'] as String? ?? '';
        _scheduleLand = data['scheduleLand'] as String? ?? '';
        _historyFilterLand = data['historyFilterLand'] as String? ?? 'Semua lahan';
        _irrigationMoisture = data['irrigationMoisture'] as String? ?? 'Kering';
        _scheduledDate = data['scheduledDate'] == null ? null : DateTime.tryParse(data['scheduledDate'] as String);
        _restoringState = false;
      }
    } catch (e) {
      debugPrint('SiramCuy database load error: $e');
    } finally {
      _loadingState = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (!_loadingState && !_restoringState) _queuePersist();
  }

  void _queuePersist() {
    _saveQueue = _saveQueue.then((_) async {
      final db = _database;
      if (db == null || _loadingState || _restoringState) return;
      final payload = jsonEncode({
        'lands': _lands.map(_landToJson).toList(),
        'history': _history.map(_analysisToJson).toList(),
        'latest': _latest == null ? null : _analysisToJson(_latest!),
        'logs': _irrigationLogs.map(_logToJson).toList(),
        'plans': _plans.map(_planToJson).toList(),
        'irrigationLand': _irrigationLand,
        'scheduleLand': _scheduleLand,
        'historyFilterLand': _historyFilterLand,
        'irrigationMoisture': _irrigationMoisture,
        'scheduledDate': _scheduledDate?.toIso8601String(),
      });
      await db.insert('app_state', {'id': 1, 'payload': payload, 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    }).catchError((Object e) => debugPrint('SiramCuy database save error: $e'));
  }

  Map<String, dynamic> _landToJson(LandRecord x) => {'name': x.name, 'location': x.location, 'areaSqm': x.areaSqm, 'notes': x.notes, 'ph': x.ph, 'texture': x.texture, 'moisture': x.moisture, 'fertility': x.fertility, 'drainage': x.drainage, 'sunlight': x.sunlight, 'crop': x.crop, 'updatedAt': x.updatedAt.toIso8601String()};
  LandRecord _landFromJson(Map<String, dynamic> x) => LandRecord(name: x['name'] as String? ?? 'Lahan', location: x['location'] as String? ?? '', areaSqm: (x['areaSqm'] as num?)?.toDouble(), notes: x['notes'] as String? ?? '', ph: (x['ph'] as num?)?.toDouble(), texture: x['texture'] as String? ?? 'Belum dicatat', moisture: x['moisture'] as String? ?? 'Belum dicatat', fertility: x['fertility'] as String? ?? 'Belum dicatat', drainage: x['drainage'] as String? ?? 'Belum dicatat', sunlight: x['sunlight'] as String? ?? 'Belum dicatat', crop: x['crop'] as String?, updatedAt: DateTime.tryParse(x['updatedAt'] as String? ?? '') ?? DateTime.now());
  Map<String, dynamic> _analysisToJson(AnalysisRecord x) => {'createdAt': x.createdAt.toIso8601String(), 'landName': x.landName, 'ph': x.ph, 'texture': x.texture, 'moisture': x.moisture, 'fertility': x.fertility, 'drainage': x.drainage, 'sunlight': x.sunlight, 'results': x.results.map((r) => {'crop': r.crop.name, 'score': r.score, 'matches': r.matches, 'cautions': r.cautions}).toList()};
  AnalysisRecord _analysisFromJson(Map<String, dynamic> x) => AnalysisRecord(createdAt: DateTime.tryParse(x['createdAt'] as String? ?? '') ?? DateTime.now(), landName: x['landName'] as String? ?? '', ph: (x['ph'] as num?)?.toDouble() ?? 7, texture: x['texture'] as String? ?? 'Lempung', moisture: x['moisture'] as String? ?? 'Sedang', fertility: x['fertility'] as String? ?? 'Sedang', drainage: x['drainage'] as String? ?? 'Baik', sunlight: x['sunlight'] as String? ?? 'Matahari penuh', results: ((x['results'] as List?) ?? []).map((r) { final m = Map<String, dynamic>.from(r); final crop = cropProfiles.firstWhere((c) => c.name == m['crop'], orElse: () => cropProfiles.first); return CropMatch(crop: crop, score: (m['score'] as num?)?.toInt() ?? 0, matches: List<String>.from(m['matches'] ?? []), cautions: List<String>.from(m['cautions'] ?? [])); }).toList());
  Map<String, dynamic> _logToJson(IrrigationLog x) => {'date': x.date.toIso8601String(), 'landName': x.landName, 'crop': x.crop, 'moistureBefore': x.moistureBefore, 'amountLiters': x.amountLiters, 'note': x.note};
  IrrigationLog _logFromJson(Map<String, dynamic> x) => IrrigationLog(date: DateTime.tryParse(x['date'] as String? ?? '') ?? DateTime.now(), landName: x['landName'] as String? ?? '', crop: x['crop'] as String? ?? 'Belum dipilih', moistureBefore: x['moistureBefore'] as String? ?? 'Tidak dicatat', amountLiters: (x['amountLiters'] as num?)?.toDouble(), note: x['note'] as String? ?? '');
  Map<String, dynamic> _planToJson(IrrigationPlan x) => {'landName': x.landName, 'date': x.date.toIso8601String(), 'note': x.note, 'completed': x.completed};
  IrrigationPlan _planFromJson(Map<String, dynamic> x) => IrrigationPlan(landName: x['landName'] as String? ?? '', date: DateTime.tryParse(x['date'] as String? ?? '') ?? DateTime.now(), note: x['note'] as String? ?? '', completed: x['completed'] as bool? ?? false);

  @override
  void dispose() {
    _amountController.dispose();
    _irrigationNoteController.dispose();
    _scheduleNoteController.dispose();
    _database?.close();
    super.dispose();
  }

  void _switchTab(int index) => setState(() => _tab = index);

  void _saveRecord(AnalysisRecord record) {
    final name = record.landName.trim().isEmpty
        ? 'Lahan ${_lands.length + 1}'
        : record.landName.trim();
    LandRecord? land;
    for (final item in _lands) {
      if (item.name.toLowerCase() == name.toLowerCase()) {
        land = item;
        break;
      }
    }
    setState(() {
      _latest = record;
      _history.insert(0, record);
      if (land == null) {
        land = LandRecord(name: name);
        _lands.add(land!);
      }
      land!
        ..ph = record.ph
        ..texture = record.texture
        ..moisture = record.moisture
        ..fertility = record.fertility
        ..drainage = record.drainage
        ..sunlight = record.sunlight
        ..updatedAt = record.createdAt;
      if (record.results.isNotEmpty) {
        land!.crop ??= record.results.first.crop.name;
      }
      _irrigationLand = _lands.any((item) => item.name == _irrigationLand)
          ? _irrigationLand
          : name;
      _scheduleLand = _lands.any((item) => item.name == _scheduleLand)
          ? _scheduleLand
          : name;
    });
  }

  void _chooseCropForLatest(String cropName) {
    final record = _latest;
    if (record == null) return;
    final name = record.landName.trim();
    setState(() {
      for (final land in _lands) {
        if (land.name.toLowerCase() == name.toLowerCase()) {
          land.crop = cropName;
          land.updatedAt = DateTime.now();
          break;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uiText('$cropName dipilih untuk lahan ${name.isEmpty ? 'tersebut' : name}.'))),
    );
  }

  Future<void> _showAddLandDialog() async => _showLandFormDialog();

  Future<void> _showLandFormDialog({LandRecord? land}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: land?.name ?? '');
    final locationController = TextEditingController(text: land?.location ?? '');
    final areaController = TextEditingController(text: land?.areaSqm?.toString() ?? '');
    final notesController = TextEditingController(text: land?.notes ?? '');
    final phController = TextEditingController(text: land?.ph?.toString() ?? '');
    String texture = land?.texture ?? 'Lempung';
    String moisture = land?.moisture ?? 'Sedang';
    String fertility = land?.fertility ?? 'Sedang';
    String drainage = land?.drainage ?? 'Baik';
    String sunlight = land?.sunlight ?? 'Matahari penuh';
    String? crop = land?.crop;
    final result = await showDialog<LandRecord>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(uiText(land == null ? 'Tambah lahan' : 'Edit lahan')),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: uiText('Nama lahan *'), prefixIcon: Icon(Icons.grass_outlined), hintText: uiText('Contoh: Kebun belakang')),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Nama lahan wajib diisi.';
                      final duplicate = _lands.any((item) => item.name.toLowerCase() == name.toLowerCase() && !identical(item, land));
                      if (duplicate) return 'Nama lahan sudah digunakan.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: locationController, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: uiText('Lokasi / alamat lahan'), prefixIcon: Icon(Icons.location_on_outlined), hintText: uiText('Contoh: Desa Sukamaju'))),
                  const SizedBox(height: 10),
                  TextFormField(controller: areaController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: uiText('Luas lahan (m²)'), prefixIcon: Icon(Icons.square_foot_outlined), hintText: uiText('Contoh: 250')), validator: (value) { final raw = value?.trim() ?? ''; if (raw.isEmpty) return null; final normalized = raw.replaceAll(',', '.'); final parsed = double.tryParse(normalized); if (parsed == null || parsed <= 0) return uiText('Luas harus berupa angka lebih dari 0.'); return null; }),
                  const SizedBox(height: 10),
                  TextFormField(controller: phController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: uiText('pH tanah (0–14)'), prefixIcon: Icon(Icons.science_outlined), hintText: uiText('Contoh: 6.5')), validator: (value) { final raw = value?.trim() ?? ''; if (raw.isEmpty) return null; final parsed = double.tryParse(raw.replaceAll(',', '.')); if (parsed == null || parsed < 0 || parsed > 14) return uiText('pH harus berupa angka dari 0 sampai 14.'); return null; }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: texture, isExpanded: true, decoration: InputDecoration(labelText: uiText('Tekstur tanah')), items: const ['Pasir', 'Lempung berpasir', 'Lempung', 'Liat', 'Belum dicatat'].map((v) => DropdownMenuItem(value: v, child: Text(uiText(v)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => texture = v); }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: moisture, isExpanded: true, decoration: InputDecoration(labelText: uiText('Kelembapan')), items: const ['Kering', 'Sedang', 'Basah', 'Belum dicatat'].map((v) => DropdownMenuItem(value: v, child: Text(uiText(v)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => moisture = v); }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: fertility, isExpanded: true, decoration: InputDecoration(labelText: uiText('Kesuburan')), items: const ['Rendah', 'Sedang', 'Tinggi', 'Belum dicatat'].map((v) => DropdownMenuItem(value: v, child: Text(uiText(v)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => fertility = v); }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: drainage, isExpanded: true, decoration: InputDecoration(labelText: uiText('Drainase')), items: const ['Buruk', 'Sedang', 'Baik', 'Belum dicatat'].map((v) => DropdownMenuItem(value: v, child: Text(uiText(v)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => drainage = v); }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: sunlight, isExpanded: true, decoration: InputDecoration(labelText: uiText('Paparan matahari')), items: const ['Matahari penuh', 'Matahari sebagian', 'Teduh', 'Belum dicatat'].map((v) => DropdownMenuItem(value: v, child: Text(uiText(v)))).toList(), onChanged: (v) { if (v != null) setDialogState(() => sunlight = v); }),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(value: crop, isExpanded: true, decoration: InputDecoration(labelText: uiText('Tanaman (opsional)')), items: [DropdownMenuItem<String?>(value: null, child: Text(uiText('Belum dipilih'))), ...cropProfiles.map((item) => DropdownMenuItem<String?>(value: item.name, child: Text(item.name)))], onChanged: (v) => setDialogState(() => crop = v)),
                  const SizedBox(height: 10),
                  TextFormField(controller: notesController, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: uiText('Catatan (opsional)'), alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_outlined), hintText: uiText('Catatan kondisi atau perawatan lahan'))),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(widget.english ? 'Cancel' : 'Batal')),
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final areaText = areaController.text.trim().replaceAll(',', '.');
                final phText = phController.text.trim().replaceAll(',', '.');
                final record = LandRecord(
                  name: name,
                  location: locationController.text.trim(),
                  areaSqm: areaText.isEmpty ? null : double.parse(areaText),
                  notes: notesController.text.trim(),
                  ph: phText.isEmpty ? null : double.parse(phText),
                  texture: texture,
                  moisture: moisture,
                  fertility: fertility,
                  drainage: drainage,
                  sunlight: sunlight,
                  crop: crop,
                  updatedAt: DateTime.now(),
                );
                Navigator.pop(dialogContext, record);
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(uiText(land == null ? 'Simpan lahan' : 'Simpan perubahan')),
            ),
          ],
        ),
      ),
    );
    nameController.dispose(); locationController.dispose(); areaController.dispose(); notesController.dispose(); phController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      if (land == null) {
        _lands.add(result);
        _irrigationLand = result.name;
        _scheduleLand = result.name;
      } else {
        final oldName = land.name;
        final index = _lands.indexOf(land);
        if (index >= 0) _lands[index] = result;
        for (final record in _history) {
          if (record.landName.toLowerCase() == oldName.toLowerCase()) record.landName = result.name;
        }
        for (var i = 0; i < _irrigationLogs.length; i++) {
          final old = _irrigationLogs[i];
          if (old.landName.toLowerCase() == oldName.toLowerCase()) {
            _irrigationLogs[i] = IrrigationLog(date: old.date, landName: result.name, crop: old.crop, moistureBefore: old.moistureBefore, amountLiters: old.amountLiters, note: old.note);
          }
        }
        for (final plan in _plans) { if (plan.landName.toLowerCase() == oldName.toLowerCase()) plan.landName = result.name; }
        if (_irrigationLand == oldName) _irrigationLand = result.name;
        if (_scheduleLand == oldName) _scheduleLand = result.name;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uiText(land == null ? 'Lahan berhasil ditambahkan.' : 'Data lahan berhasil diperbarui.'))));
  }

  void _removeLand(LandRecord land) {
    setState(() {
      _lands.remove(land);
      if (_irrigationLand == land.name) {
        _irrigationLand = _lands.isEmpty ? '' : _lands.first.name;
      }
      if (_scheduleLand == land.name) {
        _scheduleLand = _lands.isEmpty ? '' : _lands.first.name;
      }
      _plans.removeWhere((plan) => plan.landName == land.name);
    });
  }

  Future<void> _chooseScheduleDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: 'Pilih tanggal irigasi',
    );
    if (selected != null && mounted) setState(() => _scheduledDate = selected);
  }

  Future<void> _chooseScheduleTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: widget.english ? 'Choose irrigation time' : 'Pilih jam irigasi',
    );
    if (selected != null && mounted) setState(() => _scheduledTime = selected);
  }

  String _timeLabel(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _savePlan() {
    if (_lands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText('Tambahkan lahan terlebih dahulu.'))),
      );
      return;
    }
    if (_scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText('Pilih tanggal rencana irigasi.'))),
      );
      return;
    }
    if (_scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.english ? 'Choose the irrigation time.' : 'Pilih jam rencana irigasi.')),
      );
      return;
    }
    final landName = _lands.any((land) => land.name == _scheduleLand)
        ? _scheduleLand
        : _lands.first.name;
    final dateTime = DateTime(_scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day, _scheduledTime!.hour, _scheduledTime!.minute);
    setState(() {
      _plans.add(IrrigationPlan(
        landName: landName,
        date: dateTime,
        note: _scheduleNoteController.text.trim(),
      ));
      _plans.sort((a, b) => a.date.compareTo(b.date));
      _scheduledDate = null;
      _scheduledTime = null;
      _scheduleNoteController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uiText('Rencana irigasi disimpan di aplikasi.'))),
    );
  }

  void _saveIrrigationLog() {
    if (_lands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText('Tambahkan lahan terlebih dahulu.'))),
      );
      return;
    }
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = amountText.isEmpty ? null : double.tryParse(amountText);
    if (amountText.isNotEmpty && (amount == null || amount < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uiText('Jumlah air harus berupa angka positif.'))),
      );
      return;
    }
    final land = _lands.firstWhere(
      (item) => item.name == _irrigationLand,
      orElse: () => _lands.first,
    );
    setState(() {
      _irrigationLogs.insert(
        0,
        IrrigationLog(
          date: DateTime.now(),
          landName: land.name,
          crop: land.crop ?? 'Belum dipilih',
          moistureBefore: _irrigationMoisture,
          amountLiters: amount,
          note: _irrigationNoteController.text.trim(),
        ),
      );
      land.moisture = 'Dicatat setelah irigasi';
      land.updatedAt = DateTime.now();
      _amountController.clear();
      _irrigationNoteController.clear();
      // Catatan penyiraman tidak otomatis menyelesaikan semua rencana lahan; pengguna menandai rencana secara spesifik.
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uiText('Catatan irigasi berhasil ditambahkan.'))),
    );
  }

  void _completePlan(IrrigationPlan plan) {
    if (plan.completed) return;
    final land = _lands.where((item) => item.name == plan.landName).toList();
    setState(() {
      plan.completed = true;
      _irrigationLogs.insert(
        0,
        IrrigationLog(
          date: DateTime.now(),
          landName: plan.landName,
          crop: land.isEmpty ? 'Belum dipilih' : (land.first.crop ?? 'Belum dipilih'),
          moistureBefore: 'Tidak dicatat',
          amountLiters: null,
          note: plan.note.isEmpty ? 'Rencana irigasi ditandai selesai.' : plan.note,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      AnalysisPage(
        key: const ValueKey('soil-analysis'),
        panel: _panel,
        muted: _muted,
        border: _border,
        onAnalyze: _saveRecord,
        onChooseCrop: _chooseCropForLatest,
        latest: _latest,
        lands: _lands,
      ),
      _buildLands(),
      _buildIrrigation(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              height: 39,
              width: 39,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF15803D), Color(0xFF22C55E)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.water_drop_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uiText('SiramCuy'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                Text(widget.english ? 'SOIL • CROPS • IRRIGATION' : 'TANAH • TANAMAN • IRIGASI', style: TextStyle(fontSize: 9, letterSpacing: 1.0)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.darkMode ? 'Aktifkan light mode' : 'Aktifkan dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _switchTab,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: widget.english ? 'Home' : 'Beranda'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: widget.english ? 'Crop Match' : 'TanamCocok'),
          NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass_rounded), label: widget.english ? 'Land' : 'Lahan'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop_rounded), label: widget.english ? 'Irrigation' : 'Irigasi'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: widget.english ? 'Profile' : 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final recent = _history.take(2).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF0F766E)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(30)),
                child: Text(uiText('ASISTEN PENGELOLAAN LAHAN'), style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 17),
              Text(uiText('Tanah cocok, tanaman tepat, perawatan terpantau.'), style: TextStyle(color: Colors.white, fontSize: 28, height: 1.1, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(uiText('Analisis kondisi tanah, temukan pilihan tanaman, lalu catat kegiatan irigasi dalam satu aplikasi.'), style: TextStyle(color: Colors.white.withOpacity(0.88), height: 1.45, fontSize: 13)),
              const SizedBox(height: 20),
              Wrap(spacing: 9, runSpacing: 9, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF14532D), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                  onPressed: () => _switchTab(1),
                  icon: const Icon(Icons.science_outlined),
                  label: Text(uiText('Analisis tanah'), style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.65)), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13)),
                  onPressed: () => _switchTab(3),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: Text(uiText('Catat irigasi')),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _statCard(icon: Icons.grass_rounded, label: 'Lahan', value: '${_lands.length}', color: const Color(0xFF22C55E)),
            _statCard(icon: Icons.analytics_outlined, label: 'Analisis', value: '${_history.length}', color: const Color(0xFF8B5CF6)),
            _statCard(icon: Icons.water_drop_outlined, label: 'Catatan irigasi', value: '${_irrigationLogs.length}', color: const Color(0xFF0EA5E9)),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Semua kebutuhan dalam satu tempat', subtitle: 'Pilih fitur yang ingin kamu gunakan'),
        const SizedBox(height: 12),
        _shortcut(Icons.auto_awesome_rounded, const Color(0xFF8B5CF6), 'TanamCocok', 'Cari tanaman berdasarkan kondisi tanah.', () => _switchTab(1)),
        const SizedBox(height: 9),
        _shortcut(Icons.grass_rounded, const Color(0xFF22C55E), 'Manajemen lahan', 'Simpan nama lahan dan data yang sudah dianalisis.', () => _switchTab(2)),
        const SizedBox(height: 9),
        _shortcut(Icons.water_drop_rounded, const Color(0xFF0EA5E9), 'Irigasi dan pengingat', 'Buat rencana tanggal dan catat penyiraman secara manual.', () => _switchTab(3)),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Rencana irigasi', subtitle: 'Rencana yang kamu simpan di aplikasi'),
        const SizedBox(height: 12),
        if (_plans.where((plan) => !plan.completed).isEmpty)
          _emptyInline(Icons.calendar_month_outlined, 'Belum ada rencana aktif', 'Atur tanggal irigasi di menu Irigasi.', () => _switchTab(3))
        else
          ...(_plans.where((plan) => !plan.completed).take(3).map((plan) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _planCard(plan, compact: true)))),
        const SizedBox(height: 24),
        const SectionHeading(title: 'Aktivitas terbaru', subtitle: 'Analisis kondisi tanah terakhir'),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          _emptyInline(Icons.science_outlined, 'Belum ada analisis', 'Mulai dengan mengisi data kondisi tanah.', () => _switchTab(1))
        else
          ...recent.map((record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
              child: Row(children: [
                Container(width: 45, height: 45, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.12), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.eco_rounded, color: Color(0xFF22C55E))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(record.landName.isEmpty ? uiText('Analisis lahan') : record.landName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(uiText('pH ${record.ph.toStringAsFixed(1)} • ${record.texture} • ${_dateLabel(record.createdAt)}'), style: TextStyle(color: _muted, fontSize: 11)),
                  if (record.results.isNotEmpty) Text(uiText('Rekomendasi teratas: ${record.results.first.crop.name} (${record.results.first.score}%)'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
          )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(uiText('SiramCuy memakai input manual, tanpa sensor IoT. Data aplikasi hanya tersimpan selama sesi berjalan pada versi prototipe ini. Jadwal irigasi belum memunculkan notifikasi latar belakang.'), style: TextStyle(color: _muted, fontSize: 11, height: 1.45))),
          ]),
        ),
      ],
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color color}) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 46) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
        child: Row(children: [
          Container(height: 39, width: 39, decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)), Text(uiText(label), style: TextStyle(color: _muted, fontSize: 11))])),
        ]),
      ),
    );
  }

  Widget _shortcut(IconData icon, Color color, String title, String description, VoidCallback onTap) {
    return Material(
      color: _panel,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: _border)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText(title), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(uiText(description), style: TextStyle(color: _muted, fontSize: 11, height: 1.35))])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }

  Widget _emptyInline(IconData icon, String title, String message, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
      child: Column(children: [
        Icon(icon, size: 30, color: _muted),
        const SizedBox(height: 8),
        Text(uiText(title), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(uiText(message), textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 10),
        TextButton(onPressed: onPressed, child: Text(uiText('Buka fitur'))),
      ]),
    );
  }

  Widget _buildLands() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(child: SectionHeading(title: 'Lahan saya', subtitle: 'Kelola beberapa lahan dalam satu aplikasi')),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: _showAddLandDialog, icon: const Icon(Icons.add), label: Text(uiText('Tambah'))),
        ]),
        const SizedBox(height: 16),
        if (_lands.isEmpty)
          _emptyInline(Icons.grass_outlined, 'Belum ada lahan', 'Tambahkan nama lahan atau lakukan analisis TanamCocok terlebih dahulu.', _showAddLandDialog)
        else
          ..._lands.map((land) {
            final records = _history.where((record) => record.landName.toLowerCase() == land.name.toLowerCase()).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.terrain_rounded, color: Color(0xFF22C55E))),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(land.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text(uiText(land.crop == null ? 'Tanaman belum dipilih' : 'Tanaman: ${land.crop}'), style: TextStyle(color: _muted, fontSize: 12)), if (land.location.isNotEmpty) Text(land.location, style: TextStyle(color: _muted, fontSize: 11))])),
                    PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _showLandFormDialog(land: land); if (value == 'delete') _confirmRemoveLand(land); if (value == 'details') _showLandDetails(land); }, itemBuilder: (_) => [PopupMenuItem(value: 'details', child: Text(uiText('Lihat detail'))), PopupMenuItem(value: 'edit', child: Text(uiText('Edit lahan'))), PopupMenuItem(value: 'delete', child: Text(uiText('Hapus lahan')))]),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _smallTag('pH: ${land.ph?.toStringAsFixed(1) ?? '—'}'),
                    _smallTag('Tekstur: ${land.texture}'),
                    _smallTag('Kelembapan: ${land.moisture}'),
                    if (land.areaSqm != null) _smallTag('Luas: ${land.areaSqm!.toStringAsFixed(land.areaSqm! % 1 == 0 ? 0 : 1)} m²'),
                  ]),
                  const SizedBox(height: 11),
                  Text(uiText('Kesuburan ${land.fertility} • Drainase ${land.drainage}'), style: TextStyle(color: _muted, fontSize: 11)),
                  Text(uiText('Kesuburan ${land.fertility} • Drainase ${land.drainage} • Matahari ${land.sunlight}'), style: TextStyle(color: _muted, fontSize: 11)),
                  if (land.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text(land.notes, style: TextStyle(color: _muted, fontSize: 12))),
                  Text(uiText('Diperbarui: ${_dateLabel(land.updatedAt)}'), style: TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _switchTab(1), icon: const Icon(Icons.science_outlined), label: Text(uiText('Analisis tanah')))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _irrigationLand = land.name; }); _switchTab(3); }, icon: const Icon(Icons.water_drop_outlined), label: Text(uiText('Catat irigasi')))),
                  ]),
                  if (records.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(uiText('${records.length} riwayat analisis • terakhir ${_dateLabel(records.first.createdAt)}'), style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                ]),
              ),
            );
          }),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)), child: Text(uiText('Data lahan dan riwayat utama disimpan secara lokal menggunakan SQLite pada perangkat ini. Gunakan nama lahan yang sama saat melakukan analisis agar hasilnya ditautkan ke lahan yang sama.'), style: TextStyle(color: _muted, fontSize: 11, height: 1.45))),
      ],
    );
  }

  Future<void> _showLandDetails(LandRecord land) async {
    final analyses = _history.where((record) => record.landName.toLowerCase() == land.name.toLowerCase()).toList();
    final logs = _irrigationLogs.where((log) => log.landName.toLowerCase() == land.name.toLowerCase()).toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(land.name),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          _detailLine('Lokasi', land.location.isEmpty ? 'Belum dicatat' : land.location),
          _detailLine('Luas', land.areaSqm == null ? 'Belum dicatat' : '${land.areaSqm!.toStringAsFixed(land.areaSqm! % 1 == 0 ? 0 : 1)} m²'),
          _detailLine('pH tanah', land.ph?.toStringAsFixed(1) ?? 'Belum dicatat'),
          _detailLine('Tekstur', land.texture), _detailLine('Kelembapan', land.moisture),
          _detailLine('Kesuburan', land.fertility), _detailLine('Drainase', land.drainage),
          _detailLine('Paparan matahari', land.sunlight), _detailLine('Tanaman', land.crop ?? 'Belum dipilih'),
          _detailLine('Riwayat analisis', '${analyses.length} kali'), _detailLine('Catatan irigasi', '${logs.length} kali'),
          if (land.notes.isNotEmpty) _detailLine('Catatan', land.notes),
          _detailLine('Terakhir diperbarui', _dateLabel(land.updatedAt)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(uiText('Tutup'))), FilledButton.icon(onPressed: () { Navigator.pop(dialogContext); _showLandFormDialog(land: land); }, icon: const Icon(Icons.edit_outlined), label: Text(uiText('Edit')))],
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 135, child: Text(uiText(label), style: TextStyle(color: _muted, fontSize: 12))), Expanded(child: Text(uiText(value), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))) ]));

  Future<void> _confirmRemoveLand(LandRecord land) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(uiText('Hapus lahan?')),
        content: Text(uiText('Lahan "${land.name}" akan dihapus dari daftar. Riwayat analisis yang sudah dibuat tidak ikut dihapus.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(uiText('Batal'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(uiText('Hapus'))),
        ],
      ),
    );
    if (confirm == true) _removeLand(land);
  }

  Widget _smallTag(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Text(uiText(text), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)));
  }

  Widget _buildIrrigation() {
    final selectedName = _lands.any((land) => land.name == _irrigationLand) ? _irrigationLand : (_lands.isEmpty ? '' : _lands.first.name);
    final currentLand = _lands.where((land) => land.name == selectedName).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        const SectionHeading(title: 'Irigasi manual', subtitle: 'Catat penyiraman dan buat rencana tanggal berikutnya'),
        const SizedBox(height: 15),
        if (_lands.isEmpty) ...[
          _emptyInline(Icons.grass_outlined, 'Tambahkan lahan terlebih dahulu', 'Catatan irigasi perlu terhubung dengan satu lahan.', () => _switchTab(2)),
          const SizedBox(height: 14),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FormSectionTitle(number: '01', title: 'Catat kegiatan irigasi', subtitle: 'Isi setelah penyiraman dilakukan'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedName,
                isExpanded: true,
                decoration: InputDecoration(labelText: uiText('Pilih lahan'), prefixIcon: Icon(Icons.location_on_outlined)),
                items: _lands.map((land) => DropdownMenuItem(value: land.name, child: Text(land.name))).toList(),
                onChanged: (value) => setState(() => _irrigationLand = value ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _irrigationMoisture,
                isExpanded: true,
                decoration: InputDecoration(labelText: uiText('Kelembapan sebelum irigasi'), prefixIcon: Icon(Icons.water_drop_outlined)),
                items: const ['Kering', 'Sedang', 'Basah', 'Tidak diperiksa'].map((value) => DropdownMenuItem(value: value, child: Text(uiText(value)))).toList(),
                onChanged: (value) => setState(() => _irrigationMoisture = value ?? 'Kering'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: uiText('Jumlah air (liter, opsional)'), prefixIcon: Icon(Icons.local_drink_outlined), hintText: uiText('Contoh: 10'))),
              const SizedBox(height: 12),
              TextField(controller: _irrigationNoteController, maxLines: 2, decoration: InputDecoration(labelText: uiText('Catatan (opsional)'), prefixIcon: Icon(Icons.notes_rounded), hintText: uiText('Contoh: menyiram tanaman cabai pagi hari'))),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _saveIrrigationLog, icon: const Icon(Icons.save_outlined), label: Text(uiText('Simpan catatan irigasi')))),
              if (currentLand.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(uiText('Tanaman pada lahan ini: ${currentLand.first.crop ?? 'Belum dipilih melalui TanamCocok'}'), style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ]),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FormSectionTitle(number: '02', title: 'Rencana irigasi', subtitle: 'Simpan tanggal target sebagai pengingat di dalam aplikasi'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _lands.any((land) => land.name == _scheduleLand) ? _scheduleLand : _lands.first.name,
                isExpanded: true,
                decoration: InputDecoration(labelText: uiText('Lahan untuk dijadwalkan'), prefixIcon: Icon(Icons.grass_outlined)),
                items: _lands.map((land) => DropdownMenuItem(value: land.name, child: Text(land.name))).toList(),
                onChanged: (value) => setState(() => _scheduleLand = value ?? ''),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _chooseScheduleDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(_scheduledDate == null ? (widget.english ? 'Choose irrigation date' : 'Pilih tanggal irigasi') : _dateLabel(_scheduledDate!))),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _chooseScheduleTime, icon: const Icon(Icons.access_time_rounded), label: Text(_scheduledTime == null ? (widget.english ? 'Choose irrigation time' : 'Pilih jam irigasi') : (widget.english ? 'Time: ' : 'Jam: ') + _timeLabel(_scheduledTime!))),
              const SizedBox(height: 12),
              TextField(controller: _scheduleNoteController, maxLines: 2, decoration: InputDecoration(labelText: uiText('Catatan rencana (opsional)'), prefixIcon: Icon(Icons.edit_note_rounded), hintText: uiText('Contoh: periksa kelembapan sebelum menyiram'))),
              const SizedBox(height: 13),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _savePlan, icon: const Icon(Icons.event_available_rounded), label: Text(uiText('Simpan rencana')))),
            ]),
          ),
        ],
        if (_plans.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeading(title: 'Daftar jadwal irigasi', subtitle: 'Jadwal dikelompokkan berdasarkan lahan dan tanggal'),
          const SizedBox(height: 10),
          ..._plans.map((plan) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _planCard(plan))),
        ],
        const SizedBox(height: 22),
        const SectionHeading(title: 'Riwayat irigasi', subtitle: 'Catatan kegiatan yang sudah dimasukkan'),
        const SizedBox(height: 10),
        if (_lands.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: _lands.any((land) => land.name == _historyFilterLand) || _historyFilterLand == 'Semua lahan' ? _historyFilterLand : 'Semua lahan',
            isExpanded: true,
            decoration: InputDecoration(labelText: uiText('Filter riwayat berdasarkan lahan'), prefixIcon: Icon(Icons.filter_list_rounded)),
            items: [DropdownMenuItem(value: 'Semua lahan', child: Text(uiText('Semua lahan'))), ..._lands.map((land) => DropdownMenuItem(value: land.name, child: Text(land.name)))],
            onChanged: (value) => setState(() => _historyFilterLand = value ?? 'Semua lahan'),
          ),
          const SizedBox(height: 10),
        ],
        if (_irrigationLogs.where((log) => _historyFilterLand == 'Semua lahan' || log.landName == _historyFilterLand).isEmpty)
          _emptyInline(Icons.history_rounded, 'Belum ada catatan', 'Catatan irigasi untuk filter ini akan muncul setelah disimpan.', () { if (_lands.isEmpty) _switchTab(2); })
        else
          ..._irrigationLogs.where((log) => _historyFilterLand == 'Semua lahan' || log.landName == _historyFilterLand).map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(17), border: Border.all(color: _border)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.13), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0EA5E9))),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(log.landName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(uiText('${_dateLabel(log.date)} • Kelembapan sebelumnya: ${log.moistureBefore}'), style: TextStyle(color: _muted, fontSize: 11)),
                  if (log.amountLiters != null) Text(uiText('Jumlah air: ${log.amountLiters!.toStringAsFixed(log.amountLiters! % 1 == 0 ? 0 : 1)} liter'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (log.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(log.note, style: TextStyle(color: _muted, fontSize: 12))),
                ])),
              ]),
            ),
          )),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: _border)), child: Text(uiText('Jadwal tersimpan di SQLite dan ditampilkan saat aplikasi dibuka. Versi ini belum mengirim notifikasi otomatis Android.'), style: TextStyle(color: _muted, fontSize: 11, height: 1.45))),
      ],
    );
  }

  Widget _planCard(IrrigationPlan plan, {bool compact = false}) {
    final isLate = !plan.completed && DateTime(plan.date.year, plan.date.month, plan.date.day).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    final statusColor = plan.completed ? const Color(0xFF22C55E) : isLate ? const Color(0xFFEF4444) : const Color(0xFF0EA5E9);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: statusColor.withOpacity(0.45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 43, height: 43, alignment: Alignment.center, decoration: BoxDecoration(color: statusColor.withOpacity(0.13), borderRadius: BorderRadius.circular(13)), child: Icon(plan.completed ? Icons.check_circle_rounded : Icons.calendar_month_rounded, color: statusColor)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(plan.landName, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${_dateLabel(plan.date)} • ${_timeLabel(TimeOfDay.fromDateTime(plan.date))}', style: TextStyle(color: _muted, fontSize: 12))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)), child: Text(uiText(plan.completed ? 'Selesai' : isLate ? 'Terlewat' : 'Terjadwal'), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800))),
        ]),
        if (plan.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(plan.note, style: TextStyle(color: _muted, fontSize: 12))),
        if (!compact) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => setState(() => _plans.remove(plan)), icon: const Icon(Icons.delete_outline_rounded, size: 18), label: Text(uiText('Hapus jadwal')))),
        if (!plan.completed && !compact) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _completePlan(plan), icon: const Icon(Icons.check_rounded), label: Text(uiText('Tandai selesai')))),
        ],
        if (compact && !plan.completed) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _switchTab(3), child: Text(uiText('Buka irigasi')))),
      ]),
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        SectionHeading(title: widget.english ? 'Profile & Settings' : 'Profil & pengaturan', subtitle: widget.english ? 'Customize appearance and manage your data' : 'Atur tampilan dan kelola data sesi ini'),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF0F766E)])),
          child: Row(children: [
            const CircleAvatar(radius: 29, backgroundColor: Colors.white24, child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 30)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText('SiramCuy'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(uiText('Kondisi tanah • rekomendasi tanaman • irigasi'), style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3))])),
          ]),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
          child: SwitchListTile.adaptive(
            value: widget.darkMode,
            onChanged: (_) => widget.onToggleTheme(),
            secondary: Icon(widget.darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(widget.english ? 'Dark mode' : 'Mode gelap', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(widget.english ? 'Switch between light and dark appearance' : 'Ubah tampilan terang atau gelap'),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
          child: ListTile(
            leading: Icon(Icons.translate_rounded, color: Theme.of(context).colorScheme.primary),
            title: Text(widget.english ? 'App Language' : 'Bahasa aplikasi', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(widget.english ? 'English' : 'Bahasa Indonesia'),
            trailing: SegmentedButton<bool>(
              segments: [ButtonSegment<bool>(value: false, label: Text('ID')), ButtonSegment<bool>(value: true, label: Text('EN'))],
              selected: {widget.english},
              onSelectionChanged: (values) { if (values.first != widget.english) widget.onToggleLanguage(); },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _infoTile(Icons.phone_android_rounded, widget.english ? 'Platform' : 'Platform', widget.english ? 'Flutter • Android mobile app' : 'Flutter • aplikasi mobile Android'),
        const SizedBox(height: 9),
        _infoTile(Icons.edit_note_rounded, widget.english ? 'Data input' : 'Input data', widget.english ? 'Soil conditions and irrigation activities are entered manually by the user.' : 'Kondisi tanah dan aktivitas irigasi dicatat manual oleh pengguna.'),
        const SizedBox(height: 9),
        _infoTile(Icons.science_outlined, widget.english ? 'Recommendation system' : 'Sistem rekomendasi', widget.english ? 'Crop matching rules are prototype data, not a harvest prediction.' : 'Aturan kecocokan tanaman adalah data awal untuk prototipe, bukan prediksi hasil panen.'),
        const SizedBox(height: 9),
        _infoTile(Icons.storage_outlined, widget.english ? 'Storage' : 'Penyimpanan', widget.english ? 'Data is saved locally using SQLite and remains available after restarting the app.' : 'Data disimpan secara lokal menggunakan SQLite dan tetap tersedia setelah aplikasi dimulai ulang.'),
        const SizedBox(height: 22),
        SectionHeading(title: widget.english ? 'Manage app data' : 'Kelola data prototipe', subtitle: widget.english ? 'This action deletes app data' : 'Tindakan ini menghapus data dari memori aplikasi'),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _history.isEmpty && _irrigationLogs.isEmpty && _lands.isEmpty && _plans.isEmpty ? null : _confirmClearData,
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(widget.english ? 'Delete all app data' : 'Hapus semua data sesi'),
        ),
        const SizedBox(height: 15),
        Text(widget.english ? 'Educational prototype. For real-world use, rely on validated agronomy references and trustworthy soil-test data.' : 'Versi prototipe untuk pembelajaran. Untuk pemakaian nyata, gunakan referensi agronomi yang tervalidasi dan data uji tanah yang dapat dipercaya.', style: TextStyle(color: _muted, fontSize: 11, height: 1.5)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String description) {
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText(title), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(uiText(description), style: TextStyle(color: _muted, fontSize: 12, height: 1.4))]))]));
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.english ? 'Delete all app data?' : 'Hapus semua data sesi?'),
        content: Text(widget.english ? 'All land records, analysis history, irrigation logs, and schedules will be deleted.' : 'Semua lahan, riwayat analisis, catatan irigasi, dan rencana akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(uiText('Batal'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(widget.english ? 'Delete all' : 'Hapus semua')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _history.clear();
        _lands.clear();
        _irrigationLogs.clear();
        _latest = null;
        _plans.clear();
        _irrigationLand = '';
        _scheduleLand = '';
        _scheduledDate = null;
        _scheduledTime = null;
      });
    }
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

