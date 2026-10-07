import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';

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
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...imageUrls.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: e.value,
                            width: 100,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                            onPressed: () => onRemoveExisting(e.key),
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
                          child: Image.memory(e.value,
                              width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                            onPressed: () => onRemoveNew(e.key),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (totalImages < AppConstants.maxProductImages)
                GestureDetector(
                  onTap: onPickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_photo_alternate,
                        size: 40, color: Colors.grey.shade400),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
