import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'features/reader/maps/bible_map_data.dart';

void main() {
  // The reader's Cormorant fonts are bundled under assets/google_fonts, so we
  // load them from assets only — never over the network. This removes the
  // brief sans-serif "flash" on first paint and makes the reader work offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  // Warm the tiny Bible-atlas index at launch so the interlinear "View on map"
  // chip is ready on the very first tap.
  BibleGeo.ensureLoaded();
  runApp(const ProviderScope(child: MyApp()));
}
