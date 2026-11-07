import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../app_network_image.dart';

/// Sekcija slika proizvoda: postojeće URL slike + nove izabrane + dodavanje.
class ProductImagesSection extends StatelessWidget {
  final List<String> imageUrls;
  final List<Uint8List> newImageBytes;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;
  final VoidCallback onPickImage;

  const ProductImagesSection({
    super.key,
    required this.imageUrls,
    required this.newImageBytes,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onPickImage,
  });

  int get totalImages => imageUrls.length + newImageBytes.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Slike proizvoda (max ${AppConstants.maxProductImages})',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...imageUrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage.thumbnail(
                            imageUrl: e.value,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => onRemoveExisting(e.key),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              ...newImageBytes.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            e.value,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => onRemoveNew(e.key),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (totalImages < AppConstants.maxProductImages)
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
