import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('=== POČETAK OPTIMIZACIJE ASSETA ===');

  int totalBytesSaved = 0;

  // 1. Uklanjanje mrtvih / nekorišćenih fajlova
  final deadFiles = [
    'assets/images/app_icon.png',
    'assets/images/login_background.png',
    'assets/images/logo.png',
    'assets/images/footer_badge.png',
    'assets/images/domaci_market_logo.png',
    'assets/images/home_header.png',
  ];

  for (final path in deadFiles) {
    final file = File(path);
    if (file.existsSync()) {
      final size = file.lengthSync();
      file.deleteSync();
      totalBytesSaved += size;
      print('Obrisan nekorišćeni fajl: $path (${(size / (1024 * 1024)).toStringAsFixed(2)} MB)');
    }
  }

  final deadDir = Directory('assets/images/1');
  if (deadDir.existsSync()) {
    int dirSize = 0;
    for (final f in deadDir.listSync(recursive: true).whereType<File>()) {
      dirSize += f.lengthSync();
    }
    deadDir.deleteSync(recursive: true);
    totalBytesSaved += dirSize;
    print('Obrisan napušteni folder: assets/images/1 (${(dirSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
  }

  // 2. Optimizacija velikih slika
  void optimizePng(String path, {int? maxDimension}) {
    final file = File(path);
    if (!file.existsSync()) return;
    final originalBytes = file.readAsBytesSync();
    final originalSize = originalBytes.length;

    var image = img.decodeImage(originalBytes);
    if (image == null) return;

    if (maxDimension != null && (image.width > maxDimension || image.height > maxDimension)) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    final optimizedBytes = img.encodePng(image, level: 9);
    if (optimizedBytes.length < originalSize) {
      file.writeAsBytesSync(optimizedBytes);
      final saved = originalSize - optimizedBytes.length;
      totalBytesSaved += saved;
      print('Optimizovan PNG: $path (${(originalSize / 1024).toStringAsFixed(1)} KB -> ${(optimizedBytes.length / 1024).toStringAsFixed(1)} KB, ušteda: ${(saved / 1024).toStringAsFixed(1)} KB)');
    }
  }

  void optimizeJpg(String path, {int quality = 82, int? maxDimension}) {
    final file = File(path);
    if (!file.existsSync()) return;
    final originalBytes = file.readAsBytesSync();
    final originalSize = originalBytes.length;

    var image = img.decodeImage(originalBytes);
    if (image == null) return;

    if (maxDimension != null && (image.width > maxDimension || image.height > maxDimension)) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    final optimizedBytes = img.encodeJpg(image, quality: quality);
    if (optimizedBytes.length < originalSize) {
      file.writeAsBytesSync(optimizedBytes);
      final saved = originalSize - optimizedBytes.length;
      totalBytesSaved += saved;
      print('Optimizovan JPG: $path (${(originalSize / 1024).toStringAsFixed(1)} KB -> ${(optimizedBytes.length / 1024).toStringAsFixed(1)} KB, ušteda: ${(saved / 1024).toStringAsFixed(1)} KB)');
    }
  }

  // Optimizuj ključne slike
  optimizeJpg('assets/images/hero_farm_banner.jpg', quality: 80);
  optimizePng('assets/images/header_logo.png', maxDimension: 512);
  optimizePng('assets/images/domaci_market_logo_v2.png', maxDimension: 512);
  optimizePng('assets/icon/app_icon.png', maxDimension: 512);

  // Optimizuj slike kategorija (cvarci, slanina, sunka)
  final catDir = Directory('assets/images/categories');
  if (catDir.existsSync()) {
    for (final f in catDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        optimizePng(f.path, maxDimension: 300);
      }
    }
  }

  // Optimizuj slike automobilskih brendova (prikazuju se kao ikonice max 40x40)
  final carBrandsDir = Directory('assets/images/car_brands');
  if (carBrandsDir.existsSync()) {
    for (final f in carBrandsDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        optimizePng(f.path, maxDimension: 160);
      }
    }
  }

  // Optimizuj slike mobilnih brendova (prikazuju se kao ikonice)
  final phoneBrandsDir = Directory('assets/images/phone_brands');
  if (phoneBrandsDir.existsSync()) {
    for (final f in phoneBrandsDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        optimizePng(f.path, maxDimension: 160);
      }
    }
  }

  // Optimizuj slike traktorskih brendova (prikazuju se kao ikonice)
  final tractorBrandsDir = Directory('assets/images/tractor_brands');
  if (tractorBrandsDir.existsSync()) {
    for (final f in tractorBrandsDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        optimizePng(f.path, maxDimension: 160);
      }
    }
  }

  print('--------------------------------------------------');
  print('UKUPNA UŠTEDA NA ASSETIMA: ${(totalBytesSaved / (1024 * 1024)).toStringAsFixed(2)} MB');
  print('=== KRAJ OPTIMIZACIJE ===');
}
