import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(const ExtendedWidgetsApp(home: _HomePage()));
}

class _HomePage extends StatelessWidget {
  const _HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Assets Picker')),
        children: [
          FlAssetPickerView(
              entryConfig: const PickerAssetEntryBuilderConfig(radius: 6),
              onChanged: (List<ExtendedAssetEntity> value) {
                log('onChanged ${value.builder((item) => item.realValueStr)}');
              }),
        ]);
  }
}
