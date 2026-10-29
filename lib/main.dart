import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

part 'localization.dart';
part 'app.dart';
part 'models.dart';
part 'main_shell.dart';
part 'analysis_page.dart';
part 'shared_widgets.dart';

void main() {
  runApp(const SiramCuyApp());
}
