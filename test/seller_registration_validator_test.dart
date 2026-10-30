import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/utils/seller_registration_validator.dart';

void main() {
  group('ProducerLegalType', () {
    test('maps to and from dbValue', () {
      expect(ProducerLegalType.rpg.dbValue, 'rpg');
      expect(ProducerLegalType.company.dbValue, 'company');
      expect(ProducerLegalType.fromDbValue('rpg'), ProducerLegalType.rpg);
      expect(ProducerLegalType.fromDbValue('COMPANY'), ProducerLegalType.company);
      expect(ProducerLegalType.fromDbValue('unknown'), isNull);
      expect(ProducerLegalType.fromDbValue(null), isNull);
    });
  });

  group('SellerRegistrationValidator.validateBpg', () {
    test('accepts valid 12-digit BPG numbers', () {
      expect(SellerRegistrationValidator.validateBpg('801234567890'), isNull);
      expect(SellerRegistrationValidator.validateBpg('721456987012'), isNull);
    });

    test('accepts 12-digit BPG with spaces or dashes', () {
      expect(
        SellerRegistrationValidator.validateBpg('8012-3456-7890'),
        isNull,
      );
      expect(
        SellerRegistrationValidator.validateBpg('8012 3456 7890'),
        isNull,
      );
    });

    test('rejects empty, wrong length, or non-digit BPG', () {
      expect(SellerRegistrationValidator.validateBpg(''), isNotNull);
      expect(SellerRegistrationValidator.validateBpg('   '), isNotNull);
      expect(SellerRegistrationValidator.validateBpg('12345678901'), isNotNull);
      expect(
        SellerRegistrationValidator.validateBpg('1234567890123'),
        isNotNull,
      );
      expect(
        SellerRegistrationValidator.validateBpg('80123456789A'),
        isNotNull,
      );
    });

    test('rejects 12 identical digits', () {
      expect(
        SellerRegistrationValidator.validateBpg('000000000000'),
        isNotNull,
      );
      expect(
        SellerRegistrationValidator.validateBpg('111111111111'),
        isNotNull,
      );
      expect(
        SellerRegistrationValidator.validateBpg('999999999999'),
        isNotNull,
      );
    });
  });

  group('SellerRegistrationValidator.validatePib', () {
    test('accepts valid 9-digit Serbian PIB with ISO 7064 MOD 11-10 checksum', () {
      expect(SellerRegistrationValidator.validatePib('100001011'), isNull);
      expect(SellerRegistrationValidator.validatePib('100 001 011'), isNull);
      expect(SellerRegistrationValidator.validatePib('100-001-011'), isNull);
    });

    test('rejects PIB with invalid check digit', () {
      expect(SellerRegistrationValidator.validatePib('100001012'), isNotNull);
      expect(SellerRegistrationValidator.validatePib('100001010'), isNotNull);
      expect(SellerRegistrationValidator.validatePib('123456789'), isNotNull);
    });

    test('rejects PIB starting with 0 or wrong length', () {
      expect(SellerRegistrationValidator.validatePib('000001011'), isNotNull);
      expect(SellerRegistrationValidator.validatePib('10000101'), isNotNull);
      expect(SellerRegistrationValidator.validatePib('1000010111'), isNotNull);
      expect(SellerRegistrationValidator.validatePib('10000101A'), isNotNull);
      expect(SellerRegistrationValidator.validatePib(''), isNotNull);
    });
  });

  group('UserModel registered producer fields', () {
    test('identifies RPG and Company producer badges and serializes fields', () {
      final rpgUser = UserModel.fromJson({
        'id': 'u1',
        'role': 'seller',
        'legal_type': 'rpg',
        'bpg_masked': '••••••••7890',
        'has_registered_entity': true,
      });
      expect(rpgUser.isRegisteredProducer, isTrue);
      expect(
        rpgUser.registeredProducerBadgeLabel,
        'Verifikovano gazdinstvo (BPG)',
      );

      final companyUser = UserModel.fromJson({
        'id': 'u2',
        'role': 'seller',
        'legal_type': 'company',
        'pib': '100001011',
      });
      expect(companyUser.isRegisteredProducer, isTrue);
      expect(
        companyUser.registeredProducerBadgeLabel,
        'Registrovani proizvođač (PIB)',
      );
      expect(companyUser.toJson()['pib'], '100001011');
      expect(companyUser.toJson()['legal_type'], 'company');
    });
  });
}

