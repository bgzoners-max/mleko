import 'dart:convert';
import 'package:web/web.dart' as web;

String resolveBaseUrl([String? origin]) {
  if (origin != null && origin.isNotEmpty) {
    if (origin == 'https://domacimarket.rs') return 'https://www.domacimarket.rs';
    return origin;
  }
  final windowOrigin = web.window.location.origin;
  if (windowOrigin.isNotEmpty) {
    if (windowOrigin == 'https://domacimarket.rs') return 'https://www.domacimarket.rs';
    return windowOrigin;
  }
  return 'https://www.domacimarket.rs';
}

bool isWebOnline() {
  try {
    return web.window.navigator.onLine;
  } catch (_) {
    return true;
  }
}

void setPageMetadata({
  required String title,
  String? description,
  String? path,
  String? imageUrl,
  String? type,
  String? keywords,
  String? robots,
  Map<String, dynamic>? jsonLd,
}) {
  final origin = resolveBaseUrl();

  // 1. Title
  web.document.title = title;
  _upsertMetaByName('title', title);
  _upsertMetaByProperty('og:title', title);
  _upsertMetaByName('twitter:title', title);

  // 2. Description
  if (description != null && description.isNotEmpty) {
    _upsertMetaByName('description', description);
    _upsertMetaByProperty('og:description', description);
    _upsertMetaByName('twitter:description', description);
  }

  // 3. Keywords
  if (keywords != null && keywords.isNotEmpty) {
    _upsertMetaByName('keywords', keywords);
  }

  // 4. Robots direktiva (Googlebot & pretraživači)
  final robotsContent = robots ??
      'index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1';
  _upsertMetaByName('robots', robotsContent);
  _upsertMetaByName('googlebot', robotsContent);

  // 5. OpenGraph Type & Twitter Card
  _upsertMetaByProperty('og:type', type ?? 'website');
  _upsertMetaByProperty('og:site_name', 'Domaći Market');
  _upsertMetaByProperty('og:locale', 'sr_RS');
  _upsertMetaByName('twitter:card', 'summary_large_image');

  // 6. Image
  final resolvedImageUrl = _normalizeUrl(
    imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : 'https://www.domacimarket.rs/icons/Icon-512.png',
    origin,
  );
  _upsertMetaByProperty('og:image', resolvedImageUrl);
  _upsertMetaByProperty('og:image:secure_url', resolvedImageUrl);
  _upsertMetaByName('twitter:image', resolvedImageUrl);

  // 7. Canonical URL, hreflang i OG URL
  final canonicalUrl = _normalizeUrl(path ?? '/', origin);
  _upsertCanonical(canonicalUrl);
  _syncHreflangLinks(canonicalUrl);
  _upsertMetaByProperty('og:url', canonicalUrl);
  _upsertMetaByName('twitter:url', canonicalUrl);

  // 8. Strukturirani podaci (Schema.org JSON-LD)
  if (jsonLd != null) {
    _upsertJsonLd(jsonLd);
  } else {
    _removeDynamicJsonLd();
  }
}

String _normalizeUrl(String value, String origin) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('/')) {
    return '$origin$value';
  }
  return '$origin/$value';
}

void _upsertMetaByName(String name, String content) {
  final head = web.document.head;
  if (head == null) return;
  final existing =
      head.querySelector('meta[name="$name"]') as web.HTMLMetaElement?;
  if (existing != null) {
    existing.content = content;
    return;
  }

  final meta = web.document.createElement('meta') as web.HTMLMetaElement
    ..name = name
    ..content = content;
  head.append(meta);
}

void _upsertMetaByProperty(String property, String content) {
  final head = web.document.head;
  if (head == null) return;
  final existing =
      head.querySelector('meta[property="$property"]') as web.HTMLMetaElement?;
  if (existing != null) {
    existing.content = content;
    return;
  }

  final meta = web.document.createElement('meta') as web.HTMLMetaElement
    ..setAttribute('property', property)
    ..content = content;
  head.append(meta);
}

void _upsertCanonical(String href) {
  final head = web.document.head;
  if (head == null) return;
  final existing =
      head.querySelector('link[rel="canonical"]') as web.HTMLLinkElement?;
  if (existing != null) {
    existing.href = href;
    return;
  }

  final link = web.document.createElement('link') as web.HTMLLinkElement
    ..rel = 'canonical'
    ..href = href;
  head.append(link);
}

void _syncHreflangLinks(String href) {
  final head = web.document.head;
  if (head == null) return;

  final legacySr = head.querySelector('link[rel="alternate"][hreflang="sr"]');
  legacySr?.remove();

  for (final hreflang in const ['sr-RS', 'x-default']) {
    final existing =
        head.querySelector('link[rel="alternate"][hreflang="$hreflang"]')
            as web.HTMLLinkElement?;
    if (existing != null) {
      existing.href = href;
      continue;
    }
    final link = web.document.createElement('link') as web.HTMLLinkElement
      ..rel = 'alternate'
      ..hreflang = hreflang
      ..href = href;
    head.append(link);
  }
}

void _upsertJsonLd(Map<String, dynamic> jsonMap) {
  final head = web.document.head;
  if (head == null) return;
  const scriptId = 'seo-dynamic-jsonld';
  var script = head.querySelector('#$scriptId') as web.HTMLScriptElement?;
  if (script == null) {
    script = (web.document.createElement('script') as web.HTMLScriptElement)
      ..id = scriptId
      ..type = 'application/ld+json';
    head.append(script);
  }
  script.text = jsonEncode(jsonMap);
}

void _removeDynamicJsonLd() {
  const scriptId = 'seo-dynamic-jsonld';
  final script = web.document.head?.querySelector('#$scriptId');
  script?.remove();
}
