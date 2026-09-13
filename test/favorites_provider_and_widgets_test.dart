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

      provider.clear();
      expect(provider.isLoaded, isFalse);
      expect(provider.ids, isEmpty);

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
  });
}
