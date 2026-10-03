import '../models/classified_ad_model.dart';
import '../models/classified_category_model.dart';
import '../models/product_model.dart';
import 'web_seo_stub.dart' if (dart.library.html) 'web_seo_web.dart' as impl;

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
  impl.setPageMetadata(
    title: title,
    description: description,
    path: path,
    imageUrl: imageUrl,
    type: type,
    keywords: keywords,
    robots: robots,
    jsonLd: jsonLd,
  );
}

/// Dinamički origin / javni base URL za konzistentnost sa Vercel Edge funkcijama
String get publicBaseUrl => impl.resolveBaseUrl();

/// SEO za pojedinačni proizvod (Google Schema.org Product Rich Snippet)
void setProductSeo(ProductModel product) {
  final cleanDesc = product.description.trim().isNotEmpty
      ? product.description.trim().replaceAll(RegExp(r'\s+'), ' ')
      : 'Kupite domaći proizvod ${product.name} direktno od poljoprivrednog gazdinstva.';
  final metaDesc = cleanDesc.length <= 160
      ? cleanDesc
      : '${cleanDesc.substring(0, 157).trimRight()}...';

  final priceNum = product.pricePerKg;
  final mainImage =
      product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

  final jsonLd = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'Product',
    'name': product.name,
    'description': cleanDesc,
    'image': product.imageUrls.isNotEmpty
        ? product.imageUrls
        : ['$publicBaseUrl/icons/Icon-512.png'],
    'category': product.category,
    'offers': {
      '@type': 'Offer',
      'priceCurrency': 'RSD',
      'price': priceNum,
      'availability': product.availableNow
          ? 'https://schema.org/InStock'
          : 'https://schema.org/OutOfStock',
      'url': '$publicBaseUrl/product/${product.id}',
      'priceValidUntil': '${DateTime.now().year + 1}-12-31',
    },
    if (product.avgRating != null && product.reviewCount > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': product.avgRating!.toStringAsFixed(1),
        'reviewCount': product.reviewCount,
        'bestRating': '5',
        'worstRating': '1',
      },
  };

  setPageMetadata(
    title: '${product.name} | Cena: ${product.priceFormatted} | Domaći Market',
    description: metaDesc,
    path: '/product/${product.id}',
    imageUrl: mainImage,
    type: 'product',
    keywords:
        '${product.name}, ${product.category}, ${product.location}, domaći proizvodi, zdrava hrana, seoska gazdinstva',
    jsonLd: jsonLd,
  );
}

/// SEO za mali oglas (Google Schema.org Product / Classified Offer)
void setClassifiedAdSeo(ClassifiedAdModel ad) {
  final cleanDesc = ad.description.trim().isNotEmpty
      ? ad.description.trim().replaceAll(RegExp(r'\s+'), ' ')
      : '${ad.title} – mali oglas u mestu ${ad.city} na platformi Domaći Market.';
  final metaDesc = cleanDesc.length <= 160
      ? cleanDesc
      : '${cleanDesc.substring(0, 157).trimRight()}...';

  final mainImage = ad.images.isNotEmpty ? ad.images.first : null;

  final jsonLd = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'Product',
    'name': ad.title,
    'description': cleanDesc,
    if (ad.images.isNotEmpty) 'image': ad.images,
    if (ad.categoryName != null) 'category': ad.categoryName,
    'offers': {
      '@type': 'Offer',
      'priceCurrency': ad.currency,
      'price': ad.price,
      'availability': ad.isActive
          ? 'https://schema.org/InStock'
          : 'https://schema.org/OutOfStock',
      'url': '$publicBaseUrl/classifieds/ad/${ad.id}',
      'itemCondition': ad.condition == 'new'
          ? 'https://schema.org/NewCondition'
          : 'https://schema.org/UsedCondition',
    },
    if (ad.sellerName != null)
      'seller': {
        '@type': 'Person',
        'name': ad.sellerName,
      },
  };

  setPageMetadata(
    title: '${ad.title} | ${ad.priceFormatted} | Mali Oglasi Domaći Market',
    description: metaDesc,
    path: '/classifieds/ad/${ad.id}',
    imageUrl: mainImage,
    type: 'product',
    keywords:
        '${ad.title}, ${ad.categoryName ?? "mali oglasi"}, ${ad.city}, oglasi srbija, besplatni oglasi, prodaja, kupovina',
    jsonLd: jsonLd,
  );
}

/// SEO za pojedinačnu kategoriju Malih Oglasa
void setClassifiedCategorySeo(ClassifiedCategoryModel category) {
  final desc =
      'Pregledajte i besplatno oglasite proizvode u kategoriji ${category.name} na Domaćem Marketu. 0 dinara provizije, besplatno obnavljanje i direktan kontakt.';

  final jsonLd = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    'name': '${category.name} — Mali Oglasi',
    'description': desc,
    'url': '$publicBaseUrl/classifieds?category=${category.id}',
  };

  setPageMetadata(
    title: '${category.name} | Mali Oglasi | Domaći Market',
    description: desc,
    path: '/classifieds?category=${category.id}',
    keywords:
        '${category.name}, mali oglasi, besplatni oglasi srbija, oglasi bez provizije, kupovina, prodaja',
    jsonLd: jsonLd,
  );
}

/// SEO za prodajni profil / poljoprivredno gazdinstvo (LocalBusiness / Store)
void setSellerSeo({
  required String id,
  required String name,
  String? city,
  String? avatarUrl,
  String? bio,
  double? rating,
  int? reviewCount,
}) {
  final cleanBio = (bio?.trim().isNotEmpty == true)
      ? bio!.trim().replaceAll(RegExp(r'\s+'), ' ')
      : 'Pogledajte domaće proizvode i ponudu poljoprivrednog gazdinstva $name${city != null ? ' ($city)' : ''}. Kupujte direktno od proverenog proizvođača.';

  final metaDesc = cleanBio.length <= 160
      ? cleanBio
      : '${cleanBio.substring(0, 157).trimRight()}...';

  final jsonLd = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'LocalBusiness',
    'name': name,
    'description': cleanBio,
    if (avatarUrl != null && avatarUrl.isNotEmpty) 'image': avatarUrl,
    'url': '$publicBaseUrl/seller/$id',
    if (city != null && city.isNotEmpty)
      'address': {
        '@type': 'PostalAddress',
        'addressLocality': city,
        'addressCountry': 'RS',
      },
    if (rating != null && reviewCount != null && reviewCount > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': rating.toStringAsFixed(1),
        'reviewCount': reviewCount,
        'bestRating': '5',
        'worstRating': '1',
      },
  };

  setPageMetadata(
    title: '$name - Gazdinstvo i Domaći Proizvođač | Domaći Market',
    description: metaDesc,
    path: '/seller/$id',
    imageUrl: avatarUrl,
    type: 'profile',
    keywords:
        '$name, gazdinstvo, proizvođač, ${city ?? ""}, domaći proizvodi, selo, sveža hrana',
    jsonLd: jsonLd,
  );
}

/// SEO za kategoriju
void setCategorySeo({
  required String name,
  String? path,
  String? description,
}) {
  final desc = description ??
      'Pregledajte ponudu domaćih proizvoda u kategoriji $name. Sveže, prirodno i domaće direktno sa sela na Domaći Market.';

  final jsonLd = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    'name': name,
    'description': desc,
    'url': '$publicBaseUrl${path ?? '/categories'}',
  };

  setPageMetadata(
    title: '$name | Domaći Proizvodi | Domaći Market',
    description: desc,
    path: path ?? '/categories',
    keywords:
        '$name, domaći proizvodi, seoska hrana, sveže namirnice, domaća ponuda',
    jsonLd: jsonLd,
  );
}

/// Centralizovano mapiranje SEO metapodataka po statičkim rutama (GoRouter)
void applyRouteSeo(String path) {
  // 1. Privatne rute (Googlebot ne sme indeksirati)
  if (path == '/cart' ||
      path.startsWith('/checkout') ||
      path == '/orders' ||
      path.startsWith('/profile') ||
      path.startsWith('/buyer') ||
      path == '/settings' ||
      path == '/seller-settings' ||
      path == '/becoming-seller' ||
      path == '/add-product' ||
      path.startsWith('/product/edit') ||
      path.startsWith('/admin') ||
      path == '/conversations' ||
      path.startsWith('/chat') ||
      path.startsWith('/support/ticket') ||
      path == '/classifieds/new' ||
      path.startsWith('/classifieds/edit') ||
      path == '/classifieds/my' ||
      path == '/classifieds/saved-searches' ||
      path == '/verify-email' ||
      path == '/auth/confirm' ||
      path == '/auth/confirmed' ||
      path == '/login' ||
      path == '/register' ||
      path == '/onboarding' ||
      path == '/splash') {
    setPageMetadata(
      title: 'Domaći Market',
      path: path,
      robots: 'noindex, nofollow',
    );
    return;
  }

  // 2. Javne statičke rute
  if (path == '/') {
    setPageMetadata(
      title: 'Domaći Market | Pijaca domaće hrane & Besplatni Mali Oglasi u Srbiji',
      description:
          'Domaći Market spaja proverenu domaću hranu sa sela i 100% besplatne male oglase u Srbiji. Kupujte i oglasite bez provizije: domaći sir, mleko, meso, med, traktore, automobile, alate, tehniku, nekretnine, sve za decu i bebe, zdravlje i lepotu, knjige i rukotvorine.',
      path: '/',
      keywords:
          'domaći market, mali oglasi, besplatni mali oglasi, oglasi srbija, poljoprivredni oglasi, traktori prodaja, polovni automobili srbija, auto delovi, poljoprivredne mašine, domaće životinje, alati, bela tehnika, nekretnine srbija, sve za decu, dečija kolica, auto sedišta, igračke, zdravlje i lepota, parfemi, knjige, udžbenici, umetnost, rukotvorine, domaći proizvodi, domaća hrana, seoska gazdinstva, organska hrana, bez provizije, oglasnik',
    );
  } else if (path == '/classifieds') {
    setPageMetadata(
      title:
          'Mali Oglasi | Besplatno postavljanje i obnavljanje oglasa | Domaći Market',
      description:
          '100% besplatni mali oglasi u Srbiji bez provizije. Pronađite i besplatno oglasite traktore, poljoprivredne mašine, automobile, alate, belu tehniku, nekretnine, sve za decu, zdravlje i lepotu, knjige, odeću i domaće životinje.',
      path: '/classifieds',
      keywords:
          'mali oglasi, besplatni oglasi srbija, poljoprivredni oglasi, traktori, polovni automobili, alati, bela tehnika, nekretnine srbija, domaće životinje, sve za decu, dečija kolica, igračke, zdravlje i lepota, knjige, oglasi bez provizije',
    );
  } else if (path == '/categories') {
    setPageMetadata(
      title: 'Sve Kategorije Domaćih Proizvoda | Domaći Market',
      description:
          'Istražite sve kategorije domaćih proizvoda sa sela: mlečni proizvodi, sveže i suvo meso, med i pčelinji proizvodi, voće, povrće, slana i slatka zimnica, sokovi i sirupi, brašno i žitarice, čajevi i domaće rukotvorine.',
      path: '/categories',
      keywords:
          'kategorije hrane, mlečni proizvodi, med, domaće meso, pršuta, slanina, zimnica, ajvar, džem, voće, povrće, domaći sokovi, brašno, rukotvorine, domaći proizvodi srbija',
    );
  } else if (path == '/search') {
    setPageMetadata(
      title: 'Pretraga Domaćih Proizvoda i Gazdinstava | Domaći Market',
      description:
          'Pretražite bazu domaćih proizvođača i prirodnih seoskih proizvoda širom Srbije po lokaciji, kategoriji i nazivu.',
      path: '/search',
      keywords:
          'pretraga domaćih proizvoda, pretraga gazdinstava, lokalna hrana srbija',
    );
  } else if (path == '/sellers-map') {
    setPageMetadata(
      title: 'Mapa Domaćih Proizvođača i Gazdinstava Srbije | Domaći Market',
      description:
          'Interaktivna mapa poljoprivrednih gazdinstava i proizvođača domaće hrane. Pronađite najbliže seosko gazdinstvo u vašoj okolini.',
      path: '/sellers-map',
      keywords:
          'mapa gazdinstava, lokalni proizvođači mapa, domaća hrana u blizini, gazdinstva srbija mapa',
    );
  } else if (path == '/about') {
    setPageMetadata(
      title: 'O Nama i Misiji Platforme | Domaći Market',
      description:
          'Saznajte više o misiji platforme Domaći Market – povezivanju vrednih srpskih domaćina i kupaca koji cene pravu domaću hranu.',
      path: '/about',
      keywords:
          'o nama domaći market, misija, domaća hrana, podrška selu, srpski domaćini',
    );
  } else if (path == '/uslovi-koriscenja') {
    setPageMetadata(
      title: 'Uslovi Korišćenja Platforme | Domaći Market',
      description:
          'Pravila korišćenja platforme Domaći Market za kupce, prodavce i posetioce web aplikacije.',
      path: '/uslovi-koriscenja',
    );
  } else if (path == '/politika-privatnosti') {
    setPageMetadata(
      title: 'Politika Privatnosti i Zaštita Podataka | Domaći Market',
      description:
          'Detaljne informacije o obradi i zaštiti podataka o ličnosti na platformi Domaći Market u skladu sa zakonima Republike Srbije.',
      path: '/politika-privatnosti',
    );
  } else if (path == '/support') {
    setPageMetadata(
      title: 'Korisnička Podrška i Pomoć | Domaći Market',
      description:
          'Trebate pomoć ili imate pitanje u vezi platforme Domaći Market? Kontaktirajte naš tim za podršku.',
      path: '/support',
    );
  }
}
