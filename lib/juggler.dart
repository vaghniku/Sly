import 'dart:typed_data';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

import '/image.dart';
import '/widgets/spinner.dart';
import '/widgets/snack_bar.dart';
import '/widgets/unique/editor.dart';

/// Manages loading and switching between multiple images.
class SlyJuggler {
  StreamController<String> controller = StreamController<String>();
  final List<Map<String, dynamic>?> images = [];
  SlyImage? copiedEdits;

  final List<Widget> carouselChildren = [];

  int _selected = 0;
  get selected => _selected;
  set selected(value) {
    _selected = value;
    editedImage ??= SlyImage.from(originalImage);
    controller.add('new image');
  }

  Map<String, dynamic>? get selectedImage => images[selected];

  SlyImage get originalImage => selectedImage?['originalImage'];

  SlyImage? get editedImage => selectedImage?['editedImage'];
  set editedImage(value) {
    selectedImage?['editedImage'] = value;
    selectedImage?['cropController'] = cropController ?? CropController();
    subscription?.cancel();
    selectedImage?['subscription'] =
        editedImage!.controller.stream.listen((event) => controller.add(event));
  }

  String? get suggestedFileName => selectedImage?['suggestedFileName'];
  CropController? get cropController => selectedImage?['cropController'];
  StreamSubscription<String>? get subscription =>
      selectedImage?['subscription'];

  /// Creates a Juggler without any initial images.
  ///
  /// Call `editImages` with a set of images to start editing.
  SlyJuggler();

  /// Adds an image to the Juggler and updates the Carousel.
  void add(SlyImage image, {String suggesedFileName = 'Edited Image'}) {
    images.insert(
        0, {'originalImage': image, 'suggestedFileName': suggesedFileName});
    carouselChildren.insert(
      0,
      FutureBuilder<Uint8List>(
        future: image.encode(
          format: SlyImageFormat.jpeg75,
          maxSideLength: 150,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          } else if (snapshot.hasError) {
            return Container();
          } else {
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: SlySpinner(),
              ),
            );
          }
        },
      ),
    );
    controller.add('image added');
  }

  /// Removes the image at `index`.
  ///
  /// If there are any more images, selects the one to the left.
  void remove(int index) {
    if (copiedEdits == editedImage) copiedEdits = null;

    images.removeAt(index);
    carouselChildren.removeAt(index);

    if (images.isNotEmpty) selected = max(0, index - 1);

    controller.add('removed');
  }

  /// Used to pick new images to edit or to select existing ones.
  ///
  /// When used *without* `newSelection`, it will prompt the user
  /// to pick a new set of images from their gallery.
  ///
  /// When used *with* `newSelection`, it will select
  /// the image at that index for editing.
  Future<void> editImages({
    required BuildContext context,
    VoidCallback? loadingCallback,
    VoidCallback? failedCallback,
    bool animate = true,
    int? newSelection,
  }) async {
    if (newSelection == null) {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();

      if (files.isEmpty) {
        if (failedCallback != null) failedCallback();
        return;
      }

      if (!context.mounted) {
        if (failedCallback != null) failedCallback();
        return;
      }
      if (loadingCallback != null) loadingCallback();

      final List<List> newImages = [];
      for (final file in files) {
        final image = await SlyImage.fromData(await file.readAsBytes());
        if (image == null) {
          if (failedCallback != null) failedCallback();

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showSlySnackBar(context, 'Couldn’t Load Image');
          return;
        }

        newImages.add([
          image,
          '${file.name.replaceAll(RegExp(r'\.[^\.]+$'), '')} Edited',
        ]);
      }

      if (!context.mounted) {
        if (failedCallback != null) failedCallback();
        return;
      }

      final empty = images.isEmpty;

      for (final image in newImages) {
        add(image[0], suggesedFileName: image[1] != '' ? image[1] : null);
      }
      selected = 0;

      if (empty) {
        Navigator.pushReplacement(
          context,
          animate
              ? MaterialPageRoute(
                  builder: (context) => SlyEditorPage(juggler: this),
                )
              : PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SlyEditorPage(juggler: this),
                ),
        );
      }
    } else {
      selected = newSelection;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Copies edits from the current image for pasting later.
  void copyEdits() {
    copiedEdits = editedImage;
  }

  /// Pastes edits from another image.
  ///
  /// Does not include geometry attributes.
  void pasteEdits() {
    if (copiedEdits == null || copiedEdits == editedImage) return;
    editedImage?.copyEditsFrom(copiedEdits!, skipGeometry: true);
    editedImage?.applyEditsProgressive();
  }
}
