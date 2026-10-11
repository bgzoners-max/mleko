import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/favorites_provider.dart';
import 'package:mleko/widgets/category_icon.dart';
import 'package:mleko/widgets/emoji_text.dart';

void main() {
  group('FavoritesProvider', () {
    test('clears and checks favorite ids correctly', () async {
      final provider = FavoritesProvider();

      expect(provider.isLoaded, isFalse);
      expect(provider.ids, isEmpty);

      // load sa null userId
      await provider.load(null);
      expect(provider.isLoaded, isTrue);
      expect(provider.ids, isEmpty);

      expect(provider.isFavorite('p-1'), isFalse);
      expect(provider.idSet, isEmpty);
      expect(provider.count, 0);

      provider.clear();
      expect(provider.isLoaded, isFalse);
      expect(provider.ids, isEmpty);
      expect(provider.count, 0);

      provider.dispose();
    });
  });

  group('EmojiText & CategoryIcon Widgets', () {
    testWidgets('renders EmojiText with fallback fonts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmojiText('🥛 Sveže mleko'),
          ),
        ),
      );

      expect(find.text('🥛 Sveže mleko'), findsOneWidget);
    });

    testWidgets('renders buildCategoryIcon with emoji, material icon and fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                buildCategoryIcon(null),
                buildCategoryIcon('eco'),
                buildCategoryIcon('🥛'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.text('🥛'), findsOneWidget);
    });

    testWidgets('renders CategoryIcon widget with section icons and semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CategoryIcon(
                  iconName: 'hrana',
                  semanticLabel: 'Hrana sekcija',
                ),
                CategoryIcon(
                  iconName: 'osnove',
                  semanticLabel: 'Osnove sekcija',
                ),
                CategoryIcon(
                  iconName: 'pica',
                  semanticLabel: 'Pića sekcija',
                ),
                CategoryIcon(
                  iconName: 'specijaliteti',
                  semanticLabel: 'Specijaliteti sekcija',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.agriculture), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // specijaliteti -> sunka.png asset
      expect(find.bySemanticsLabel('Hrana sekcija'), findsOneWidget);
      expect(find.bySemanticsLabel('Osnove sekcija'), findsOneWidget);
    });
  });
}
