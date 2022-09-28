import 'package:fl_assets_picker/fl_assets_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(const ExtendedWidgetsApp(home: _HomePage()));
}

const url =
    'https://www.baidu.com/link?url=n9n-pQJwIQHrF2a7plaZcBZoBWnTzeKtDulF3wD4D_YyY4old-FkWpif7X4zEEGjOGva64S50RbclsR2F0cL8kj93L6zP42qwfxb-iWDXZfpht7SmweX0sZQJCqGjbp_lrDlAlmgMgF1p8v0TA7rQmCM-_CzmsKCJz77ytOZz3fSL2hBx2e067PGZUyXG3DJtxusmgwsHJW_IHNwd5NdkEWfx6jngoMtME86eeGo5VubN6DOjxYcNR-rRohxjM7kvMMC87mDO5lZrhWA3Juncluxvs7idmFam1uylhJIQUF6plJIMVtvlGmBVgsicIuSZh4w24qBA11XWWyB2OBTYnifQ42TQwPZM-QD4yAd4MgPv5iGmKT-0_PaGZq1NtQtylu6JbFJiZr2ikvZXgLbP2RVQITDTekXxtkvJqol6v8TLbnY2HAGUxCaEuCCNrzIa8ZbTcdy3EBjSmQj6FvYF31dogCmJMPvYi9w0UVdNPb3lakXZ-YwOTM1l8H12pe2uvc76mdiIyr5OXgFtDH1rKaynfXJKeZvLy9SbrsZ7Nb7J3gMTjlBxdGF_HL-xECZUjBt6po_RexaUJjkdACXRzT8tbQ7yY_uX3a42nrlgl1eIN_ae4PG2X2Kkj6ynOZ0LJ4lJutTjBS0KBws1VqADDKj3FnqqoCFqLdin8-rd42OmsEgeVaWrtSFCCLKJOf4&wd=&eqid=81455e940019f44a000000066333b67b';

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Assets Picker')),
        padding: const EdgeInsets.all(12),
        children: [
          const Text('单资源选择').marginAll(12),
          SingleAssetPicker(
              initialData: SingleAssetPicker.convertUrl(url),
              config: const PickerAssetEntryBuilderConfig(
                  radius: 6, pickerIcon: Icon(Icons.account_circle_rounded)),
              onChanged: (ExtendedAssetEntity value) {
                log('onChanged ${value.realValueStr}');
              }),
          const Text('多资源选择').marginAll(12),
          MultiAssetPicker(
              entryConfig: const PickerAssetEntryBuilderConfig(radius: 6),
              onChanged: (List<ExtendedAssetEntity> value) {
                log('onChanged ${value.builder((item) => item.realValueStr)}');
              }),
        ]);
  }
}
