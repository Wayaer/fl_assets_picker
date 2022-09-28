import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(const ExtendedWidgetsApp(home: _HomePage()));
}

const url =
    'https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fitem%2F201612%2F31%2F20161231205134_uVTex.thumb.400_0.jpeg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1666931842&t=44493a6c92d1ddda89367519c6206491';

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Assets Picker')),
        padding: const EdgeInsets.all(12),
        children: [
          const Text('单资源选择').marginAll(12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            SingleAssetPicker(
                errorCallback: (String value) {
                  showToast(value);
                },
                initialData: SingleAssetPicker.convertUrl(url),
                config: PickerAssetEntryBuilderConfig(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.amberAccent),
                onChanged: (ExtendedAssetEntity value) {
                  log('onChanged ${value.realValueStr}');
                }),
            SingleAssetPicker(
                errorCallback: (String value) {
                  showToast(value);
                },
                initialData: SingleAssetPicker.convertUrl(url),
                config: PickerAssetEntryBuilderConfig(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.amberAccent),
                onChanged: (ExtendedAssetEntity value) {
                  log('onChanged ${value.realValueStr}');
                }),
          ]),
          const SizedBox(height: 20),
          const Text('多资源选择').marginAll(12),
          MultiAssetPicker(
              initialData: MultiAssetPicker.convertUrls(url),
              errorCallback: (String value) {
                showToast(value);
              },
              entryConfig: PickerAssetEntryBuilderConfig(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.amberAccent),
              onChanged: (List<ExtendedAssetEntity> value) {
                log('onChanged ${value.builder((item) => item.realValueStr)}');
              }),
        ]);
  }
}
