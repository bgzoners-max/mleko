import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_back_button.dart';
import '../widgets/rustic_illustration.dart';

final _slides = [
  {
    'title': 'Pijaca domaće hrane',
    'subtitle':
        'Kupuj sveže mleko, sir, meso, med i zimnicu direktno od proverenih seoskih gazdinstava.',
    'motif': RusticMotif.fullBasket,
  },
  {
    'title': '100% Besplatni mali oglasi',
    'subtitle':
        'Besplatno oglasi ili pronađi bilo šta — telefone, tehniku, automobile, nameštaj, nekretnine, alate i usluge bez provizije.',
    'motif': RusticMotif.field,
  },
  {
    'title': 'Direktan dogovor bez posrednika',
    'subtitle':
        'Interni chat, mapa lokacija, direktan kontakt i 0% provizije — sav novac ide vama.',
    'motif': RusticMotif.delivery,
  },
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        actions: const [AppHomeButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Rustic ilustracija umesto generičke ikonice —
                        // onboarding nosi "ljudski" ton aplikacije.
                        RusticIllustration(
                          motif: s['motif'] as RusticMotif,
                          size: 168,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _current == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_current < _slides.length - 1) {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    } else {
                      context.go('/login');
                    }
                  },
                  child:
                      Text(_current < _slides.length - 1 ? 'Dalje' : 'Kreni'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
