import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mleko/providers/app_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsProvider MarketMode defaults and persistence', () {
    test('default marketMode is foodMarket', () {
      final settings = AppSettingsProvider(autoload: false);
      expect(settings.marketMode, equals(MarketMode.foodMarket));
    });

    test('ensureLoaded defaults marketMode to foodMarket when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsProvider(autoload: false);
      await settings.ensureLoaded();

      expect(settings.marketMode, equals(MarketMode.foodMarket));
    });

    test('ensureLoaded removes legacy mleko_market_mode key and defaults to foodMarket', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_market_mode': 0, // legacy classifieds default
      });
      final settings = AppSettingsProvider(autoload: false);
      await settings.ensureLoaded();

      expect(settings.marketMode, equals(MarketMode.foodMarket));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('mleko_market_mode'), isFalse);
    });

    test('setMarketMode persists classifieds and foodMarket correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsProvider(autoload: false);
      await settings.ensureLoaded();

      await settings.setMarketMode(MarketMode.classifieds);
      expect(settings.marketMode, equals(MarketMode.classifieds));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('mleko_market_mode_v2'), equals(1));

      // Reload in fresh provider
      final reloaded = AppSettingsProvider(autoload: false);
      await reloaded.ensureLoaded();
      expect(reloaded.marketMode, equals(MarketMode.classifieds));

      // Switch back to foodMarket
      await reloaded.setMarketMode(MarketMode.foodMarket);
      expect(reloaded.marketMode, equals(MarketMode.foodMarket));

      final reloaded2 = AppSettingsProvider(autoload: false);
      await reloaded2.ensureLoaded();
      expect(reloaded2.marketMode, equals(MarketMode.foodMarket));
    });

    test('reload re-reads from SharedPreferences after in-memory change', () async {
      SharedPreferences.setMockInitialValues({'mleko_market_mode_v2': 0}); // foodMarket
      final settings = AppSettingsProvider(autoload: false);
      await settings.ensureLoaded();
      expect(settings.marketMode, equals(MarketMode.foodMarket));

      // Promeni u memoriji — ovoga puta perzistira classifieds
      await settings.setMarketMode(MarketMode.classifieds);
      expect(settings.marketMode, equals(MarketMode.classifieds));

      // reload() mora pročitati sačuvanu vrednost iz SharedPreferences (classifieds)
      await settings.reload();
      expect(settings.marketMode, equals(MarketMode.classifieds));
      expect(settings.isLoaded, isTrue);
    });

    test('ensureLoaded can be called multiple times without error', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettingsProvider(autoload: false);

      await settings.ensureLoaded();
      await settings.ensureLoaded();
      await settings.ensureLoaded();

      expect(settings.marketMode, equals(MarketMode.foodMarket));
      expect(settings.isLoaded, isTrue);
    });
  });
}
