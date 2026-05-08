import 'package:flutter/material.dart';

class PanelPlaceholder extends StatelessWidget {
  const PanelPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Odaberite stavku iz menija',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
