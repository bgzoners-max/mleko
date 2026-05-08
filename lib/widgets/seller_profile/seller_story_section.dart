import 'package:flutter/material.dart';

import '../../core/responsive.dart';

class SellerStorySection extends StatelessWidget {
  final String story;

  const SellerStorySection({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(
          Breakpoints.adaptiveDouble(
            context,
            phone: 16,
            smallTabletValue: 17,
            largeTabletValue: 18,
            desktop: 18,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O gazdinstvu',
                style: Breakpoints.sectionTitleStyle(
                  context,
                  Theme.of(context).textTheme.titleMedium,
                )),
            const SizedBox(height: 8),
            Text(
              story,
              style: Breakpoints.supportingTextStyle(
                context,
                Theme.of(context).textTheme.bodyMedium,
                phone: 14,
                largeTabletValue: 15,
                desktop: 15,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
