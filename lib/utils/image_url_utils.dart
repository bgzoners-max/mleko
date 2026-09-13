/// Pomoćni alati za URL-ove slika u Supabase Storage-u.
///
/// Omogućavaju da kartice (thumbnaili) i ostali widgeti koriste server-side transformaciju
/// (`/storage/v1/render/image/public/...?width=...&quality=...`) umesto
/// preuzimanja originalnih fajlova pune rezolucije na svaki uređaj.
class ImageUrlUtils {
  /// Kill-switch: ako server-side transformacija nije dostupna (ili bucket je
  /// privatan), postavi na `false` da bi sve slike opet išle u originalnoj
  /// rezoluciji bez promene ostatka koda.
  static const bool kServerTransformsEnabled = true;

  static const String _objectPublicPath = '/storage/v1/object/public/';
  static const String _renderImagePath = '/storage/v1/render/image/public/';

  /// Vraća URL transformisane slike, ili `null` ako transformacija nije moguća
  /// (URL nije iz Supabase Storage-a, već ima parametre, ili je globalno isključena).
  static String? transformUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 80,
    String? resize,
  }) {
    if (!kServerTransformsEnabled) return null;
    if (originalUrl.isEmpty) return null;

    final idx = originalUrl.indexOf(_objectPublicPath);
    if (idx < 0) return null;
    // Već ima parametre (signed URL / već transformisano) – ne diraj.
    if (originalUrl.contains('?')) return null;

    final before = originalUrl.substring(0, idx);
    final after = originalUrl.substring(idx + _objectPublicPath.length);

    final queryParams = <String>[];
    if (width != null) queryParams.add('width=$width');
    if (height != null) queryParams.add('height=$height');
    queryParams.add('quality=$quality');
    if (resize != null && resize.isNotEmpty) queryParams.add('resize=$resize');

    return '$before$_renderImagePath$after?${queryParams.join('&')}';
  }

  /// Thumbnail za kartice (podrazumevano 400px širina, kvalitet 80)
  static String? thumbnailUrl(
    String originalUrl, {
    int width = 400,
    int quality = 80,
  }) =>
      transformUrl(originalUrl, width: width, quality: quality);

  /// Za male ikone i avatare (podrazumevano 120px širina/visina)
  static String? iconUrl(
    String originalUrl, {
    int size = 120,
    int quality = 80,
  }) =>
      transformUrl(originalUrl, width: size, height: size, quality: quality);

  /// Za veće prikaze na ekranu detalja (podrazumevano 800px širina)
  static String? detailUrl(
    String originalUrl, {
    int width = 800,
    int quality = 85,
  }) =>
      transformUrl(originalUrl, width: width, quality: quality);
}