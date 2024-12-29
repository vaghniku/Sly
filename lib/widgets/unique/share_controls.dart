import 'package:flutter/material.dart';
import 'package:sly/widgets/button.dart';

import '/layout.dart';
import '/widgets/switch.dart';
import '/widgets/unique/save_button.dart';

class SlyShareControls extends StatelessWidget {
  final Function getSaveMetadata;
  final Function setSaveMetadata;
  final bool multipleImages;
  final SlySaveButton? saveButton;
  final VoidCallback? saveAll;
  final VoidCallback? copyEdits;
  final VoidCallback? pasteEdits;
  final bool canPasteEdits;

  const SlyShareControls({
    super.key,
    required this.getSaveMetadata,
    required this.setSaveMetadata,
    required this.multipleImages,
    this.saveButton,
    this.saveAll,
    this.copyEdits,
    this.pasteEdits,
    this.canPasteEdits = false,
  });

  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('shareControls'),
        physics: isWide(context) ? null : const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save Metadata'),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Such as date taken and location',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                SlySwitch(
                  value: getSaveMetadata(),
                  onChanged: (value) => setSaveMetadata(value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: saveButton,
          ),
          multipleImages
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 16),
                  child: SlyButton(
                    onPressed: saveAll,
                    child: const Text('Save All'),
                  ),
                )
              : Container(),
          multipleImages
              ? canPasteEdits
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        const Text(
                          'Edits',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            Expanded(
                              child: SlyButton(
                                onPressed: copyEdits,
                                child: const Text('Copy'),
                              ),
                            ),
                            Expanded(
                              child: SlyButton(
                                onPressed: pasteEdits,
                                child: const Text('Paste'),
                              ),
                            )
                          ],
                        )
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SlyButton(
                        onPressed: copyEdits,
                        child: const Text('Copy Edits'),
                      ),
                    )
              : Container(),
        ],
      );
}
