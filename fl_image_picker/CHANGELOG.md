## 4.0.0

* Breaking change: `ImagePickerController.onRenovate` is now a constructor field instead of a getter,
  subclasses should pass `super.onRenovate`.
* Update `image_picker` to `1.2.4`, `mime` to `2.1.0`, `universal_io` to `2.3.1`.
* Align minimum SDK with dependencies: Dart `>=3.11.0`, Flutter `>=3.41.0`.
* Add `requestFullMetadata` to `FlImagePickerOptions` constructor.
* Pass `preferredCameraDevice` when recording videos.
* Detect `AssetType` from `XFile.mimeType`, `XFile.name` and path.
* Support `ImageProvider`, `blob:` URLs and web `XFile` in `buildImageProvider`.
* `FlXFile.fromPreviewed` now accepts `File`, `XFile` and `Uint8List`.
* `realValueStr` now also resolves `renovated` values.
* Expose `allowDelete` on `MultipleImagePicker`.
* `PickerAction.toAssetType()` is replaced by the `PickerAction.assetType` field.
* Breaking change: remove `SingleImagePicker.size`, use `width`/`height`.
* Breaking change: remove `FlImagePicker.imageBuilder`, `checkPermission` and `actionsBuilder`;
  override `ImagePickerController.buildPreview`, `requestPermission` and `buildActionSheet` instead.
* Fix controllers notifying listeners after being disposed and overlapping pick requests.
* Preserve `mimeType`/`name` in `FlXFile.toRenovated`, and return `null` for empty `realValueStr`.
* Recognize local file path strings in `FlImagePicker.buildImageProvider`.
* Add `onError` to picker APIs and controllers for plugin/renovate failures.
* Fix preview `PageController` leak and out-of-range initial index.
* Rebuild examples with Flutter 3.47 and new UI.

## 3.1.0

* Change the `ImagePickerOptions` to the `FlImagePickerOptions`
* Relax dependency versions

## 3.0.1

* Breaking change， Please refer to
  the [example](https://github.com/Wayaer/fl_assets_picker/blob/main/fl_image_picker/example/lib/main.dart)

## 2.1.0

* Update `mime`

## 2.0.0

* `assetXXX` -> `imageXXX`
* `AssetXXX` -> `ImageXXX`
* Fix some issues
* `maxVideoCount` defaults to 0

## 1.0.1

* Modify the static method name of `FlImagePicker`
* Remove `pickerIconBuilder` from `MultipleImagePicker`,Please use the `pick` of `itemConfig`
* Change the `PickerFromTypeItem` to the `PickerActionOptionss`
* Change the `PickerFromType` to the `PickerOptionalActions`
* Change the `fromTypes` to the `actions`
* Fix known issues

## 0.1.2

* Fixed an issue with `SingleImagePicker` not showing
* Error callback changed to enum

## 0.1.1

* Fix errors on the web

## 0.1.0

* initial release.
