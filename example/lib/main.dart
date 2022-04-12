import 'package:assets_picker/assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(const ExtendedWidgetsApp(home: _HomePage()));
}

class _HomePage extends StatefulWidget {
  const _HomePage({Key? key}) : super(key: key);

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Assets Picker')),
        children: [
          AssetPickerView(
              entryConfig: const PickerAssetEntryBuilderConfig(radius: 6),
              onChanged: (List<AssetEntry> value) {
                log(value.length);
              }),
        ]);
  }
}
