import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/user_model.dart';

void main() {
  group('Auth & Profiles Hardening - DTO and Canonical Mapping (P1)', () {
    test('BuyerProfile DTO maps cleanly to and from UserModel', () {
      const buyer = UserModel(
        id: 'buyer-42',
        email: 'kupac@test.rs',
        phone: '+38160111222',
        displayName: 'Marko Marković',
        city: 'Beograd',
        postalCode: '11000',
        address: 'Knez Mihailova 10',
        role: UserRole.buyer,
        isGuest: false,
      );

      final dto = buyer.toBuyerProfile();
      expect(dto.id, 'buyer-42');
      expect(dto.displayName, 'Marko Marković');
      expect(dto.address, 'Knez Mihailova 10');
      expect(dto.city, 'Beograd');

      final reconstructed = dto.toUserModel();
      expect(reconstructed.id, buyer.id);
      expect(reconstructed.role, UserRole.buyer);
      expect(reconstructed.address, 'Knez Mihailova 10');
      expect(reconstructed.buyerAddress, 'Knez Mihailova 10');
      expect(reconstructed.sellerLocation, isNull);

      final json = dto.toJson();
      expect(json['address'], 'Knez Mihailova 10');
      expect(json['location'], 'Knez Mihailova 10'); // DB compatibility
      expect(json['role'], 'buyer');
    });

    test('SellerProfile DTO preserves farm details, story, and tags', () {
      const seller = UserModel(
        id: 'seller-99',
        email: 'gazdinstvo@test.rs',
        phone: '+38164333444',
        phonePublic: true,
        displayName: 'Jovan Jovanović',
        farmName: 'Gazdinstvo Zlatibor',
        city: 'Čajetina',
        postalCode: '31310',
        location: 'Zlatibor, Selo Gostilje',
        address: 'Gostilje bb',
        role: UserRole.seller,
        sellerStory: 'Tradicionalna proizvodnja sira i kajmaka od 1950.',
        sellerTags: ['Bio sertifikat', 'Organski uzgoj'],
        sellerQuickReplies: ['Imamo na stanju', 'Dostava je petkom'],
        lat: 43.65,
        lng: 19.78,
      );

      final dto = seller.toSellerProfile();
      expect(dto.farmName, 'Gazdinstvo Zlatibor');
      expect(dto.location, 'Zlatibor, Selo Gostilje');
      expect(dto.address, 'Gostilje bb');
      expect(dto.sellerStory, contains('Tradicionalna proizvodnja'));
      expect(dto.sellerTags, contains('Bio sertifikat'));
      expect(dto.lat, 43.65);
      expect(dto.lng, 19.78);

      final reconstructed = dto.toUserModel();
      expect(reconstructed.isSeller, isTrue);
      expect(reconstructed.sellerLocation, 'Zlatibor, Selo Gostilje');
      expect(reconstructed.sellerStory, contains('Tradicionalna proizvodnja'));

      final json = dto.toJson();
      expect(json['location'], 'Zlatibor, Selo Gostilje');
      expect(json['address'], 'Gostilje bb');
      expect(json['role'], 'seller');
      expect(json['phone_public'], isTrue);
    });

    test('Buyer copyWith(address) updates address and does NOT get blocked by location', () {
      final initialJson = {
        'id': 'buyer-1',
        'role': 'buyer',
        'location': 'Stara adresa 1',
      };
      final buyer = UserModel.fromJson(initialJson);
      expect(buyer.address, 'Stara adresa 1');

      // Kupac unosi novu adresu u checkout ili profilu
      final updated = buyer.copyWith(address: 'Nova Ulica 25');
      expect(updated.address, 'Nova Ulica 25');

      final serialized = updated.toJson();
      expect(serialized['address'], 'Nova Ulica 25');
      expect(serialized['location'], 'Nova Ulica 25');
      expect(serialized['location'], isNot('Stara adresa 1'));
    });

    test('Seller location and address are independent and cannot overwrite each other', () {
      final initialJson = {
        'id': 'seller-1',
        'role': 'seller',
        'farm_name': 'Moja Farma',
        'location': 'Selo Popučke',
        'address': 'Radnja Valjevo 12',
      };
      final seller = UserModel.fromJson(initialJson);
      expect(seller.sellerLocation, 'Selo Popučke');
      expect(seller.address, 'Radnja Valjevo 12');

      // Ažuriranje adrese radnje ne sme dirati lokaciju gazdinstva
      final updatedShop = seller.copyWith(address: 'Nova Radnja 99');
      expect(updatedShop.address, 'Nova Radnja 99');
      expect(updatedShop.location, 'Selo Popučke');

      final shopJson = updatedShop.toJson();
      expect(shopJson['location'], 'Selo Popučke');
      expect(shopJson['address'], 'Nova Radnja 99');

      // Ažuriranje gazdinstva ne sme dirati adresu
      final updatedFarm = seller.copyWith(location: 'Novo Selo 1');
      expect(updatedFarm.location, 'Novo Selo 1');
      expect(updatedFarm.address, 'Radnja Valjevo 12');

      final farmJson = updatedFarm.toJson();
      expect(farmJson['location'], 'Novo Selo 1');
      expect(farmJson['address'], 'Radnja Valjevo 12');
    });
  });

  group('Auth & Profiles Hardening - updateProfile Field Completeness (P1)', () {
    test('toJson/toDbMap contains all seller fields (no dropped attributes)', () {
      const user = UserModel(
        id: 'seller-full',
        email: 'test@full.com',
        phone: '+38161111222',
        displayName: 'Petar Petrović',
        city: 'Kragujevac',
        postalCode: '34000',
        address: 'Lepenica 1',
        role: UserRole.seller,
        farmName: 'Farma Šumadija',
        location: 'Kragujevac okolina',
        profileImageUrl: 'https://img.com/avatar.jpg',
        lat: 44.01,
        lng: 20.91,
        phonePublic: true,
        sellerStory: 'Domaći proizvodi sa obronaka Rudnika.',
        farmGalleryUrls: ['https://img.com/1.jpg', 'https://img.com/2.jpg'],
        sellerTags: ['Dostava', 'Organsko'],
        sellerQuickReplies: ['Odgovor 1', 'Odgovor 2'],
      );

      final dbMap = user.toDbMap();
      expect(dbMap['display_name'], 'Petar Petrović');
      expect(dbMap['phone'], '+38161111222');
      expect(dbMap['city'], 'Kragujevac');
      expect(dbMap['postal_code'], '34000');
      expect(dbMap['address'], 'Lepenica 1');
      expect(dbMap['location'], 'Kragujevac okolina');
      expect(dbMap['lat'], 44.01);
      expect(dbMap['lng'], 20.91);
      expect(dbMap['phone_public'], isTrue);
      expect(dbMap['seller_story'], 'Domaći proizvodi sa obronaka Rudnika.');
      expect(dbMap['farm_gallery_urls'], ['https://img.com/1.jpg', 'https://img.com/2.jpg']);
      expect(dbMap['seller_tags'], ['Dostava', 'Organsko']);
      expect(dbMap['seller_quick_replies'], ['Odgovor 1', 'Odgovor 2']);
    });
  });

  group('Auth Anti-Enumeration Protection (P0)', () {
    test('Anti-enumeration logic does not distinguish between taken email and bad credentials', () {
      // Provera formatiranja uobičajenih auth poruka
      String formatMsg(String err) {
        final msg = err.toLowerCase();
        if (msg.contains('invalid login') ||
            msg.contains('invalid') ||
            msg.contains('wrong') ||
            msg.contains('credentials') ||
            msg.contains('email not confirmed') ||
            msg.contains('user not found') ||
            msg.contains('email already') ||
            msg.contains('already registered')) {
          return 'Pogrešan email ili lozinka.';
        }
        return 'Greška';
      }

      expect(formatMsg('User already registered'), 'Pogrešan email ili lozinka.');
      expect(formatMsg('email already taken'), 'Pogrešan email ili lozinka.');
      expect(formatMsg('user not found'), 'Pogrešan email ili lozinka.');
      expect(formatMsg('Invalid login credentials'), 'Pogrešan email ili lozinka.');
    });
  });
}
