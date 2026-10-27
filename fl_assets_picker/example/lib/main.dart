import 'package:example/src/home_page.dart';
import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as material_ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlAssetsPicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C6BF5))),
      // fl_video 的 Material 控件基于 material_ui，需要额外提供其本地化
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[material_ui.DefaultMaterialLocalizations.delegate],
      home: const HomePage(),
    );
  }
}
