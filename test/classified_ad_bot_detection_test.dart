import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Classified ad views bot detection and deduplication rules', () {
    // Exact regex used in PostgreSQL function increment_classified_ad_views:
    final botRegex = RegExp(
      r'(bot|crawl|spider|slurp|curl|wget|python|scrapy|aiohttp|httpx|headless|chrome-lighthouse|lighthouse|preview|scraper|facebookexternalhit|whatsapp|telegrambot|discordbot|slackbot|archive\.org|semrush|ahrefs|bingbot|googlebot|yandex|bytespider)',
      caseSensitive: false,
    );

    test('flags automated search crawlers and scrapers as bots', () {
      final knownBots = [
        'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
        'Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)',
        'Mozilla/5.0 (compatible; AhrefsBot/7.0; +http://ahrefs.com/robot/)',
        'SemrushBot/7~bl (http://www.semrush.com/bot.html)',
        'curl/7.88.1',
        'Wget/1.21.3',
        'python-requests/2.31.0',
        'Scrapy/2.11.0 (+https://scrapy.org)',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 HeadlessChrome/118.0.5993.88 Safari/537.36',
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        'WhatsApp/2.23.20.76 A',
        'TelegramBot (like TwitterBot)',
        'Mozilla/5.0 (compatible; Discordbot/2.0; +https://discordapp.com)',
        'Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)',
        'Mozilla/5.0 (compatible; archive.org_bot +http://archive.org/details/archive.org_bot)',
        'Bytespider; spider-feedback@bytedance.com',
      ];

      for (final ua in knownBots) {
        expect(botRegex.hasMatch(ua), isTrue,
            reason: 'Should detect $ua as bot');
      }
    });

    test('allows legitimate mobile and web user agents', () {
      final legitimateUAs = [
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.6422.165 Mobile Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0',
        'Dart/3.4 (dart:io)',
      ];

      for (final ua in legitimateUAs) {
        expect(botRegex.hasMatch(ua), isFalse,
            reason: 'Should allow legitimate UA: $ua');
      }
    });

    test('flags bot viewer IDs', () {
      final botViewerIdRegex = RegExp(r'^(bot|spider|crawler)', caseSensitive: false);
      expect(botViewerIdRegex.hasMatch('bot-probe-123'), isTrue);
      expect(botViewerIdRegex.hasMatch('spider-99'), isTrue);
      expect(botViewerIdRegex.hasMatch('crawler-x'), isTrue);
      expect(botViewerIdRegex.hasMatch('inst_1a2b3c4d5e6f'), isFalse);
      expect(botViewerIdRegex.hasMatch('usr-77'), isFalse);
    });

    test('anonymous viewer hash differentiates browser/device behind same IP', () {
      const ip = '178.222.45.10';
      const chromeUa = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126.0';
      const safariUa = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5) Safari/604.1';

      String fingerprint(String ip, String ua) => 'ip_ua:${ip.hashCode}_${ua.hashCode}';

      final hashChrome = fingerprint(ip, chromeUa);
      final hashSafari = fingerprint(ip, safariUa);

      expect(hashChrome, isNot(equals(hashSafari)));
      expect(hashChrome, startsWith('ip_ua:'));
    });

    test('24-hour deduplication window correctly identifies stale vs active views', () {
      final now = DateTime.now();
      final viewRecent = now.subtract(const Duration(hours: 12));
      final viewOld = now.subtract(const Duration(hours: 25));

      bool isWithin24Hours(DateTime lastViewed) =>
          now.difference(lastViewed) < const Duration(hours: 24);

      expect(isWithin24Hours(viewRecent), isTrue,
          reason: 'View within 24h should be ignored (deduplicated)');
      expect(isWithin24Hours(viewOld), isFalse,
          reason: 'View older than 24h should be counted as new view');
    });
  });
}
