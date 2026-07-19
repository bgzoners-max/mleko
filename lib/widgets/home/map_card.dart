import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kartica mape â€“ kompaktno, tap otvara punu mapu
class MapCard extends StatelessWidget {
  const MapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/sellers-map'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.map_outlined,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prodavci na mapi',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                          ),
                          Text(
                            'PronaÄ‘i domaÄ‡e u svojoj blizini',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => context.push('/about'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('O platformi'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/support'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('PodrÅ¡ka'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/uslovi-koriscenja'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Uslovi koriÅ¡Ä‡enja'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/politika-privatnosti'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Politika privatnosti'),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/footer_badge.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.red),
                      Text('Error', style: TextStyle(fontSize: 8, color: Colors.red)),
                    ],
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
