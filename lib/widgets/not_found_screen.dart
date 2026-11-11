import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/web_seo.dart';
import 'app_back_button.dart';

class NotFoundScreen extends StatefulWidget {
  const NotFoundScreen({super.key, this.requestedPath});

  final String? requestedPath;

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen> {
  @override
  void initState() {
    super.initState();
    setNotFoundSeo(path: widget.requestedPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stranica nije pronađena'),
        leading: const AppBackButton(fallbackRoute: '/'),
        actions: const [AppHomeButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Tražena stranica ne postoji ili je premeštena.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Početna stranica'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
