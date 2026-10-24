import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Servis za optimizaciju, normalizaciju i kompresiju slika na klijentu (pre uploada).
///
/// Funkcionalnosti:
/// 1. Dekodira sve formate (JPEG, PNG, WebP, HEIC/TIFF gde je podržano).
/// 2. Ispravlja rotaciju na osnovu EXIF metapodataka (kamera telefona).
/// 3. Smanjuje dimenzije na najviše [maxWidth] x [maxHeight] (default 1600px) zadržavajući proporcije.
/// 4. Briše nepotrebne/glomazne metapodatke (C2PA, GPS, thumbnail-ove) koji mogu pokvariti WebCodecs/CanvasKit renderovanje.
/// 5. Kodira u standardni čisti JPEG (default 82% kvalitet) čime se postiže 5-10x manji fajl i garantovana kompatibilnost.
class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._();

  /// Maksimalne standardne dimenzije za oglas/proizvod
  static const int defaultMaxWidth = 1600;
  static const int defaultMaxHeight = 1600;
  static const int defaultQuality = 82;

  /// Kompresuje pojedinačnu sliku u čisti JPEG format.
  /// Ako dekodiranje ne uspe (npr. nepoznat binarni format), bezbedno vraća originalne bajtove.
  Future<Uint8List> compressImage(
    Uint8List inputBytes, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
  }) async {
    // Na Web-u i native platformama: compute ili direktno izvršavanje
    // Za Web kIsWeb compute koristi web worker ili async task; jednostavna obrada je brza
    if (kIsWeb) {
      return _processImageBytes(inputBytes, maxWidth, maxHeight, quality);
    } else {
      return compute(
        _processImageParams,
        _ImageProcessParams(
          bytes: inputBytes,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        ),
      );
    }
  }

  /// Kompresuje listu slika sa ograničenom konkurentnošću i opcionalnim callback-om
  /// za napredak (redni broj po završetku, ne po pokretanju). Orderi rezultata su
  /// očuvani u odnosu na ulazni niz.
  ///
  /// `maxConcurrency` po zadatoj vrednosti pokreće najviše toliko `compute` isolate-a
  /// istovremeno kako se na mobilnim uređajima ne bi preopteretio CPU/memorija.
  Future<List<Uint8List>> compressMultiple(
    List<Uint8List> images, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    int maxConcurrency = 3,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <Uint8List?>[]..length = images.length;
    var processed = 0;

    var nextIndex = 0;
    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        if (index >= images.length) return;
        nextIndex++;
        final compressed = await compressImage(
          images[index],
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        results[index] = compressed;
        processed++;
        onProgress?.call(processed, images.length);
      }
    }

    final workerCount = images.isEmpty
        ? 0
        : (maxConcurrency < 1 ? 1 : maxConcurrency).clamp(1, images.length);
    await Future.wait(
      List.generate(workerCount, (_) => worker()),
    );
    return results.cast<Uint8List>();
  }

  static Uint8List _processImageParams(_ImageProcessParams params) {
    return _processImageBytes(
      params.bytes,
      params.maxWidth,
      params.maxHeight,
      params.quality,
    );
  }

  static Uint8List _processImageBytes(
    Uint8List inputBytes,
    int maxWidth,
    int maxHeight,
    int quality,
  ) {
    try {
      final decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        debugPrint(
            'ImageCompressionService: Nije moguće dekodirati sliku, vraćam original.');
        return inputBytes;
      }

      // 1. Ispravka rotacije na osnovu EXIF orijentacije (orijentacija mobilnog telefona)
      final oriented = img.bakeOrientation(decoded);

      // 2. Skaliranje ako prelazi maksimalne dimenzije
      var finalImage = oriented;
      if (oriented.width > maxWidth || oriented.height > maxHeight) {
        if (oriented.width >= oriented.height) {
          finalImage = img.copyResize(
            oriented,
            width: maxWidth,
            interpolation: img.Interpolation.linear,
          );
        } else {
          finalImage = img.copyResize(
            oriented,
            height: maxHeight,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      // 3. Kodiranje u čisti JPEG bez glomaznih ne-standardnih chunk-ova
      final encodedJpg = img.encodeJpg(finalImage, quality: quality);
      return Uint8List.fromList(encodedJpg);
    } catch (e) {
      debugPrint(
          'ImageCompressionService: Greška pri obradi slike ($e), vraćam original.');
      return inputBytes;
    }
  }
}

class _ImageProcessParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  _ImageProcessParams({
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}
